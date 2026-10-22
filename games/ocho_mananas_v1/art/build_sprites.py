"""Turns the generated sprite sheets in art/raw/*_gen.png (flat magenta background) into the game's actor sprites:
packed pictures drawn at the screen's full 480x320 (views/rear.lua and views/side.lua), same frame order as the
code expects.

    python3 games/ocho_mananas_v1/art/build_sprites.py            # every sheet that exists in art/raw/
    python3 games/ocho_mananas_v1/art/build_sprites.py DANI_BACK  # one

Per sheet: key out the magenta, cut the cells (rows, then columns, at the emptiest lines), scale every cell by ONE
factor (so the motion survives; a wider cell, a runner lying down, is squeezed to fit), feet on the bottom row,
quantize the whole strip to 32 colours, then tools/png2asset.py --packed.
"""
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
GAME = HERE.parent
ROOT = GAME.parents[1]
RAW = HERE / "raw"
COLOURS = 32
HERO_COLOURS = 56  # Dani is drawn big: more shades


def row_major(n, cols):
    return [(i // cols, i % cols) for i in range(n)]


def runners(cols, run, extra):
    """Four runners (one row each): `run` stride frames each, then one frame per `extra` column, across all four."""
    return ([(v, c) for v in range(4) for c in range(run)] + [(v, run + e) for e in range(extra) for v in range(4)])


# id: (cell w, cell h, [parts]); a part is (source, rows, cols, frame order as (row, col)); frames run part after part
SHEETS = {
    # 0-5 run, 6 stumble, 7 down, 8-11 sprint, 12-15 jog, 16-17 glance back, 18-19 sidestep into a recess
    "DANI_BACK": (84, 160, [("dani_back_gen.png", 1, 8, row_major(8, 8)), ("dani_backx_gen.png", 1, 12, row_major(12, 12))]),
    "DANI_FRONT": (84, 160, [("dani_front_gen.png", 1, 4, row_major(4, 4))]),
    # 0-5 run, 6 stumble, 7-10 sprint, 11-14 jog
    "DANI_SIDE": (124, 160, [("dani_side_gen.png", 1, 7, row_major(7, 7)), ("dani_sidex_gen.png", 1, 8, row_major(8, 8))]),
    "TORO_BACK": (60, 68, [("toro_back_gen.png", 1, 4, row_major(4, 4))]),
    "TORO_FRONT": (60, 68, [("toro_front_gen.png", 1, 4, row_major(4, 4))]),
    "TORO_SIDE": (104, 64, [("toro_side_gen.png", 1, 4, row_major(4, 4))]),
    "TORO_3QB": (60, 68, [("toro_3q_back_gen.png", 1, 4, row_major(4, 4))]),  # rear three-quarter, head to the left
    "TORO_3QF": (60, 68, [("toro_3q_front_gen.png", 1, 4, row_major(4, 4))]),  # front three-quarter, head to the left
    "CABE_BACK": (60, 68, [("cabe_back_gen.png", 1, 4, row_major(4, 4))]),
    "CABE_FRONT": (60, 68, [("cabe_front_gen.png", 1, 4, row_major(4, 4))]),
    "CABE_SIDE": (104, 64, [("cabe_side_gen.png", 1, 4, row_major(4, 4))]),
    "CABE_3QB": (60, 68, [("cabe_3q_back_gen.png", 1, 4, row_major(4, 4))]),
    "CABE_3QF": (60, 68, [("cabe_3q_front_gen.png", 1, 4, row_major(4, 4))]),
    # 4 runners x (4 strides, trip, down): stride frames var*4+phase, then 16+var trips, 20+var lies down
    "RUN_BACK": (36, 68, [("run_back_gen.png", 4, 6, runners(6, 4, 2))]),
    # 4 runners x 2 strides: var*2+phase
    "RUN_FRONT": (36, 68, [("run_front_gen.png", 4, 2, runners(2, 2, 0))]),
    # 4 runners x (4 strides, down): var*4+phase, then 16+var lies down
    "RUN_SIDE": (52, 68, [("run_side_gen.png", 4, 5, runners(5, 4, 1))]),
    # props: the lamp (off, lit), the banner (two waves), the ikurriña (two waves), Nico on his balcony (aiming, flash)
    "FAROLA": (48, 72, [("props_gen.png", 1, 6, [(0, 0), (0, 1)])]),
    "BANDERA": (56, 72, [("props_gen.png", 1, 6, [(0, 2), (0, 3)])]),
    "IKURRINA": (64, 72, [("props_gen.png", 1, 6, [(0, 4), (0, 5)])]),
    "NICO": (80, 96, [("nico_gen.png", 1, 2, row_major(2, 2))]),
    # refuge markers: the recess (calm, bright), the floor arrows, the side view's recess and floor zone
    "RETIRO": (40, 80, [("props2_gen.png", 1, 5, [(0, 0), (0, 1)])]),
    "FLECHA": (64, 40, [("props2_gen.png", 1, 5, [(0, 2)])]),
    "LAT_RET_FAR": (56, 96, [("props2_gen.png", 1, 5, [(0, 3)])]),
    "LAT_RET_NEAR": (96, 40, [("props2_gen.png", 1, 5, [(0, 4)])]),
}


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
            out.append(cell.crop(cell.getbbox()))
    return out


def build(aid):
    cw, ch, parts = SHEETS[aid]
    scaled = []  # (cell, scale): each sheet is scaled by its own factor (they were drawn at different sizes)
    for src, rows, cols, order in parts:
        keyed = key_magenta(Image.open(RAW / src))
        if aid.startswith("DANI"):
            keyed = drop_shadow(keyed)
        grid = cells(keyed, rows, cols)
        part = [grid[r * cols + c] for r, c in order]
        # the tallest cell fills the height, the widest one that is not lying down the width
        tall = max(f.height for f in part)
        k = min(ch / tall, cw / max(f.width for f in part if f.height > tall * 0.85))
        scaled += [(f, k) for f in part]
    frames = [f for f, _ in scaled]
    strip = Image.new("RGBA", (cw * len(frames), ch), (0, 0, 0, 0))
    for i, (f, k) in enumerate(scaled):
        s = min(k, cw / f.width, ch / f.height)
        sz = (max(1, round(f.width * s)), max(1, round(f.height * s)))
        small = f.resize(sz, Image.Resampling.BOX)
        strip.alpha_composite(small, (i * cw + (cw - sz[0]) // 2, ch - sz[1]))
    alpha = strip.getchannel("A").point(lambda a: 255 if a >= 110 else 0)
    colours = HERO_COLOURS if aid.startswith("DANI") else COLOURS
    strip = strip.convert("RGB").quantize(colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    strip = strip.convert("RGBA")
    strip.putalpha(alpha)
    strip.save(HERE / f"built_{aid}.png")
    for old in (".idx",):  # the indexed sprite this replaces
        (GAME / "assets" / f"{aid}{old}").unlink(missing_ok=True)
    subprocess.run([sys.executable, str(ROOT / "tools/png2asset.py"), str(HERE / f"built_{aid}.png"),
                    str(GAME / "assets"), aid, "--frames", str(len(frames)), "--ms", "100", "--packed",
                    "--colours", str(colours)], check=True)


if __name__ == "__main__":
    for aid in sys.argv[1:] or [a for a, v in SHEETS.items() if all((RAW / p[0]).exists() for p in v[2])]:
        build(aid)
