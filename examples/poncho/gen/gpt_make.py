"""Turns the raw sheets (gen/gpt_run.py) into Poncho's art with tools/sprite_kit.py: every sheet scaled by its own upright frame, soles on the anchor row, feet centred, never cut, one
15-colour palette per strip: art/<id>.png + .json (frames named idle_0.., walk_0.., run_0.. ...).

    python3 gen/gpt_make.py [id ...]
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

import numpy as np
from scipy import ndimage
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[2] / "tools"))
import gpt_jobs as J  # noqa: E402
import sprite_kit as K  # noqa: E402
from sprite_kit import build_character, write_strip  # noqa: E402

RAW, ART = HERE.parent / "raw", HERE.parent / "art"
_key_background = K.key_background
# the kit's own keying despeckles blobs under 500 px: at game size that would take off a shoe or a hand that does not touch the body. Backgrounds are taken off here, at full size, by
# clear_bg()/regrid(), so the kit gets pictures that are clean already and must change nothing.
K.key_background = lambda im, tol=38: im.convert("RGBA")
K.quantized = lambda im, colours: im   # the kit's own 15-colour pass would pick a new palette from resampled pixels: the outfit's LOCKED palette is applied here instead (snap())


def clear_bg(im: Image.Image, tol: int = 40) -> Image.Image:
    """The picture with its background see-through: what the kit keys from the border, plus the same flat grey wherever it is shut in (between his legs and the scooter)."""
    k = _key_background(im).convert("RGBA")
    a = np.array(k)
    rgb = np.asarray(im.convert("RGB")).astype(int)
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    near = ((rgb - bg) ** 2).sum(-1) < tol * tol
    a[near, 3] = 0
    return Image.fromarray(a)


GAP = 12      # raw px: parts of one frame (a shoe off the leg, a hand, a curl) closer than this stay together
NEAR = 9      # raw px: a small blob farther than this from the body is a crumb
MIN_BLOB = 30  # raw px: smaller bits are noise, not art


def seam_split(out: np.ndarray, r: int) -> np.ndarray:
    """Label r (two frames that touch) becomes r and r + 1 (labels above shift up): the seam is the top-to-bottom path (one column left or right per row) that crosses the fewest drawn
    pixels, searched in the middle half of the blob."""
    m = out == r
    xs = np.where(m.any(0))[0]
    x0, x1 = int(xs.min()), int(xs.max()) + 1
    lo, hi = x0 + (x1 - x0) // 4, x1 - (x1 - x0) // 4
    cost = m[:, lo:hi].astype(float)
    h, w = cost.shape
    acc = cost.copy()
    back = np.zeros((h, w), np.int8)
    centre = np.abs(np.arange(w) - w / 2) * 0.002
    for y in range(1, h):
        prev = acc[y - 1]
        cand = np.stack([np.r_[np.inf, prev[:-1]], prev, np.r_[prev[1:], np.inf]])
        k = cand.argmin(0)
        acc[y] = cost[y] + cand[k, np.arange(w)] + centre
        back[y] = k - 1
    x = int(acc[-1].argmin())
    seam = np.zeros(h, int)
    for y in range(h - 1, -1, -1):
        seam[y] = lo + x
        x += int(back[y, x])
        x = min(max(x, 0), w - 1)
    out = out.copy()
    out[out > r] += 1
    right = m & (np.arange(out.shape[1])[None, :] >= seam[:, None])
    out[right] = r + 1
    return out


def frame_labels(alpha: np.ndarray, n: int) -> np.ndarray:
    """The frames of a sheet as a label image (0 = empty, 1..n left to right): the drawn pixels are grown by `gap` px and the connected blobs of that are the frames, so a shoe or a curl
    that floats near its body stays with it and a neighbour whose columns overlap does not join in. The widest gap that gives exactly n frames wins; with more blobs the smallest joins
    its nearest; with fewer (frames that touch) the widest is cut along the sheet's emptiest column near its middle."""
    best = None
    for gap in range(GAP, -1, -1):
        grown = ndimage.binary_dilation(alpha, iterations=gap) if gap else alpha
        lab, k = ndimage.label(grown, structure=np.ones((3, 3)))
        sz = ndimage.sum(alpha, lab, range(1, k + 1))
        k = int((sz >= 0.15 * sz.max()).sum())   # frame-sized blobs only: a crumb is not a frame
        if k == n or (k > n and (best is None or k < best[1])):
            best = (lab, k)
            if k == n:
                break
        elif best is None and gap == 0:
            best = (lab, k)
    lab, k = best
    lab = np.where(alpha, lab, 0)
    all_ids = [i for i in range(1, lab.max() + 1) if (lab == i).sum() >= MIN_BLOB]
    top = max((lab == i).sum() for i in all_ids)
    ids = [i for i in all_ids if (lab == i).sum() >= 0.15 * top]
    cen = {i: np.array(ndimage.center_of_mass(lab == i)) for i in all_ids}
    for i in all_ids:   # small pieces join the nearest frame-sized blob (crumbs are dropped below)
        if i not in ids:
            lab[lab == i] = min(ids, key=lambda j: np.linalg.norm(cen[j] - cen[i]))
    while len(ids) > n:   # more frame-sized blobs than frames: the smallest joins its nearest
        small = min(ids, key=lambda i: (lab == i).sum())
        near = min((i for i in ids if i != small), key=lambda i: np.linalg.norm(cen[i] - cen[small]))
        lab[lab == small] = near
        ids.remove(small)
    out = np.zeros(lab.shape, np.int32)
    order = sorted(ids, key=lambda i: cen[i][1])
    for r, i in enumerate(order, 1):
        out[lab == i] = r
    while len(order) < n:   # frames that touch: the widest is cut along the cheapest seam (it bends round limbs instead of slicing through them)
        widths = []
        for r in range(1, len(order) + 1):
            xs = np.where((out == r).any(0))[0]
            widths.append(xs.max() - xs.min())
        r = 1 + int(np.argmax(widths))
        out = seam_split(out, r)
        order.append(0)
    for r in range(1, n + 1):   # crumbs: small AND far from the body (a neighbour's tip, a speck of noise)
        m = out == r
        sub, k = ndimage.label(m, structure=np.ones((3, 3)))
        if k > 1:
            sz = ndimage.sum(m, sub, range(1, k + 1))
            main = 1 + int(np.argmax(sz))
            near = ndimage.binary_dilation(sub == main, iterations=NEAR)
            for i in range(1, k + 1):
                if sz[i - 1] < 0.04 * sz.max() and not (near & (sub == i)).any():
                    out[sub == i] = 0
    return out


def regrid(im: Image.Image, n: int) -> tuple[Image.Image, list[tuple[int, int, int, int]]]:
    """A raw sheet cut along its REAL gaps: every frame's blobs kept whole (shoes, hands, wheels, curls), laid out again on an even grid with wide empty gaps, at the same heights, so the
    kit's cut finds them exactly. Returns (the sheet, the raw box (x0, y0, x1, y1) of each frame)."""
    keyed = clear_bg(im)
    alpha = np.asarray(keyed.getchannel("A")) >= K.ALPHA_MIN
    fl = frame_labels(alpha, n)
    rgba = np.asarray(keyed)
    boxes = []
    for r in range(1, n + 1):
        ys, xs = np.where(fl == r)
        boxes.append((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    pad = 60
    cw = max(b[2] - b[0] for b in boxes) + 2 * pad
    out = np.zeros((alpha.shape[0], cw * n, 4), np.uint8)
    for i, (x0, y0, x1, y1) in enumerate(boxes):
        m = fl[:, x0:x1] == i + 1
        cell = out[:, i * cw + pad:i * cw + pad + (x1 - x0)]
        cell[m] = rgba[:, x0:x1][m]
    return Image.fromarray(out), boxes


def lab(rgb: np.ndarray) -> np.ndarray:
    c = rgb.astype(float) / 255
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    xyz = c @ np.array([[0.4124, 0.2126, 0.0193], [0.3576, 0.7152, 0.1192], [0.1805, 0.0722, 0.9505]]) / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[:, 1] - 16, 500 * (f[:, 0] - f[:, 1]), 200 * (f[:, 1] - f[:, 2])], 1)


def shared_palette(images: list[Image.Image], colours: int, method=None) -> np.ndarray:
    """ONE palette for every sheet of an outfit, from its clean reference picture(s): the distinct colours (counted, weighted by the square root of their count so cheeks and shoes
    survive) grouped by a weighted k-means in Lab space, so skin stays skin, hair stays brown, shorts stay yellow."""
    pool = []
    for im in images:
        a = np.asarray(clear_bg(im))
        pool.append(a[a[..., 3] >= K.ALPHA_MIN][:, :3] // 8 * 8 + 4)
    u, n = np.unique(np.concatenate(pool), axis=0, return_counts=True)
    w, x = np.sqrt(n.astype(float)), lab(u)
    cen = [x[int(np.argmax(w))]]
    for _ in range(colours - 1):   # farthest-point start, weighted
        d = np.min([((x - c) ** 2).sum(1) for c in cen], axis=0) * w
        cen.append(x[int(np.argmax(d))])
    cen = np.array(cen)
    for _ in range(30):
        lab_i = ((x[:, None] - cen[None]) ** 2).sum(-1).argmin(1)
        for k in range(colours):
            m = lab_i == k
            if m.any():
                cen[k] = (x[m] * w[m, None]).sum(0) / w[m].sum()
    lab_i = ((x[:, None] - cen[None]) ** 2).sum(-1).argmin(1)
    return np.array([(u[lab_i == k] * w[lab_i == k, None]).sum(0) / max(1e-9, w[lab_i == k].sum()) if (lab_i == k).any() else (0, 0, 0) for k in range(colours)]).round().astype(np.uint8)


def flat_palette(keyed: Image.Image, pal: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """The sheet at full size in the palette's flat colours (no dithering, no blur): (index image, mask of the drawn pixels)."""
    a = np.asarray(keyed)
    mask = a[..., 3] >= K.ALPHA_MIN
    idx = np.zeros(mask.shape, np.int16)
    ys, xs = np.nonzero(mask)
    px = a[ys, xs, :3].astype(np.int32)
    for s in range(0, len(px), 200_000):
        d = ((px[s:s + 200_000, None] - pal[None].astype(np.int32)) ** 2).sum(-1)
        idx[ys[s:s + 200_000], xs[s:s + 200_000]] = d.argmin(-1)
    return idx, mask


def vote(idx: np.ndarray, mask: np.ndarray, xs: np.ndarray, ys: np.ndarray, pal: np.ndarray) -> np.ndarray:
    """Every target pixel takes the most common palette colour of its block (the dark outline wins when it fills a third of it), see-through when most of it is empty."""
    dark = int(np.argmin(pal.sum(1)))
    out = np.zeros((len(ys) - 1, len(xs) - 1, 4), np.uint8)
    for j in range(len(ys) - 1):
        for i in range(len(xs) - 1):
            m = mask[ys[j]:ys[j + 1], xs[i]:xs[i + 1]]
            if m.size == 0 or m.sum() < EDGE * m.size:
                continue
            c = np.bincount(idx[ys[j]:ys[j + 1], xs[i]:xs[i + 1]][m], minlength=len(pal)).astype(float)
            c[dark] *= 2.2
            if m.sum() < COVER * m.size and int(c.argmax()) != dark:   # a thin tip is kept only when it is outline (hair curls, soles, rims)
                continue
            out[j, i, :3] = pal[int(c.argmax())]
            out[j, i, 3] = 255
    return out


def prescale(im: Image.Image, n: int, kf, height: int, pal: np.ndarray) -> Image.Image:
    """The raw sheet made crisp and reduced to the game's size BEFORE the kit fits it: flat locked-palette colours, then every target pixel takes the majority colour of its block
    (never a smooth filter; the model's pixel grid is not regular enough to detect). The kit's own resize then does next to nothing."""
    keyed = im.convert("RGBA")   # already clean: regrid() took the background off
    if kf == "auto":
        kf = K.pick_upright(K.blobs(keyed, n)[1])
    k = K.sheet_scale(keyed, n, kf, height)
    tw, th = max(1, round(keyed.width * k)), max(1, round(keyed.height * k))
    idx, mask = flat_palette(keyed, pal)
    return Image.fromarray(vote(idx, mask, np.linspace(0, keyed.width, tw + 1).astype(int), np.linspace(0, keyed.height, th + 1).astype(int), pal))


def merge_darks(pal: np.ndarray, luma: float = 48) -> np.ndarray:
    """One outline colour: every palette colour darker than `luma` becomes the darkest one (the outline, the black of the tee and the pupils share it)."""
    l = pal @ np.array([0.299, 0.587, 0.114])
    out = pal.copy()
    out[l < luma] = OUTLINE
    sat = pal.max(1).astype(int) - pal.min(1).astype(int)
    halo = (sat < 24) & (l > 60) & (l < 228)   # mid greys are the background's edge, not a colour of the boy: they only make speckles
    return out[~halo] if halo.any() else out


def clean(strip: Image.Image, w: int) -> Image.Image:
    """Stray pixels out, frame by frame: a drawn pixel on the silhouette with no same-colour neighbour is removed; one inside the body with none takes its neighbours' majority colour
    (a white eye glint is kept); a see-through pixel shut in by 6+ drawn neighbours is filled."""
    a = np.array(strip)
    for f in range(a.shape[1] // w):
        fr = a[:, f * w:(f + 1) * w]
        h, ww = fr.shape[:2]
        key = (fr[..., 0].astype(np.int32) << 16 | fr[..., 1].astype(np.int32) << 8 | fr[..., 2]) * (fr[..., 3] > 0) - (fr[..., 3] == 0)
        src = key.copy()
        for y in range(1, h - 1):
            for x in range(1, ww - 1):
                nb = src[y - 1:y + 2, x - 1:x + 2].ravel()
                nb = np.delete(nb, 4)
                c = src[y, x]
                if c == -1:
                    drawn = nb[nb != -1]
                    if len(drawn) >= 6:
                        v, n = np.unique(drawn, return_counts=True)
                        k = int(v[n.argmax()])
                        fr[y, x] = (k >> 16 & 255, k >> 8 & 255, k & 255, 255)
                    continue
                if (nb == c).sum() >= 1:
                    continue
                if (nb == -1).sum() >= 3:
                    fr[y, x, 3] = 0
                    continue
                if c >> 16 > 200 and (c >> 8 & 255) > 200:
                    continue
                v, n = np.unique(nb[nb != -1], return_counts=True)
                if len(v) and n.max() >= 4:
                    k = int(v[n.argmax()])
                    fr[y, x] = (k >> 16 & 255, k >> 8 & 255, k & 255, 255)
    return Image.fromarray(a)


def thicken_stem(strip: Image.Image, w: int) -> Image.Image:
    """The scooter's blue stem is drawn one pixel wide between two outline pixels: make it two wide (the outline pixel on its right becomes blue and the outline moves one on, when that
    pixel is empty)."""
    a = np.array(strip)
    h, W = a.shape[:2]
    blue = (a[..., 2] > 140) & (a[..., 0] < 90) & (a[..., 3] > 0)
    dark = (a[..., :3].astype(int) @ [1, 1, 1] < 150) & (a[..., 3] > 0)
    for y in range(h):
        for x in range(1, W - 3):
            if x % w >= w - 3:
                continue
            if blue[y, x] and not blue[y, x + 1] and dark[y, x - 1] and dark[y, x + 1] and a[y, x + 2, 3] == 0:
                a[y, x + 2] = a[y, x + 1]
                a[y, x + 1] = a[y, x]
    return Image.fromarray(a)


def snap(strip: Image.Image, pal: np.ndarray) -> Image.Image:
    """Every drawn pixel takes the nearest colour of the outfit's locked palette (no dithering): whatever the kit's resampling blended is put back."""
    a = np.array(strip)
    ys, xs = np.nonzero(a[..., 3] >= 128)
    px = a[ys, xs, :3].astype(np.int32)
    d = ((px[:, None] - pal[None].astype(np.int32)) ** 2).sum(-1)
    a[ys, xs, :3] = pal[d.argmin(1)]
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    a[a[..., 3] == 0] = 0
    return Image.fromarray(a)


def trim_below(strip: Image.Image, meta: dict, below: int = 6) -> tuple[Image.Image, dict]:
    """The cell keeps `below` px under the ground line (auto_cell leaves 24: memory the hero does not use), never cutting a frame."""
    bb = strip.getchannel("A").getbbox()
    h = max(meta["anchor"][1] + below, (bb[3] if bb else 0) + 1)
    h = -(-h // 8) * 8
    return strip.crop((0, 0, strip.width, min(h, strip.height))), {**meta, "h": min(h, strip.height)}


EDGE = 0.06   # outline pixels of a block that is only this empty still count (thin tips, soles, wheel rims)
COVER = 0.34   # a target pixel is drawn when at least this part of its block is (a thin sole or wheel rim must not vanish)
OUTLINE = (26, 20, 24)   # the one near-black of the outline, the pupils and the tee's black stripes
PALETTE = 31   # per outfit (+ see-through: 32 colours, packed at 8 bits a pixel)


def make(cid: str, spec: dict, colours: int = 32) -> None:
    sheets = []
    ref = RAW / (f"{cid}_ref.png" if cid != "poncho" else "poncho_ref.png")
    # the palette comes from the CLEAN reference picture(s) of the outfit (the sheets' pixels are noisy and give pink skin and grey shorts), rare colours kept (MAXCOVERAGE)
    refs = [ref] + ([RAW / "poncho_ref.png"] if cid == "poncho_scooter" else [])
    pal = merge_darks(shared_palette([Image.open(r) for r in refs if r.exists()], PALETTE))
    for name, n, _, fnames, kf, _ in spec["sheets"]:
        raw = RAW / f"{cid}_{name}.png"
        if not raw.exists():
            print(f"  {cid}: {name} missing")
            continue
        sheets.append((prescale(regrid(Image.open(raw), n)[0], n, kf, spec["height"], pal), n, fnames, kf, raw.name))
    if not sheets:
        sys.exit(f"{cid}: no raw sheets (python3 gen/gpt_run.py --plan)")
    strip, meta = build_character(sheets, spec["height"], None, None, colours, "right")
    strip, meta = trim_below(strip, meta)
    strip = snap(strip, pal)
    strip = strip if os.environ.get("NOCLEAN") else clean(strip, meta["w"])
    if cid == "poncho_scooter":
        strip = thicken_stem(strip, meta["w"])
    write_strip(ART, cid, strip, meta)
    print(f"  {cid}: {len(meta['frames'])} frames, cell {meta['w']}x{meta['h']}, anchor {meta['anchor']}")


if __name__ == "__main__":
    for c in sys.argv[1:] or list(J.CHARS):
        make(c, J.CHARS[c])
