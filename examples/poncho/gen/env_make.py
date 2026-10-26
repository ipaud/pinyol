"""Turns the raw playroom sheets (gen/env_run.py) into the game's pictures, surgically: every object is cut along its own blobs (gpt_make.frame_labels), reduced to its game size by majority vote
into a LOCKED 32-colour palette (no smooth filter, no dithering), stray pixels cleaned, never cut.  art/env/<id>.png + .json for single pictures and strips; art/far.png, art/case.png for the wide layers.

    python3 gen/env_make.py [group ...]       groups: walls case giant fore tiles enemies items
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gpt_make as M  # noqa: E402
import env_jobs as E  # noqa: E402

RAW, ART = M.RAW, M.ART / "env"
ART.mkdir(parents=True, exist_ok=True)
OUT = np.array(M.OUTLINE, np.uint8)
NCOL = 31


# ------------------------------------------------------------------------------------------------------------------------------------ palette
def pal_from(px: np.ndarray, n: int = NCOL, halo: bool = True) -> np.ndarray:
    """A locked palette of n colours from pixels (N x 3): weighted k-means in Lab (weights: square root of how common a colour is, so small things survive); darks become the one outline colour."""
    u, c = np.unique(px // 8 * 8 + 4, axis=0, return_counts=True)
    w, x = np.sqrt(c.astype(float)), M.lab(u)
    cen = [x[int(np.argmax(w))]]
    for _ in range(n - 1):
        d = np.min([((x - q) ** 2).sum(1) for q in cen], axis=0) * w
        cen.append(x[int(np.argmax(d))])
    cen = np.array(cen)
    for _ in range(25):
        a = ((x[:, None] - cen[None]) ** 2).sum(-1).argmin(1)
        for k in range(n):
            m = a == k
            if m.any():
                cen[k] = (x[m] * w[m, None]).sum(0) / w[m].sum()
    a = ((x[:, None] - cen[None]) ** 2).sum(-1).argmin(1)
    pal = np.array([(u[a == k] * w[a == k, None]).sum(0) / max(1e-9, w[a == k].sum()) if (a == k).any() else (0, 0, 0) for k in range(n)]).round().astype(np.uint8)
    pal = M.merge_darks(pal) if halo else _darks(pal)
    return np.unique(pal, axis=0)


def _darks(pal: np.ndarray, luma: float = 48) -> np.ndarray:
    out = pal.copy()
    out[pal @ np.array([0.299, 0.587, 0.114]) < luma] = OUT
    return out


def loadkeyed(name: str) -> Image.Image:
    """A raw sheet with its ground see-through: a sheet that came with a real alpha has it made hard (no haze at the edges); one on grey is keyed from its border."""
    im = Image.open(RAW / f"{name}.png")
    if im.mode == "RGBA" and np.asarray(im)[..., 3].min() < 255:
        a = np.array(im)
        a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
        a[a[..., 3] == 0] = 0
        return Image.fromarray(a)
    return M.clear_bg(im)


def opaque_px(im, keyed: bool) -> np.ndarray:
    """The drawn pixels of a picture: the whole of a full-bleed one, or what is not the flat ground of a sheet (`im` may be a sheet's name)."""
    if isinstance(im, str):
        im = loadkeyed(im)
        keyed = False
    a = np.asarray(M.clear_bg(im) if keyed else im.convert("RGBA"))
    px = a[a[..., 3] >= 16][:, :3]
    return px[:: max(1, len(px) // 150000)]


# ------------------------------------------------------------------------------------------------------------------------------------ cutting and fitting
def objects(name: str, n: int) -> list[np.ndarray]:
    """The n objects of a sheet, left to right, each an RGBA array cut tight along its own blobs."""
    keyed = loadkeyed(name)
    rgba = np.asarray(keyed)
    fl = M.frame_labels(rgba[..., 3] >= 16, n)
    out = []
    for r in range(1, n + 1):
        ys, xs = np.where(fl == r)
        if len(ys) == 0:
            sys.exit(f"{name}: object {r} of {n} not found (the sheet has fewer pieces than asked)")
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        o = rgba[y0:y1, x0:x1].copy()
        o[fl[y0:y1, x0:x1] != r] = 0
        out.append(o)
    return out


def shrink(rgba: np.ndarray, pal: np.ndarray, k: float) -> np.ndarray:
    """Majority-vote reduction by k into the palette: RGBA out."""
    im = Image.fromarray(rgba)
    idx, mask = M.flat_palette(im, pal)
    h, w = rgba.shape[:2]
    tw, th = max(1, round(w * k)), max(1, round(h * k))
    return M.vote(idx, mask, np.linspace(0, w, tw + 1).astype(int), np.linspace(0, h, th + 1).astype(int), pal)


def tight(a: np.ndarray) -> np.ndarray:
    ys, xs = np.where(a[..., 3] > 0)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def fit_to(rgba: np.ndarray, pal: np.ndarray, size: int, by: str = "h") -> np.ndarray:
    """An object reduced so its height (or width, by = 'w') is `size` px, cleaned and tight."""
    k = size / (rgba.shape[0] if by == "h" else rgba.shape[1])
    a = tight(shrink(rgba, pal, k))
    return np.asarray(M.clean(Image.fromarray(a), a.shape[1]))


def save(name: str, frames: list[np.ndarray], anchor: tuple[int, int], names: list[str] | None = None, cell: tuple[int, int] | None = None) -> None:
    """art/env/<name>.png (frames side by side, each in the same cell, placed by `anchor`-relative offsets given as frames' own anchors) + .json. frames: RGBA arrays already placed in cells."""
    h, w = frames[0].shape[:2]
    strip = np.concatenate(frames, axis=1)
    Image.fromarray(strip).save(ART / f"{name}.png")
    (ART / f"{name}.json").write_text(json.dumps({"w": w, "h": h, "anchor": [int(v) for v in anchor], "frames": names or [f"{name}_{i}" for i in range(len(frames))]}))
    print(f"  {name}: {len(frames)} frame(s) {w}x{h} anchor {anchor}")


def place(frames: list[np.ndarray], anchors: list[tuple[int, int]], margin: int = 2, below: int = 0) -> tuple[list[np.ndarray], tuple[int, int]]:
    """Frames (tight arrays) with their own anchor points (x, y inside the array) put in one common cell: the anchor column in the middle, no frame cut, `below` px under the lowest anchor."""
    left = max(ax for (ax, ay) in anchors) + margin
    right = max(f.shape[1] - ax for f, (ax, ay) in zip(frames, anchors)) + margin
    half = max(left, right)
    top = max(ay for (ax, ay) in anchors) + margin
    bot = max(f.shape[0] - ay for f, (ax, ay) in zip(frames, anchors)) + max(margin, below)
    W, H = 2 * half, top + bot
    out = []
    for f, (ax, ay) in zip(frames, anchors):
        c = np.zeros((H, W, 4), np.uint8)
        x0, y0 = half - ax, top - ay
        c[y0:y0 + f.shape[0], x0:x0 + f.shape[1]] = f
        out.append(c)
    return out, (half, top)


def feet_anchor(a: np.ndarray) -> tuple[int, int]:
    """(middle of the lowest 18% of the body, the last row): where the soles are."""
    ys = np.where(a[..., 3] > 0)[0]
    lo = ys.max() - max(2, int(0.18 * (ys.max() - ys.min())))
    xs = np.where((a[lo:, :, 3] > 0).any(0))[0]
    return (int((xs.min() + xs.max()) // 2), a.shape[0] - 1)


def anim_frames(src: str, n: int, size: int, kf: int = 0, flying: bool = False, pal: np.ndarray | None = None, by: str = "h"):
    """The n frames of a sheet reduced by ONE scale (frame kf is `size` px tall, or wide with by = 'w') into the sheet's locked palette, with the anchor of each: (frames, anchors, palette)."""
    objs = objects(src, n)
    pal = pal if pal is not None else pal_from(opaque_px(src, False), halo=False)
    k = size / (objs[kf].shape[0] if by == "h" else objs[kf].shape[1])
    frames = []
    for o in objs:
        t = tight(shrink(o, pal, k))
        frames.append(np.asarray(M.clean(Image.fromarray(t), t.shape[1])))
    anchors = [((f.shape[1] // 2, f.shape[0] // 2) if flying else feet_anchor(f)) for f in frames]
    return frames, anchors, pal


def strip(name: str, parts: list, below: int = 0) -> None:
    """One strip from parts [(frames, anchors, names)]: every frame in one common cell."""
    fr = [f for p in parts for f in p[0]]
    an = [a for p in parts for a in p[1]]
    nm = [x for p in parts for x in p[2]]
    cells, anchor = place(fr, an, below=below)
    save(name, cells, anchor, nm)


def anim(name: str, n: int, names: list[str], size: int, **kw) -> None:
    f, a, _ = anim_frames(kw.pop("sheet", name), n, size, **kw)
    strip(name, [(f, a, names)])


def single(name: str, a: np.ndarray, anchor: str = "feet") -> None:
    """One picture as an asset: anchor 'feet' (bottom middle), 'tl' (top-left) or 'centre'."""
    h, w = a.shape[:2]
    ax, ay = {"feet": (w // 2, h - 1), "top": (w // 2, 0), "tl": (0, 0), "centre": (w // 2, h // 2)}[anchor]
    save(name, [a], (ax, ay), [name])


def loop_blend(a: np.ndarray, w: int) -> np.ndarray:
    """A picture that repeats: its last w columns are dissolved (ordered dither) into its first w, and dropped."""
    bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
    p = a.shape[1] - w
    out = a[:, :p].copy()
    for x in range(w):
        t = (x + 0.5) / w
        for y in range(a.shape[0]):
            out[y, x] = a[y, p + x] if bayer[y % 4, x % 4] >= t else a[y, x]
    return out


# ------------------------------------------------------------------------------------------------------------------------------------ groups
def seam_blend(a: np.ndarray, b: np.ndarray, width: int = 56) -> np.ndarray:
    """a followed by b, joined by a dithered dissolve over `width` px of each (an ordered-dither mask along x): plain wallpaper hides it."""
    bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
    h = a.shape[0]
    mix = a[:, -width:].copy()
    for x in range(width):
        t = (x + 0.5) / width
        for y in range(h):
            if bayer[y % 4, x % 4] < t:
                mix[y, x] = b[y, x]
    return np.concatenate([a[:, :-width], mix, b[:, width:]], axis=1)


def walls() -> None:
    ims = [Image.open(RAW / f"wall_{k}.png").convert("RGB") for k in "ab"]
    pal = pal_from(np.concatenate([np.asarray(i).reshape(-1, 3)[::40] for i in ims]), NCOL, halo=False)
    out = []
    for im in ims:
        a = np.dstack([np.asarray(im), np.full((im.height, im.width), 255, np.uint8)])
        out.append(M.clean(Image.fromarray(shrink(a, pal, 240 / im.height)), 9999) if False else shrink(a, pal, 240 / im.height))
    far = loop_blend(seam_blend(out[0], out[1]), 56)
    Image.fromarray(far).save(ART / "far.png")
    print("  far:", far.shape[1], "x", far.shape[0])


def case() -> None:
    """The bookcase layer: wood boards and posts drawn here, the toys of the two shelf sheets put on the boards (seeded), 6 bays of 240 px that repeat."""
    rng = np.random.default_rng(7)
    sw = np.array([(174, 116, 66), (150, 98, 54), (226, 168, 98), (120, 76, 40), (86, 52, 28)], np.uint8)
    px = np.concatenate([opaque_px(f"shelf_{k}", False) for k in "ab"] + [np.repeat(sw, 4000, axis=0)])
    pal = pal_from(px, NCOL, halo=True)
    ob = objects("shelf_a", 10) + objects("shelf_b", 10)
    H = [min(60, round(h * 1.7)) for h in [36, 16, 34, 26, 34, 24, 30, 38, 26, 24, 38, 36, 26, 40, 36, 32, 28, 34, 22, 38]]
    toys = [tight(fit_to(o, pal, h)) for o, h in zip(ob, H)]
    W, HT = 1440, 90
    img = np.zeros((HT, W, 4), np.uint8)
    BACK, BACK2, LIGHT, MID, DARK = [tuple(c) for c in sw[[1, 3, 2, 0, 4]]]
    def fill(x0, y0, x1, y1, c): img[y0:y1, x0:x1] = (*c, 255)
    fill(0, 0, W, HT, BACK)
    for x in range(0, W, 24):
        fill(x, 0, x + 1, HT, BACK2)
    bords = [(0, 8), (80, 10)]   # y, thickness (a cap on top and the base the toys stand on)
    for y, t in bords:
        fill(0, y, W, y + t, MID)
        fill(0, y, W, y + 2, LIGHT)
        fill(0, y + t - 2, W, y + t, DARK)
        fill(0, y + t, W, y + t + 1, tuple(OUT))
    for x in range(0, W, 240):   # posts
        fill(x, 0, x + 10, HT, MID)
        fill(x, 0, x + 2, HT, LIGHT)
        fill(x + 8, 0, x + 10, HT, DARK)
        fill(x + 10, 0, x + 11, HT, tuple(OUT))
    # shadows under each board on the back, then the toys standing on the board tops
    for y, t in bords[:2]:
        pass
    deck, ptr = list(rng.permutation(len(toys))), 0
    for bay in range(6):
        for (top, base) in ((10, 80),):   # (compartment top, the board the toys stand on)
            x = bay * 240 + 18
            while True:
                placed = False
                for j in range(len(deck)):
                    ti = deck[(ptr + j) % len(deck)]
                    t = toys[ti]
                    if x + t.shape[1] <= bay * 240 + 230 and t.shape[0] <= base - top - 2:
                        ptr = (ptr + j + 1) % len(deck)
                        img[base - t.shape[0]:base, x:x + t.shape[1]][t[..., 3] > 0] = t[t[..., 3] > 0]
                        x += t.shape[1] + int(rng.integers(3, 14))
                        placed = True
                        break
                if not placed:
                    break
    snapped = np.asarray(M.snap(Image.fromarray(img), pal))
    Image.fromarray(snapped).save(ART / "case.png")
    print("  case:", W, "x", HT, len(toys), "toys")


GIANT = [("teddy", 140), ("rocket", 170), ("tower", 130), ("ball", 80), ("castle", 110), ("horse", 100),
         ("duck", 80), ("dino", 105), ("rings", 84), ("drum", 70), ("train", 70), ("bunny", 120)]


def giant() -> None:
    px = np.concatenate([opaque_px(f"giant_{k}", False) for k in "ab"])
    pal = pal_from(px)
    ob = objects("giant_a", 6) + objects("giant_b", 6)
    for (name, h), o in zip(GIANT, ob):
        single(f"BG_G_{name.upper()}", fit_to(o, pal, h), "feet")


FORE = [("CRAYON_R", 150, "w"), ("CRAYON_G", 140, "w"), ("CRAYON_B", 130, "w"), ("BLOCKS", 80, "h"), ("BALL", 90, "h"), ("BRICKS", 100, "w")]


def fore() -> None:
    pal = pal_from(opaque_px("fore", False))
    for (name, size, by), o in zip(FORE, objects("fore", 6)):
        single(f"BG_FORE_{name}", fit_to(o, pal, size, by), "tl")


def shrink_to(rgba: np.ndarray, pal: np.ndarray, tw: int, th: int) -> np.ndarray:
    im = Image.fromarray(rgba)
    idx, mask = M.flat_palette(im, pal)
    h, w = rgba.shape[:2]
    return M.vote(idx, mask, np.linspace(0, w, tw + 1).astype(int), np.linspace(0, h, th + 1).astype(int), pal)


def tiles() -> None:
    slab = Image.open(RAW / "floor.png").convert("RGB")
    px = [np.asarray(slab).reshape(-1, 3)[::30], opaque_px("blocks", False), opaque_px("ramp", False)]
    pal = pal_from(np.concatenate(px), NCOL, halo=True)
    sl = shrink_to(np.dstack([np.asarray(slab), np.full((slab.height, slab.width), 255, np.uint8)]), pal, round(slab.width * 96 / slab.height), 96)
    x0 = 110
    col = loop_blend(sl[:, x0:x0 + 38], 6)            # 32 px wide, repeats
    top, b1, b2 = col[0:32], col[32:64], col[64:96]
    T = [top, b1]
    bl = objects("blocks", 5)
    for o in bl:
        T.append(shrink_to(tight(o), pal, 32, 32))      # 2..5 letter blocks, 6 the toy-box crate
    # 7: the shelf: a board from the plank object, the brackets drawn
    plank = tight(objects("ramp", 3)[1])
    pl = shrink_to(plank, pal, round(plank.shape[1] * 14 / plank.shape[0]), 14)
    board = loop_blend(pl[:, 20:20 + 38], 6)
    shelf = np.zeros((32, 32, 4), np.uint8)
    shelf[0:14] = board
    dark = pal[int(np.argmin(((pal.astype(int) - (110, 70, 38)) ** 2).sum(1)))]
    for x0b, d in ((3, 1), (28, -1)):
        for y in range(14, 25):
            for x in range(0, 12 - (y - 14)):
                shelf[y, x0b + d * x if d == 1 else x0b - x] = (*dark, 255)
    for y in range(14, 25):   # outline the brackets
        n = 12 - (y - 14)
        for xx in (3 + n, 28 - n):
            if 0 <= xx < 32:
                shelf[y, xx] = (*OUT, 255)
    T.insert(7, shelf)
    ramp = shrink_to(tight(objects("ramp", 3)[0]), pal, 64, 32)
    a, b = ramp[:, :32], ramp[:, 32:]
    T += [a, b, b[:, ::-1].copy(), a[:, ::-1].copy()]
    save("BG_TILES", T, (0, 0), [f"t{i}" for i in range(len(T))])
    def rep(img, n): return np.concatenate([img] * n, axis=1)
    col3 = np.concatenate([top, b1, b2], axis=0)
    body3 = np.concatenate([b1, b2, b1], axis=0)
    single("BG_FLOORCOL", col3, "tl")
    for n in (2, 4, 8):
        single(f"BG_FLOOR{n}", rep(col3, n), "tl")
        single(f"BG_SHELF{n}", rep(shelf, n), "tl")
        single(f"BG_TBOX{n}", rep(T[6], n), "tl")
    for n in (1, 2, 4, 8):
        single(f"BG_BODY{n}", rep(body3, n), "tl")


def enemies() -> None:
    for name, names, size, kw in (("car", [f"drive_{i}" for i in range(8)] + ["hurt_0", "die_0"], 42, {}),
                                  ("ball", [f"bounce_{i}" for i in range(8)] + ["hurt_0", "die_0"], 46, {}),
                                  ("plane", [f"flap_{i}" for i in range(8)] + ["hurt_0", "die_0"], 60, {"flying": True, "by": "w"})):
        anim("TOY_" + name.upper(), 10, names, size, sheet=name, **kw)
    f, a, pal = anim_frames("robot", 10, 62)
    f2, a2, _ = anim_frames("robot_hit", 6, 62, pal=pal)
    strip("TOY_ROBOT", [(f, a, [f"walk_{i}" for i in range(10)]), (f2, a2, ["wind_0", "wind_1", "stomp_0", "stomp_1", "die_0", "die_1"])])


def items() -> None:
    anim("TOY_COIN", 8, [f"spin_{i}" for i in range(8)], 36, flying=True, sheet="coin")
    anim("TOY_KEYBOARD", 6, ["idle_0", "idle_1", "play_0", "play_1", "play_2", "play_3"], 84, by="w", sheet="keyboard")
    f, a, _ = anim_frames("flag", 6, 150)
    cells, anchor = place(f, a)
    cols = np.where(np.concatenate(cells, axis=0)[..., 3].reshape(-1, cells[0].shape[1]).any(0))[0] if False else np.where(np.stack(cells)[..., 3].any(axis=(0, 1)))[0]
    x0, x1 = max(0, cols.min() - 2), min(cells[0].shape[1], cols.max() + 3)
    save("TOY_FLAG", [c[:, x0:x1] for c in cells], (anchor[0] - x0, anchor[1]), [f"wave_{i}" for i in range(6)])
    pal = pal_from(opaque_px("pickups", False))
    ob = objects("pickups", 11)
    cream, sp0, sp1, sp2, scoot, heart, hempty, note, notes, star, spark = ob
    single("TOY_CREAM", fit_to(cream, pal, 58), "centre")
    k = 44 / sp0.shape[0]
    sp = [tight(shrink(o, pal, k)) for o in (sp0, sp1, sp2)]
    cells, anchor = place(sp, [feet_anchor(x) for x in sp])
    save("TOY_SPRING", cells, anchor, ["up", "mid", "flat"])
    single("TOY_SCOOTER", fit_to(scoot, pal, 70, "w"), "feet")
    h30 = fit_to(heart, pal, 26)
    he30 = fit_to(hempty, pal, 26)
    n1, n2 = fit_to(note, pal, 24), fit_to(notes, pal, 26)
    cells, anchor = place([n1, n2], [feet_anchor(n1), feet_anchor(n2)])
    save("TOY_NOTE", cells, anchor, ["note", "notes"])
    single("TOY_STAR", fit_to(star, pal, 22), "centre")
    single("TOY_SPARK", fit_to(spark, pal, 26), "centre")
    def canvas(w, h, parts):
        c = Image.new("RGBA", (w, h))
        for img, x, y in parts:
            c.alpha_composite(Image.fromarray(img), (x, y))
        return np.asarray(c)
    hearts = [canvas(96, 34, [((h30 if i < f else he30), 2 + i * 31, 4) for i in range(3)]) for f in range(4)]
    save("TOY_HEARTS", hearts, (0, 0), ["h0", "h1", "h2", "h3"])
    coin0 = fit_to(objects("coin", 8)[0], pal_from(opaque_px("coin", False)), 28)
    cr = fit_to(cream, pal, 32)
    sc = fit_to(scoot, pal, 40, "w")
    dim = sc.copy()
    g = (dim[..., :3].astype(int) @ [0.3, 0.59, 0.11] * 0.55 + 40).astype(np.uint8)
    dim[..., :3] = g[..., None]
    def mid(img): return (img, (44 - img.shape[1]) // 2, (34 - img.shape[0]) // 2)
    hud = [canvas(44, 34, [mid(h30)]), canvas(44, 34, [mid(he30)]), canvas(44, 34, [mid(coin0)]), canvas(44, 34, [mid(cr)]), canvas(44, 34, [mid(sc)]), canvas(44, 34, [mid(dim)])]
    save("TOY_HUD", hud, (0, 0), ["heart", "empty", "coin", "cream", "scooter", "dim"])
    sh = []
    for w in (40, 32):
        c = np.zeros((6, 40, 4), np.uint8)
        x0 = (40 - w) // 2
        c[0:6, x0 + 3:x0 + w - 3] = (96, 60, 32, 255)
        c[2:4, x0:x0 + w] = (96, 60, 32, 255)
        sh.append(c)
    save("TOY_SHADOW", sh, (20, 3), ["wide", "narrow"])


def logo(pick_cover: str = "cover_b") -> None:
    """UI_LOGO_ES / _CA / _EN: the rainbow logo (logo_es_b, logo_ca_b, logo_b) cut as one piece (the cap, the stars and the scooter stay with it), the flat ground gone, a locked palette,
    stray pixels cleaned. The cover: cover.rgb565 (240x160), art/cover.png (480x320) and art/cover_240.png of the chosen picture."""
    from scipy import ndimage
    for code, raw in (("ES", "logo_es_b"), ("CA", "logo_ca_b"), ("EN", "logo_b")):
        keyed = np.array(loadkeyed(raw))
        lab, k = ndimage.label(keyed[..., 3] > 0, structure=np.ones((3, 3)))
        sz = ndimage.sum(keyed[..., 3] > 0, lab, range(1, k + 1))
        for i in range(1, k + 1):
            if sz[i - 1] < 150:
                keyed[lab == i] = 0
        pal = pal_from(keyed[keyed[..., 3] > 0][:, :3], halo=False)
        single(f"UI_LOGO_{code}", fit_to(tight(keyed), pal, 310, "w"), "top")
    cv = Image.open(RAW / f"{pick_cover}.png").convert("RGB").resize((480, 320), Image.BOX)
    cv.save(ART / "cover.png")
    cv.save(GAME_DIR / "art" / "cover.png")
    area = cv.resize((240, 160), Image.BOX)
    near = cv.resize((240, 160), Image.NEAREST)
    area.save(GAME_DIR / "art" / "cover_240.png")
    near.save(ART / "cover_240_nearest.png")
    small = np.asarray(area).astype(np.uint16)
    rgb565 = ((small[..., 0] >> 3) << 11) | ((small[..., 1] >> 2) << 5) | (small[..., 2] >> 3)
    (GAME_DIR / "cover.rgb565").write_bytes(rgb565.astype("<u2").tobytes())
    print("  cover.rgb565 from", pick_cover)


GAME_DIR = HERE.parent
GROUPS = {"walls": walls, "case": case, "giant": giant, "fore": fore, "tiles": tiles, "enemies": enemies, "items": items, "logo": logo}


if __name__ == "__main__":
    for g in sys.argv[1:] or list(GROUPS):
        print(g)
        GROUPS[g]()
