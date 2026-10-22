"""Turns the generated sprite sheets in art/raw/*_gen.png (flat magenta background) into the game's actor sprites:
packed pictures drawn at the screen's full 480x320 (views/rear.lua and views/side.lua), same frame order as the
code expects.

    python3 games/ocho_mananas_v1/art/build_sprites.py            # every sheet that exists in art/raw/
    python3 games/ocho_mananas_v1/art/build_sprites.py DANI_BACK  # one

Per sheet: key out the magenta, cut the cells (rows, then columns, at the emptiest lines), scale every cell by ONE
factor (so the motion survives; a wider cell, a runner lying down, is squeezed to fit), feet on the bottom row,
quantize the whole strip to 32 colours, then tools/png2asset.py --packed.
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = Path(__file__).resolve().parent
GAME = HERE.parent
ROOT = GAME.parents[1]
RAW = HERE / "raw"
COLOURS = 32
HERO_COLOURS = 56  # the actors are drawn big: more shades
ACTORS = ("DANI", "RUN_", "TORO", "CABE")


def row_major(n, cols):
    return [(i // cols, i % cols) for i in range(n)]


def runners(cols, run, extra):
    """Four runners (one row each): `run` stride frames each, then one frame per `extra` column, across all four."""
    return ([(v, c) for v in range(4) for c in range(run)] + [(v, run + e) for e in range(extra) for v in range(4)])


# id: (H, [parts]); H is the height, in picture pixels, of the figure standing (a runner, a bull, a lamp): every
# sheet of the asset is scaled so its standing figures are H tall, and the cell grows to hold the widest frame.
# A part is (source, rows, cols, frame order as (row, col)); frames run part after part.
SHEETS = {
    # 0-5 run, 6 stumble, 7 down, 8-11 sprint, 12-15 jog, 16-17 glance back (the two sidestep-into-a-recess cells
    # that follow in the sheet are drawn with a wall beside him, so they are left out)
    "DANI_BACK": (150, [("dani_back_gen.png", 1, 8, row_major(8, 8)), ("dani_backx_gen.png", 1, 12, row_major(10, 12))]),
    "DANI_FRONT": (150, [("dani_front_gen.png", 1, 4, row_major(4, 4))]),
    # 0-5 run, 6 stumble, 7-10 sprint, 11-14 jog
    "DANI_SIDE": (150, [("dani_side_gen.png", 1, 7, row_major(7, 7)), ("dani_sidex_gen.png", 1, 8, row_major(8, 8))]),
    "TORO_BACK": (125, [("toro_back_gen.png", 1, 4, row_major(4, 4))]),
    "TORO_FRONT": (125, [("toro_front_gen.png", 1, 4, row_major(4, 4))]),
    "TORO_SIDE": (105, [("toro_side_gen.png", 1, 4, row_major(4, 4))]),
    "TORO_3QB": (125, [("toro_3q_back_gen.png", 1, 4, row_major(4, 4))]),  # rear three-quarter, head to the left
    "TORO_3QF": (125, [("toro_3q_front_gen.png", 1, 4, row_major(4, 4))]),  # front three-quarter, head to the left
    "CABE_BACK": (115, [("cabe_back_gen.png", 1, 4, row_major(4, 4))]),
    "CABE_FRONT": (115, [("cabe_front_gen.png", 1, 4, row_major(4, 4))]),
    "CABE_SIDE": (95, [("cabe_side_gen.png", 1, 4, row_major(4, 4))]),
    "CABE_3QB": (115, [("cabe_3q_back_gen.png", 1, 4, row_major(4, 4))]),
    "CABE_3QF": (115, [("cabe_3q_front_gen.png", 1, 4, row_major(4, 4))]),
    # 4 runners x (4 strides, trip, down): stride frames var*4+phase, then 16+var trips, 20+var lies down
    "RUN_BACK": (120, [("run_back_gen.png", 4, 6, runners(6, 4, 2))]),
    # 4 runners x 2 strides: var*2+phase
    "RUN_FRONT": (120, [("run_front_gen.png", 4, 2, runners(2, 2, 0))]),
    # 4 runners x (4 strides, down): var*4+phase, then 16+var lies down
    "RUN_SIDE": (120, [("run_side_gen.png", 4, 5, runners(5, 4, 1))]),
    # props: the lamp (off, lit), the banner (two waves), the ikurriña (two waves), Nico on his balcony (aiming, flash)
    "FAROLA": (72, [("props_gen.png", 1, 6, [(0, 0), (0, 1)])]),
    "BANDERA": (72, [("props_gen.png", 1, 6, [(0, 2), (0, 3)])]),
    "IKURRINA": (72, [("props_gen.png", 1, 6, [(0, 4), (0, 5)])]),
    "NICO": (96, [("nico_gen.png", 1, 2, row_major(2, 2))]),
    # refuge markers: the recess (calm, bright), the floor arrows, the side view's recess and floor zone
    "RETIRO": (80, [("props2_gen.png", 1, 5, [(0, 0), (0, 1)])]),
    "FLECHA": (40, [("flecha_gen.png", 1, 1, [(0, 0)])]),   # flat road markings: the view squashes them
    "LAT_RET_FAR": (96, [("props2_gen.png", 1, 5, [(0, 3)])]),
    "LAT_RET_NEAR": (40, [("props2_gen.png", 1, 5, [(0, 4)])]),
}
MARGIN = 3        # empty pixels kept around the widest frame, so nothing touches the edge of its cell
UPRIGHT = 0.7     # a frame at least this fraction of the standing height is upright (lying down is lower)


def key_magenta(im):
    """RGBA with the flat magenta background (and the white bands outside it) transparent."""
    if im.mode == "RGBA" and im.getchannel("A").getextrema()[0] < 200:  # it came with a real see-through background
        im = im.copy()
        im.putalpha(im.getchannel("A").point(lambda a: 255 if a >= 128 else 0))  # no haze
        return im
    im = im.convert("RGB")
    w, h = im.size
    px = im.load()
    mag = lambda p: p[0] > 200 and p[2] > 200 and p[1] < 90
    rows = [y for y in range(h) if sum(mag(px[x, y]) for x in range(0, w, 8)) > (w // 8) * 0.5]
    top, bottom = rows[0], rows[-1] + 1
    out = Image.new("RGBA", (w, bottom - top), (0, 0, 0, 0))
    po = out.load()
    for y in range(top, bottom):
        for x in range(w):
            p = px[x, y]
            # magenta, and the pink antialiasing between magenta and the dark outline
            if not (mag(p) or (p[0] > 150 and p[2] > 150 and p[1] < p[0] * 0.55 and p[1] < p[2] * 0.55)):
                po[x, y - top] = p + (255,)
    return out


def drop_shadow(im):
    """The generated sheets draw a purple ground shadow under Dani; the engine draws its own, so lose that one."""
    a = np.asarray(im.convert("RGBA")).copy()
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    purple = (r > 70) & (r < 175) & (g < 100) & (b > 140) & (b - r < 120) & (r > g + 25)
    a[..., 3] = np.where(purple, 0, a[..., 3])
    return Image.fromarray(a)


def spans(count, n):
    """n [start, end) spans of non-empty entries in the profile `count`; surplus ones merge across the smallest
    gap, missing ones (two cells touching) split where the widest span is thinnest."""
    runs, x = [], 0
    while x < len(count):
        if count[x]:
            s = x
            while x < len(count) and count[x]:
                x += 1
            runs.append([s, x])
        else:
            x += 1
    while len(runs) > n:
        g = min(range(len(runs) - 1), key=lambda i: runs[i + 1][0] - runs[i][1])
        runs[g][1] = runs[g + 1][1]
        del runs[g + 1]
    while len(runs) < n:
        g = max(range(len(runs)), key=lambda i: runs[i][1] - runs[i][0])
        a, b = runs[g]
        x = min(range((a + (b - a) * 3 // 10), (b - (b - a) * 3 // 10)), key=lambda c: count[c])
        runs[g:g + 1] = [[a, x], [x, b]]
    return runs


def tan_dust(im):
    """The generated dust of the animals is pink; the cobbles' dust is tan."""
    a = np.asarray(im.convert("RGBA")).copy()
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    pink = (r > 190) & (b >= g - 5) & (r > g + 30) & (b > 150)
    lum = (r + g + b) / 3
    a[..., 0] = np.where(pink, np.minimum(255, lum * 1.12), a[..., 0])
    a[..., 1] = np.where(pink, lum * 0.98, a[..., 1])
    a[..., 2] = np.where(pink, lum * 0.78, a[..., 2])
    return Image.fromarray(a.astype("uint8"))


def without_strays(cell):
    """Drops specks cut off from a neighbouring cell: a small piece (an outstretched hand) well away from the figure."""
    a = np.asarray(cell.getchannel("A")) > 0
    lab, n = ndimage.label(a, structure=np.ones((3, 3)))
    if n < 2:
        return cell
    sizes = ndimage.sum(a, lab, range(1, n + 1))
    main = int(np.argmax(sizes)) + 1
    keep = lab == main
    away = ndimage.distance_transform_edt(lab != main)  # pixels to the figure: dust at the feet is close, a hand is not
    for i in range(1, n + 1):
        if i == main:
            continue
        comp = lab == i
        if sizes[i - 1] < 0.15 * sizes[main - 1] and away[comp].min() > 6:
            continue
        keep |= comp
    out = np.asarray(cell).copy()
    out[..., 3] = np.where(keep, out[..., 3], 0)
    out = Image.fromarray(out)
    return out.crop(out.getbbox())


def cells(im, rows, cols):
    """rows x cols cropped cells, row-major."""
    alpha = im.getchannel("A")
    w, h = im.size
    out = []
    for y0, y1 in spans([sum(1 for v in alpha.crop((0, y, w, y + 1)).getdata() if v) for y in range(h)], rows):
        band = im.crop((0, y0, w, y1))
        ba = band.getchannel("A")
        for x0, x1 in spans([sum(1 for v in ba.crop((x, 0, x + 1, y1 - y0)).getdata() if v) for x in range(w)], cols):
            cell = band.crop((x0, 0, x1, y1 - y0))
            out.append(without_strays(cell.crop(cell.getbbox())))
    return out


def foot_and_anchor(im, upright, torso):
    """(baseline row, anchor column) of a frame: the row below which only 0.3% of the pixels (dust, a trailing
    foot) hang, and the middle of the body (head and torso for a figure standing, every pixel otherwise)."""
    a = np.asarray(im.getchannel("A")) > 0
    rows = a.sum(axis=1)
    cum = np.cumsum(rows) / max(1, rows.sum())
    foot = int(np.searchsorted(cum, 0.997))
    region = a[: max(1, int(im.height * 0.55))] if (upright and torso) else a
    ys, xs = np.nonzero(region)
    return foot, float(np.median(xs))


def build(aid):
    height, parts = SHEETS[aid]
    torso = aid.startswith(("DANI", "RUN_"))
    frames = []  # (scaled image, foot row, anchor column)
    for src, rows, cols, order in parts:
        keyed = key_magenta(Image.open(RAW / src))
        if aid.startswith(ACTORS):
            keyed = drop_shadow(keyed)
        if aid.startswith(("TORO", "CABE")):
            keyed = tan_dust(keyed)
        grid = cells(keyed, rows, cols)
        part = [grid[r * cols + c] for r, c in order]
        tallest = max(f.height for f in part)
        standing = [f.height for f in part if f.height >= UPRIGHT * tallest]
        k = height / float(np.median(standing))  # every frame of the sheet by the same factor
        for f in part:
            small = f.resize((max(1, round(f.width * k)), max(1, round(f.height * k))), Image.Resampling.BOX)
            small.putalpha(small.getchannel("A").point(lambda v: 255 if v >= 110 else 0))
            foot, anchor = foot_and_anchor(small, f.height >= UPRIGHT * tallest, torso)
            frames.append((small, foot, anchor))
    left = max(anchor for _, _, anchor in frames)
    right = max(im.width - anchor for im, _, anchor in frames)
    up = max(foot for _, foot, _ in frames)
    down = max(im.height - foot for im, foot, _ in frames)
    half = int(np.ceil(max(left, right))) + MARGIN
    cw, ch = 2 * half, up + down + 2 * MARGIN
    base = up + MARGIN  # the row the feet stand on in every cell
    strip = Image.new("RGBA", (cw * len(frames), ch), (0, 0, 0, 0))
    for i, (im, foot, anchor) in enumerate(frames):
        strip.alpha_composite(im, (i * cw + half - round(anchor), base - foot))
    alpha = strip.getchannel("A")
    colours = HERO_COLOURS if aid.startswith(ACTORS) else COLOURS
    strip = strip.convert("RGB").quantize(colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGBA")
    strip.putalpha(alpha)
    strip.save(HERE / f"built_{aid}.png")
    for old in (".idx",):  # the indexed sprite this replaces
        (GAME / "assets" / f"{aid}{old}").unlink(missing_ok=True)
    subprocess.run([sys.executable, str(ROOT / "tools/png2asset.py"), str(HERE / f"built_{aid}.png"),
                    str(GAME / "assets"), aid, "--frames", str(len(frames)), "--ms", "100", "--packed",
                    "--colours", str(colours)], check=True)
    widths = sorted(im.getchannel("A").getbbox()[2] - im.getchannel("A").getbbox()[0] for im, _, _ in frames)
    write_size(aid, {"w": cw, "h": ch, "foot": base, "ref": height, "body": widths[len(widths) // 2]})


def write_size(aid, entry):
    """views/sizes.lua: every actor picture's cell, the row its feet stand on, its standing height and body width."""
    path = HERE / "sizes.json"
    table = json.loads(path.read_text()) if path.exists() else {}
    table[aid] = entry
    path.write_text(json.dumps(table, indent=1, sort_keys=True) + "\n")
    lines = ["-- Generated by art/build_sprites.py: do not edit. For each picture: its frame size (w, h), the row its feet",
             "-- stand on (foot), the height of the figure standing (ref) and the width of its body (body), in picture pixels.",
             "return {"]
    for k in sorted(table):
        v = table[k]
        lines.append(f"  {k} = {{w = {v['w']}, h = {v['h']}, foot = {v['foot']}, ref = {v['ref']}, body = {v['body']}}},")
    lines.append("}")
    (GAME / "views" / "sizes.lua").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    for aid in sys.argv[1:] or [a for a, v in SHEETS.items() if all((RAW / p[0]).exists() for p in v[1])]:
        build(aid)
