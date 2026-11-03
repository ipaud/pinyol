# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10.1", "fonttools>=4"]
# ///
"""El Celler's art, all drawn here by code, in the way a 1992 PC raycaster's was painted pixel by pixel.

    uv run examples/celler/art.py      # art/*.png, assets/ and gen/face.lua

- Walls: 64x64 textures (raycast() wraps each across a square of wall): rock, the brick vault, bottle racks "en rima",
  barrel heads, riddling racks (pupitres), a wooden door and its jamb, two iron gates, a lever off and on, the stairs
  down and the door out. Plain pictures: raycast reads their pixels.
- Things standing in the cellar: 32x32 plain pictures, see-through round them (ghost corks, a key, a candle, bottles,
  a barrel, a demijohn, a cork on the floor and one in flight). The ghost corks' tails are dithered, as the era did
  see-through without blending.
- The hands at the bottom of the view (the cork gun and the lantern) and the status bar's icons: packed pictures.
- The status bar: a tile layer of the picture processor, and the night watchman's face, an indexed sprite whose
  palette entries are surfaces (forehead, cheeks, nose, chin...): lib/light turns them towards the lantern's flame.
  gen/face.lua says which entry is which surface.
- The dawn at the end: a height map and a colour map of the vineyards and the mountain, for voxels().
"""
from __future__ import annotations

import math
import random
import shutil
import struct
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ART, ASSETS, GEN = HERE / "art", HERE / "assets", HERE / "gen"
T = 64  # wall texture side
S = 32  # thing side

# ------------------------------------------------------------------ colours
ROCK = (122, 100, 76)
MORTAR = (54, 43, 34)
WOOD, WOOD_D, WOOD_L = (122, 80, 44), (72, 45, 26), (160, 110, 62)
GLASS, GLASS_L, GLASS_D = (30, 66, 40), (92, 142, 92), (12, 28, 16)
IRON, IRON_L, IRON_D = (46, 46, 54), (120, 120, 132), (22, 22, 26)
BRASS, BRASS_L = (190, 150, 60), (240, 210, 120)
CORK, CORK_D, CORK_L = (196, 146, 90), (146, 100, 60), (226, 186, 130)
CHALK = (226, 222, 206)


def clamp(v: float) -> int:
    return max(0, min(255, int(v)))


def tone(c: tuple, k: float) -> tuple:
    return tuple(clamp(v * k) for v in c[:3])


def grain(img: Image.Image, amount: int, seed: int) -> Image.Image:
    """Each pixel a little lighter or darker: stone and wood are never flat."""
    rnd = random.Random(seed)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            p = px[x, y]
            if len(p) == 4 and p[3] == 0:
                continue
            d = rnd.randint(-amount, amount)
            px[x, y] = tuple(clamp(v + d) for v in p[:3]) + tuple(p[3:])
    return img


# ------------------------------------------------------------------ walls (64x64)
def rock(seed: int = 1) -> Image.Image:
    img = Image.new("RGB", (T, T), MORTAR)
    d = ImageDraw.Draw(img)
    rnd = random.Random(seed)
    y = 0
    while y < T:
        h = rnd.choice((14, 16, 18, 16))
        if T - y - h < 8:  # the last course takes what is left
            h = T - y
        x = -rnd.randrange(20)
        while x < T:
            w = 18 + rnd.randrange(16)
            k = 0.82 + rnd.random() * 0.32
            base = tone(ROCK, k)
            for ox in (0, -T, T):  # wraps across the square's edge, so squares in a row join
                x0, x1 = x + ox + 1, x + ox + w - 2
                d.rectangle((x0, y + 1, x1, y + h - 2), fill=base)
                d.line((x0, y + 1, x1, y + 1), fill=tone(base, 1.25))
                d.line((x0, y + 1, x0, y + h - 2), fill=tone(base, 1.12))
                d.line((x0 + 1, y + h - 2, x1, y + h - 2), fill=tone(base, 0.68))
                d.line((x1, y + 2, x1, y + h - 2), fill=tone(base, 0.75))
            x += w
        y += h
    return grain(img, 9, seed)


def vault() -> Image.Image:  # thin Catalan bricks laid flat, the cellar's vaults
    img = Image.new("RGB", (T, T), (88, 72, 58))
    d = ImageDraw.Draw(img)
    rnd = random.Random(7)
    for row in range(T // 6):
        y = row * 6
        off = (row % 2) * 10
        for x in range(-off, T, 20):
            k = 0.8 + rnd.random() * 0.35
            c = tone((156, 78, 50), k)
            d.rectangle((x + 1, y + 1, x + 18, y + 4), fill=c)
            d.line((x + 1, y + 1, x + 18, y + 1), fill=tone(c, 1.2))
    for y in range(0, 10):  # the soot of centuries of candles near the top
        for x in range(T):
            p = img.getpixel((x, y))
            img.putpixel((x, y), tone(p, 0.55 + y * 0.045))
    return grain(img, 6, 8)


def rack_frame(d: ImageDraw.ImageDraw) -> None:
    d.rectangle((0, 0, 3, T - 1), fill=WOOD_D)
    d.rectangle((T - 4, 0, T - 1, T - 1), fill=WOOD_D)
    d.line((1, 0, 1, T - 1), fill=WOOD)
    d.line((T - 3, 0, T - 3, T - 1), fill=WOOD)


def bottle_end(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int = 5, k: float = 1.0, chalk: bool = False) -> None:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=tone(GLASS, k))
    d.arc((cx - r, cy - r, cx + r, cy + r), 200, 290, fill=tone(GLASS_L, k))
    d.ellipse((cx - 2, cy - 2, cx + 1, cy + 1), fill=tone(GLASS_D, k))
    d.point((cx - 2, cy - 3), fill=tone((180, 220, 180), k))
    if chalk:
        d.line((cx - r + 1, cy + r - 2, cx + r - 2, cy - r + 1), fill=CHALK)


def racks(missing: bool = False) -> Image.Image:  # bottles stacked on their sides, showing their bottoms
    img = Image.new("RGB", (T, T), (14, 12, 10))
    d = ImageDraw.Draw(img)
    rnd = random.Random(3)
    for row in range(6):
        cy = 6 + row * 10 + 1
        off = 5 if row % 2 else 0
        for col in range(6):
            cx = 9 + col * 10 + off
            if cx > T - 8:
                continue
            if missing and row == 3 and col == 2:  # the hole of the bottle that is not there: the rack is a door
                d.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(4, 3, 2))
                continue
            bottle_end(d, cx, cy, 5, 0.8 + rnd.random() * 0.35)
        d.line((4, cy + 5, T - 5, cy + 5), fill=(38, 30, 22))
    for _ in range(40):  # dust
        x, y = rnd.randrange(4, T - 4), rnd.randrange(T)
        d.point((x, y), fill=(120, 112, 96))
    rack_frame(d)
    if missing:  # a chalk cross on the post, the old cellarman's mark
        d.line((58, 34, 62, 40), fill=CHALK)
        d.line((62, 34, 58, 40), fill=CHALK)
    return img


def barrels() -> Image.Image:  # a barrel's head, as they lie stacked in rows
    img = rock(11)
    d = ImageDraw.Draw(img)
    cx, cy, r = 32, 33, 29
    d.ellipse((cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2), fill=(20, 16, 12))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=WOOD)
    for x in range(cx - r, cx + r, 7):  # the head's boards
        d.line((x, cy - r, x, cy + r), fill=WOOD_D)
    hoop = Image.new("L", (T, T), 0)
    hd = ImageDraw.Draw(hoop)
    hd.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    hd.ellipse((cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4), fill=0)
    img.paste(IRON, mask=hoop)
    d.arc((cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1), 190, 280, fill=IRON_L)
    d.arc((cx - r + 5, cy - r + 5, cx + r - 5, cy + r - 5), 200, 300, fill=WOOD_L)
    d.rectangle((cx - 3, cy + 14, cx + 3, cy + 20), fill=WOOD_D)  # the tap
    d.rectangle((cx - 1, cy + 20, cx + 1, cy + 24), fill=BRASS)
    for i, (x0, y0, x1, y1) in enumerate(((cx - 12, cy - 8, cx - 4, cy - 8), (cx - 2, cy - 12, cx - 2, cy - 4),
                                           (cx + 4, cy - 12, cx + 10, cy - 4), (cx + 10, cy - 12, cx + 4, cy - 4))):
        d.line((x0, y0, x1, y1), fill=CHALK)  # chalk marks of the year it was filled
    return grain(img, 5, 12)


def pupitre() -> Image.Image:  # an A-frame riddling rack: bottles neck down in its holes, turned by hand
    img = Image.new("RGB", (T, T), (140, 100, 58))
    d = ImageDraw.Draw(img)
    for y in range(0, T, 3):
        d.line((0, y, T, y), fill=tone((140, 100, 58), 0.92 + 0.1 * math.sin(y * 0.7)))
    rnd = random.Random(5)
    for row in range(5):
        for col in range(3):
            cx, cy = 12 + col * 20, 8 + row * 12
            d.ellipse((cx - 8, cy - 4, cx + 8, cy + 5), fill=(30, 20, 12))
            d.ellipse((cx - 6, cy - 4, cx + 6, cy + 4), fill=tone(GLASS, 0.9 + rnd.random() * 0.3))
            d.ellipse((cx - 2, cy - 2, cx + 1, cy + 1), fill=GLASS_D)
            d.arc((cx - 6, cy - 4, cx + 6, cy + 4), 200, 280, fill=GLASS_L)
            if rnd.random() < 0.6:
                d.line((cx - 5, cy - 1 + rnd.randrange(3), cx - 1, cy - 3), fill=CHALK)  # the riddler's chalk stroke
    d.rectangle((0, 0, T - 1, 1), fill=WOOD_D)
    d.rectangle((0, T - 2, T - 1, T - 1), fill=WOOD_D)
    return grain(img, 6, 6)


def door() -> Image.Image:
    img = Image.new("RGB", (T, T), WOOD)
    d = ImageDraw.Draw(img)
    rnd = random.Random(9)
    for x in range(0, T, 11):
        c = tone(WOOD, 0.85 + rnd.random() * 0.3)
        d.rectangle((x, 0, x + 10, T - 1), fill=c)
        d.line((x, 0, x, T - 1), fill=WOOD_D)
        for y in range(4, T, 9):
            d.line((x + 3, y, x + 6, y + 3), fill=tone(c, 0.8))
    for y in (10, 50):
        d.rectangle((0, y, T - 1, y + 4), fill=IRON)
        d.line((0, y, T - 1, y), fill=IRON_L)
        for x in range(4, T, 10):
            d.point((x, y + 2), fill=IRON_L)
    d.ellipse((46, 26, 56, 36), outline=IRON_L)  # the ring
    d.ellipse((49, 24, 53, 28), fill=IRON)
    return grain(img, 5, 10)


def jamb() -> Image.Image:
    img = Image.new("RGB", (T, T), WOOD_D)
    d = ImageDraw.Draw(img)
    for x in range(0, T, 4):
        d.line((x, 0, x, T - 1), fill=tone(WOOD_D, 0.9 + 0.2 * math.sin(x)))
    d.rectangle((0, 0, 5, T - 1), fill=tone(WOOD_D, 0.7))
    d.rectangle((T - 6, 0, T - 1, T - 1), fill=tone(WOOD_D, 0.7))
    return grain(img, 5, 13)


def gate(padlock: bool) -> Image.Image:
    img = Image.new("RGB", (T, T), (10, 8, 8))
    d = ImageDraw.Draw(img)
    for x in range(3, T, 9):
        d.rectangle((x, 0, x + 3, T - 1), fill=IRON)
        d.line((x, 0, x, T - 1), fill=IRON_L)
        d.line((x + 3, 0, x + 3, T - 1), fill=IRON_D)
    for y in (6, 56):
        d.rectangle((0, y, T - 1, y + 3), fill=IRON)
        d.line((0, y, T - 1, y), fill=IRON_L)
    if padlock:
        d.arc((24, 18, 40, 36), 180, 360, fill=IRON_L, width=3)
        d.rectangle((22, 27, 42, 42), fill=BRASS)
        d.line((22, 27, 42, 27), fill=BRASS_L)
        d.ellipse((30, 31, 34, 35), fill=(20, 12, 4))
        d.rectangle((31, 34, 33, 39), fill=(20, 12, 4))
    else:  # worked from afar: a red plate with a lever on it
        d.rectangle((22, 24, 42, 40), fill=(150, 30, 26))
        d.rectangle((22, 24, 42, 25), fill=(200, 70, 60))
        d.line((28, 37, 36, 28), fill=CHALK, width=2)
        d.ellipse((34, 26, 38, 30), fill=CHALK)
    return img


def lever(on: bool) -> Image.Image:
    img = rock(21)
    d = ImageDraw.Draw(img)
    d.rectangle((20, 14, 44, 52), fill=IRON)
    d.rectangle((20, 14, 44, 15), fill=IRON_L)
    d.rectangle((22, 16, 42, 50), outline=IRON_D)
    lamp = (60, 220, 90) if on else (230, 50, 40)
    d.ellipse((28, 17, 36, 25), fill=lamp)
    d.point((30, 19), fill=(255, 255, 255))
    d.ellipse((29, 34, 35, 40), fill=IRON_D)
    tip = (42, 50) if on else (42, 22)
    d.line((32, 37, tip[0], tip[1]), fill=IRON_L, width=3)
    d.ellipse((tip[0] - 4, tip[1] - 4, tip[0] + 4, tip[1] + 4), fill=(200, 40, 30))
    return img


def stairs() -> Image.Image:
    img = rock(31)
    d = ImageDraw.Draw(img)
    d.rectangle((10, 18, 54, T - 1), fill=(8, 6, 6))
    d.pieslice((10, 4, 54, 34), 180, 360, fill=(8, 6, 6))
    d.arc((8, 2, 56, 36), 180, 360, fill=tone(ROCK, 1.3), width=2)
    for i in range(6):  # the steps going down into the dark
        y = 62 - i * 6
        w = 22 - i * 3
        k = 1.0 - i * 0.14
        d.rectangle((32 - w, y - 3, 32 + w, y), fill=tone(ROCK, k))
        d.line((32 - w, y - 3, 32 + w, y - 3), fill=tone(ROCK, k * 1.3))
    d.polygon(((28, 8), (36, 8), (36, 12), (40, 12), (32, 18), (24, 12), (28, 12)), fill=CHALK)  # a chalk arrow
    return img


def way_out() -> Image.Image:  # the door to the street: the dawn shows through its cracks
    img = Image.new("RGB", (T, T), (255, 214, 130))
    d = ImageDraw.Draw(img)
    rnd = random.Random(17)
    for x in range(0, T, 13):
        c = tone(WOOD, 0.8 + rnd.random() * 0.3)
        d.rectangle((x + 1, 2, x + 11, T - 3), fill=c)
        d.line((x + 1, 2, x + 1, T - 3), fill=tone(c, 1.2))
    d.rectangle((0, 30, T - 1, 33), fill=IRON)
    d.ellipse((26, 12, 38, 24), fill=(255, 226, 150))  # a sun carved in it, the light through it
    for a in range(0, 360, 45):
        r = math.radians(a)
        d.line((32 + 8 * math.cos(r), 18 + 8 * math.sin(r), 32 + 12 * math.cos(r), 18 + 12 * math.sin(r)), fill=(255, 226, 150), width=2)
    return grain(img, 4, 18)


# ------------------------------------------------------------------ things standing in the cellar (32x32)
def thing() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def dither_wisp(img: Image.Image, cx: int, y0: int, y1: int, w0: int, frame: int) -> None:
    """The ghost's tail: every other pixel, a see-through made with no blending (as the era did)."""
    for y in range(y0, y1):
        k = (y - y0) / max(1, y1 - y0)
        half = max(1, int(w0 * (1 - k)))
        sway = int(2 * math.sin(k * 5 + frame * 1.7))
        for x in range(cx - half + sway, cx + half + sway):
            if (x + y + frame) % 2 == 0 and 0 <= x < S:
                img.putpixel((x, y), (228, 236, 255, 255))


def ghost_cork(frame: int) -> Image.Image:
    """A cava cork come alive: a mushroom of cork with its wire cage and cap plate, a face, a misty tail. Frames: two of
    floating, one scared, one popping into bubbles."""
    img, d = thing()
    if frame == 3:
        rnd = random.Random(4)
        for _ in range(14):
            x, y, r = rnd.randrange(6, 26), rnd.randrange(4, 22), rnd.randrange(1, 4)
            d.ellipse((x - r, y - r, x + r, y + r), outline=(230, 240, 255, 255))
        d.ellipse((12, 8, 20, 16), fill=CORK + (255,))
        return img
    bob = (0, -2, 0)[frame]
    shake = 1 if frame == 2 else 0
    cx = 16 + shake
    top = 3 + bob
    dither_wisp(img, cx, top + 17, 31, 6, frame)
    d.rectangle((cx - 5, top + 10, cx + 4, top + 19), fill=CORK_D + (255,))  # the neck
    d.line((cx - 5, top + 10, cx - 5, top + 19), fill=CORK + (255,))
    d.ellipse((cx - 9, top, cx + 8, top + 13), fill=CORK + (255,))  # the head
    d.arc((cx - 9, top, cx + 8, top + 13), 190, 300, fill=CORK_L + (255,))
    for (x, y) in ((cx - 6, top + 4), (cx + 4, top + 3), (cx - 2, top + 10), (cx + 5, top + 8)):
        d.point((x, y), fill=CORK_D + (255,))
    d.ellipse((cx - 4, top - 2, cx + 3, top + 2), fill=BRASS + (255,))  # the cap plate
    d.line((cx - 8, top + 6, cx - 3, top), fill=IRON_L + (255,))  # the wire cage
    d.line((cx + 7, top + 6, cx + 2, top), fill=IRON_L + (255,))
    if frame == 2:  # scared: round eyes, an O of a mouth
        for ex in (cx - 4, cx + 3):
            d.ellipse((ex - 2, top + 4, ex + 2, top + 8), fill=(255, 255, 255, 255))
            d.point((ex, top + 6), fill=(20, 16, 30, 255))
        d.ellipse((cx - 1, top + 9, cx + 1, top + 12), fill=(60, 20, 30, 255))
    else:
        for ex in (cx - 4, cx + 3):
            d.rectangle((ex - 1, top + 5, ex, top + 7), fill=(24, 16, 30, 255))
            d.point((ex, top + 5), fill=(255, 255, 255, 255))
        d.point((cx - 7, top + 9), fill=(230, 120, 110, 255))
        d.point((cx + 6, top + 9), fill=(230, 120, 110, 255))
        d.arc((cx - 2, top + 7, cx + 1, top + 10), 20, 160, fill=(60, 20, 30, 255))
    return img


def cork_floor() -> Image.Image:
    img, d = thing()
    d.ellipse((10, 26, 22, 31), fill=(0, 0, 0, 0))
    d.rectangle((11, 26, 18, 30), fill=CORK_D + (255,))
    d.ellipse((16, 24, 23, 31), fill=CORK + (255,))
    d.point((19, 27), fill=CORK_D + (255,))
    d.ellipse((21, 26, 23, 29), fill=BRASS + (255,))
    return img


def cork_flying() -> Image.Image:
    img, d = thing()
    d.rectangle((13, 13, 18, 18), fill=CORK_D + (255,))
    d.ellipse((12, 11, 20, 17), fill=CORK + (255,))
    d.ellipse((14, 10, 18, 12), fill=BRASS + (255,))
    return img


def key() -> Image.Image:
    img, d = thing()
    d.ellipse((6, 20, 16, 30), outline=BRASS + (255,), width=3)
    d.rectangle((15, 24, 27, 26), fill=BRASS + (255,))
    d.rectangle((23, 26, 24, 30), fill=BRASS + (255,))
    d.rectangle((26, 26, 27, 29), fill=BRASS + (255,))
    d.line((15, 24, 27, 24), fill=BRASS_L + (255,))
    d.point((9, 21), fill=(255, 255, 230, 255))
    for (x, y) in ((11, 14), (11, 17), (8, 16), (14, 16)):  # a glint
        d.point((x, y), fill=(255, 250, 200, 255))
    return img


def candle(frame: int) -> Image.Image:
    img, d = thing()
    d.ellipse((8, 27, 24, 31), fill=BRASS + (255,))
    d.ellipse((10, 27, 22, 29), fill=BRASS_L + (255,))
    d.rectangle((13, 14, 18, 28), fill=(236, 226, 196, 255))
    d.line((13, 14, 13, 28), fill=(255, 250, 230, 255))
    d.line((15, 11, 15, 14), fill=(40, 30, 20, 255))
    fx = 15 + (frame % 2)
    d.ellipse((fx - 2, 5 - frame, fx + 2, 12), fill=(255, 190, 60, 255))
    d.ellipse((fx - 1, 8 - frame, fx + 1, 11), fill=(255, 250, 200, 255))
    return img


def bottle(magnum: bool = False) -> Image.Image:
    img, d = thing()
    if magnum:
        d.rounded_rectangle((9, 12, 22, 31), 4, fill=(26, 54, 34, 255))
        d.rectangle((13, 4, 18, 12), fill=(26, 54, 34, 255))
        d.rectangle((12, 2, 19, 9), fill=BRASS_L + (255,))
        d.rectangle((10, 18, 21, 26), fill=(240, 220, 150, 255))
        d.rectangle((12, 20, 19, 24), fill=(150, 30, 30, 255))
        d.line((10, 13, 10, 30), fill=GLASS_L + (255,))
        for (x, y) in ((6, 6), (25, 10), (4, 20), (27, 24)):
            d.line((x - 1, y, x + 1, y), fill=(255, 250, 200, 255))
            d.line((x, y - 1, x, y + 1), fill=(255, 250, 200, 255))
        return img
    d.rounded_rectangle((12, 16, 20, 31), 3, fill=GLASS + (255,))
    d.rectangle((14, 8, 18, 16), fill=GLASS + (255,))
    d.rectangle((13, 6, 19, 12), fill=BRASS + (255,))
    d.rectangle((12, 20, 20, 25), fill=(232, 226, 210, 255))
    d.line((12, 17, 12, 30), fill=GLASS_L + (255,))
    return img


def barrel() -> Image.Image:
    img, d = thing()
    d.ellipse((4, 27, 28, 31), fill=(0, 0, 0, 0))
    d.rounded_rectangle((4, 4, 28, 31), 8, fill=WOOD + (255,))
    for x in range(7, 28, 5):
        d.line((x, 5, x, 30), fill=WOOD_D + (255,))
    for y in (8, 15, 22, 28):
        d.line((5, y, 27, y), fill=IRON + (255,))
    d.line((6, 6, 6, 29), fill=WOOD_L + (255,))
    d.ellipse((14, 16, 18, 20), fill=WOOD_D + (255,))
    return img


def demijohn() -> Image.Image:
    img, d = thing()
    d.ellipse((5, 10, 27, 31), fill=(112, 84, 44, 255))
    for y in range(11, 31, 3):
        d.line((6, y, 26, y), fill=(84, 60, 30, 255))
    for x in range(8, 26, 4):
        d.line((x, 11, x, 30), fill=(140, 108, 60, 255))
    d.rectangle((13, 3, 19, 11), fill=(40, 80, 60, 255))
    d.rectangle((12, 2, 20, 4), fill=(150, 110, 60, 255))
    return img


# ------------------------------------------------------------------ the hands and the bar's icons (packed pictures)
def cork_gun(frame: int) -> Image.Image:
    """The night watchman's toy cork gun, the fairground kind, seen from behind it: the cork tied to it by a string.
    Frames: ready, the pop (the cork gone, a puff at the muzzle)."""
    w, h = 80, 64
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    kick = 4 if frame == 1 else 0
    top = 6 + kick
    d.polygon(((34, top + 6), (46, top + 6), (54, h), (26, h)), fill=IRON + (255,))  # the barrel, going away
    d.line((35, top + 6, 28, h), fill=IRON_L + (255,))
    d.line((45, top + 6, 52, h), fill=IRON_D + (255,))
    d.ellipse((33, top + 2, 47, top + 10), fill=IRON_D + (255,))
    d.polygon(((22, top + 30), (58, top + 30), (66, h), (14, h)), fill=WOOD + (255,))  # the stock
    d.line((22, top + 30, 14, h), fill=WOOD_L + (255,))
    for y in range(top + 34, h, 6):
        d.line((24, y, 56, y + 1), fill=WOOD_D + (255,))
    d.ellipse((50, top + 34, 76, h + 10), fill=(226, 170, 130, 255))  # the right hand
    d.ellipse((54, top + 30, 64, top + 42), fill=(236, 184, 146, 255))
    d.arc((50, top + 34, 76, h + 10), 200, 260, fill=(250, 208, 170, 255))
    d.rectangle((48, h - 10, 80, h), fill=(40, 46, 80, 255))  # the sleeve of the coat
    if frame == 0:
        d.ellipse((35, top - 4, 45, top + 6), fill=CORK + (255,))
        d.ellipse((37, top - 5, 43, top - 2), fill=BRASS + (255,))
        d.line((45, top + 2, 50, top + 12), fill=CHALK + (255,))
        d.line((50, top + 12, 47, top + 26), fill=CHALK + (255,))
    else:
        for (x, y, r) in ((40, top - 6, 5), (33, top - 2, 3), (48, top - 3, 3), (40, top - 12, 2)):
            d.ellipse((x - r, y - r, x + r, y + r), outline=(250, 246, 230, 255))
        d.line((45, top + 2, 42, top - 14), fill=CHALK + (255,))
    return img.crop((14, 0, 78, 64))  # 64x64, the look's largest picture


def lantern(frame: int) -> Image.Image:
    """The lantern in the left hand: brass, four panes, the flame inside. Frames 0-2 the flame moving, 3 out."""
    w, h = 48, 72
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.arc((14, 0, 34, 16), 180, 360, fill=BRASS + (255,), width=2)
    d.polygon(((12, 10), (36, 10), (32, 4), (16, 4)), fill=BRASS + (255,))
    d.rectangle((10, 12, 38, 44), fill=(60, 44, 24, 255))
    pane = (90, 70, 40, 255) if frame == 3 else (255, 226, 150, 255)
    d.rectangle((13, 14, 35, 42), fill=pane)
    if frame < 3:
        sway = (0, 1, -1)[frame]
        d.ellipse((19 + sway, 18 - frame, 29 + sway, 36), fill=(255, 170, 50, 255))
        d.ellipse((21 + sway, 24 - frame, 27 + sway, 35), fill=(255, 246, 200, 255))
    d.rectangle((23, 34, 25, 40), fill=(60, 50, 40, 255))
    for x in (13, 23, 34):
        d.line((x, 14, x, 42), fill=BRASS + (255,))
    d.rectangle((10, 42, 38, 47), fill=BRASS + (255,))
    d.line((10, 42, 38, 42), fill=BRASS_L + (255,))
    d.ellipse((8, 50, 40, 80), fill=(226, 170, 130, 255))  # the left hand round the handle below
    d.rectangle((0, 62, 34, h), fill=(40, 46, 80, 255))
    return img.crop((0, 0, 44, 64))  # the hand below is under the status bar anyway


def icon(kind: str) -> Image.Image:
    img = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if kind == "key":
        d.ellipse((0, 4, 6, 10), outline=BRASS_L + (255,), width=2)
        d.rectangle((6, 6, 13, 7), fill=BRASS_L + (255,))
        d.rectangle((10, 8, 11, 11), fill=BRASS_L + (255,))
    elif kind == "cork":
        d.rectangle((4, 7, 9, 13), fill=CORK_D + (255,))
        d.ellipse((2, 1, 11, 9), fill=CORK + (255,))
        d.ellipse((5, 0, 8, 2), fill=BRASS + (255,))
    elif kind == "match":
        d.rectangle((6, 4, 7, 13), fill=(220, 190, 130, 255))
        d.ellipse((5, 1, 8, 5), fill=(200, 40, 30, 255))
    elif kind == "bottle":
        d.rectangle((5, 5, 9, 13), fill=GLASS_L + (255,))
        d.rectangle((6, 1, 8, 5), fill=BRASS + (255,))
    elif kind == "lever":
        d.rectangle((3, 3, 10, 12), fill=IRON_L + (255,))
        d.line((6, 9, 11, 2), fill=(230, 60, 40, 255), width=2)
    return img


# ------------------------------------------------------------------ the status bar (tiles) and the face (lit indexed sprite)
def status_bar() -> Image.Image:
    img = Image.new("RGBA", (240, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    y0 = 136
    d.rectangle((0, y0, 239, 159), fill=(70, 44, 26, 255))
    for y in range(y0 + 2, 160, 4):
        d.line((0, y, 239, y), fill=(82, 52, 30, 255))
    d.line((0, y0, 239, y0), fill=(150, 104, 60, 255))
    d.line((0, y0 + 1, 239, y0 + 1), fill=(40, 24, 14, 255))
    for x0, x1 in ((4, 100), (140, 236)):  # the two insets, either side of the face
        d.rectangle((x0, y0 + 4, x1, 156), fill=(24, 16, 10, 255))
        d.line((x0, 156, x1, 156), fill=(120, 80, 46, 255))
    d.rectangle((105, y0 + 1, 134, 159), fill=(30, 20, 12, 255))  # the face's frame
    d.rectangle((105, y0 + 1, 134, y0 + 1), fill=(160, 120, 70, 255))
    for x in (2, 102, 137, 237):
        d.point((x, y0 + 4), fill=(220, 190, 110, 255))
        d.point((x, 155), fill=(220, 190, 110, 255))
    return img


# The face: each surface its own entry of the palette, so lib/light can light it. (name, flat colour, normal x, y, z:
# x right, y down, z towards the player).
FACE_SURFACES = [
    ("cap_top", (50, 56, 96), (0, -1, 0.4)),
    ("cap_brim", (30, 30, 40), (0, 0.6, 0.8)),
    ("badge", (230, 190, 80), (0, -0.3, 1)),
    ("forehead", (226, 172, 130), (0, -0.7, 0.7)),
    ("cheek_l", (220, 164, 124), (-0.8, 0, 0.6)),
    ("cheek_r", (220, 164, 124), (0.8, 0, 0.6)),
    ("nose", (236, 150, 120), (0, 0.2, 1)),
    ("chin", (200, 144, 108), (0, 0.8, 0.6)),
    ("moustache", (90, 70, 60), (0, 0.4, 0.9)),
    ("eye", (250, 250, 240), (0, 0, 1)),
    ("pupil", (30, 24, 20), (0, 0, 1)),
    ("collar", (40, 46, 80), (0, 0.9, 0.4)),
    ("mouth", (120, 40, 40), (0, 0.3, 1)),
]


def key_colour(i: int) -> tuple:
    """A colour no surface shares, kept apart in RGB565, so the converter's palette can be read back entry by entry."""
    return (8 + i * 16, 248 - i * 8, 32 + (i * 40) % 200)


def face(frame: int) -> Image.Image:
    """The night watchman, 24x24 (frames: as he is, looking left, looking right, scared, blown out, pleased)."""
    k = {n: key_colour(i) + (255,) for i, (n, _, _) in enumerate(FACE_SURFACES)}
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((4, 21, 19, 23), fill=k["collar"])
    d.ellipse((5, 5, 18, 22), fill=k["chin"])
    d.ellipse((5, 4, 18, 18), fill=k["forehead"])
    d.rectangle((5, 10, 11, 18), fill=k["cheek_l"])
    d.rectangle((12, 10, 18, 18), fill=k["cheek_r"])
    d.ellipse((5, 4, 18, 13), fill=k["forehead"])
    d.rectangle((3, 0, 20, 4), fill=k["cap_top"])
    d.rectangle((2, 5, 21, 6), fill=k["cap_brim"])
    d.rectangle((10, 1, 13, 3), fill=k["badge"])
    look = {1: -1, 2: 1}.get(frame, 0)
    if frame == 4:  # blown: eyes shut tight
        d.line((7, 10, 10, 10), fill=k["pupil"])
        d.line((13, 10, 16, 10), fill=k["pupil"])
    else:
        big = frame == 3
        for ex in (7, 13):
            d.rectangle((ex, 9 - big, ex + 3, 11), fill=k["eye"])
            d.rectangle((ex + 1 + look, 10 - big, ex + 2 + look, 11), fill=k["pupil"])
    d.rectangle((11, 11, 12, 15), fill=k["nose"])
    d.rectangle((7, 15, 16, 16), fill=k["moustache"])
    d.point((6, 16), fill=k["moustache"])
    d.point((17, 16), fill=k["moustache"])
    if frame == 3:
        d.ellipse((10, 17, 13, 20), fill=k["mouth"])
    elif frame == 4:
        d.rectangle((10, 18, 13, 19), fill=k["mouth"])
    elif frame == 5:
        d.arc((8, 15, 15, 20), 20, 160, fill=k["mouth"])
    return img


# ------------------------------------------------------------------ the dawn: vineyards and the mountain for voxels()
V = 256


def dawn_maps() -> tuple[Image.Image, Image.Image]:
    rnd = random.Random(23)
    hts = [[0.0] * V for _ in range(V)]
    for y in range(V):
        for x in range(V):
            h = 44 + 16 * math.sin(x * 0.031 + 1.3) + 12 * math.sin(y * 0.043) + 7 * math.sin((x + y) * 0.07)
            hts[y][x] = h
    peaks = [(64 + i * 11 + rnd.randrange(6), 100 + 50 * math.sin(i * 0.5) ** 2 + rnd.randrange(25)) for i in range(13)]
    for y in range(4, 40):  # the mountain's rounded stone fingers, far to the north
        for x in range(V):
            m = 0.0
            for px, ph in peaks:
                dx = (x - px) / 7.0
                if abs(dx) < 1:
                    m = max(m, ph * (1 - dx * dx) ** 0.35 * (1 - abs(y - 20) / 22))
            hts[y][x] = max(hts[y][x], hts[y][x] * 0.4 + m)
    hm = Image.new("RGB", (V, V))
    cm = Image.new("RGB", (V, V))
    hp, cp = hm.load(), cm.load()
    for y in range(V):
        for x in range(V):
            row = (x // 3) % 2 == 0 and 44 < y < 250  # rows of vines running north
            h = hts[y][x] + (5 if row else 0)
            g = clamp(h)
            hp[x, y] = (g, g, g)
            slope = hts[y][(x + 1) % V] - hts[y][x - 1]  # lit from the east, the sun low
            light = max(0.45, min(1.35, 1.0 + slope * 0.06))
            if y < 42 and hts[y][x] > 70:
                base = (196, 150, 140)  # the mountain's pinkish rock in the first light
            elif row:
                base = (84 + rnd.randrange(30), 120 + rnd.randrange(30), 40)  # vines, the grapes ready
            elif (x * 7 + y * 3) % 97 < 3 and y > 44:
                base = (90, 40, 70)  # a bunch of grapes on the ground
            else:
                base = (178, 136, 82)  # the dry soil between the rows
            cp[x, y] = tone(base, light)
    for y in range(128, 140):  # a farmhouse among the vines, its red roof
        for x in range(148, 164):
            hp[x, y] = (clamp(hts[134][156] + 9),) * 3
            cp[x, y] = (236, 226, 204) if y > 134 else (176, 84, 56)
    return hm, cm


# ------------------------------------------------------------------ out
def strip(frames: list[Image.Image]) -> Image.Image:
    s = Image.new("RGBA", (frames[0].width * len(frames), frames[0].height))
    for i, f in enumerate(frames):
        s.alpha_composite(f.convert("RGBA"), (i * f.width, 0))
    return s


def convert(png: str, aid: str, *opts: str) -> None:
    subprocess.run([sys.executable, str(ROOT / "tools" / "png2asset.py"), str(ART / png), str(ASSETS), aid, *opts],
                   check=True, stdout=subprocess.DEVNULL)


def face_palette() -> None:
    """Which entry of OBJ.pal each surface of the face got: gen/face.lua, for lib/light."""
    raw = (ASSETS / "OBJ.pal").read_bytes()
    vals = list(struct.unpack(f"<{len(raw) // 2}H", raw))

    def p565(c):
        return ((c[0] >> 3) << 11) | ((c[1] >> 2) << 5) | (c[2] >> 3)

    lines = ["-- made by art.py: the face's palette entries (OBJ.pal), each a surface for lib/light", "return {"]
    for i, (name, flat, normal) in enumerate(FACE_SURFACES):
        e = vals.index(p565(key_colour(i)))
        lines.append(f"  {{entry = {e}, name = \"{name}\", colour = 0x{flat[0]:02X}{flat[1]:02X}{flat[2]:02X}, normal = {{{normal[0]}, {normal[1]}, {normal[2]}}}}},")
    lines.append("}")
    GEN.mkdir(exist_ok=True)
    (GEN / "face.lua").write_text("\n".join(lines) + "\n")


def main() -> None:
    ART.mkdir(exist_ok=True)
    if ASSETS.exists():
        shutil.rmtree(ASSETS)
    ASSETS.mkdir()
    walls = {"rock": rock(), "vault": vault(), "racks": racks(), "secret": racks(True), "barrels": barrels(),
             "pupitre": pupitre(), "door": door(), "jamb": jamb(), "gate": gate(True), "gate_lever": gate(False),
             "lever": lever(False), "lever_on": lever(True), "stairs": stairs(), "way_out": way_out()}
    for name, img in walls.items():
        img.save(ART / f"wall_{name}.png")
        convert(f"wall_{name}.png", f"TEX_{name.upper()}", "--type", "background", "--plain")
    things = {"ghost": strip([ghost_cork(i) for i in range(4)]), "cork": cork_floor(), "cork_fly": cork_flying(),
              "key": key(), "candle": strip([candle(0), candle(1)]), "bottle": bottle(), "reserva": bottle(True),
              "barrel": barrel(), "demijohn": demijohn()}
    for name, img in things.items():
        img.save(ART / f"{name}.png")
        convert(f"{name}.png", f"SPR_{name.upper()}", "--frames", str(img.width // S), "--anchor", "16,31", "--plain")
    strip([cork_gun(0), cork_gun(1)]).save(ART / "gun.png")
    convert("gun.png", "HUD_GUN", "--frames", "2", "--packed")
    strip([lantern(i) for i in range(4)]).save(ART / "lantern.png")
    convert("lantern.png", "HUD_LANTERN", "--frames", "4", "--packed")
    for kind in ("key", "cork", "match", "bottle", "lever"):
        icon(kind).save(ART / f"icon_{kind}.png")
        convert(f"icon_{kind}.png", f"ICO_{kind.upper()}", "--packed")
    status_bar().save(ART / "bar.png")
    convert("bar.png", "BAR", "--tiles")
    strip([face(i) for i in range(6)]).save(ART / "face.png")
    convert("face.png", "FACE", "--indexed", "--frames", "6", "--palette", "OBJ")
    face_palette()
    hm, cm = dawn_maps()
    hm.save(ART / "dawn_height.png")
    cm.save(ART / "dawn_colour.png")
    convert("dawn_height.png", "DAWN_H", "--type", "background", "--plain")
    convert("dawn_colour.png", "DAWN_C", "--type", "background", "--plain")
    sys.path.insert(0, str(ROOT / "tools"))
    import font2fnt
    font2fnt.make_pack("dos_vga", str(HERE))
    for f in ("FONT_MAIN.fnt", "FONT_BOLD.fnt", "FONT_MAIN_L.fnt", "FONT_BOLD_L.fnt"):  # the engine's own, as every game
        shutil.copy(ROOT / "examples" / "naves" / "fonts" / f, HERE / "fonts" / f)


if __name__ == "__main__":
    main()
