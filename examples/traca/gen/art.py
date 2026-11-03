# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Traca's pictures, drawn by code at the size of its 160x240 standing canvas (the screen shows it turned and twice as
big, so each pixel here is a 2x2 block on the console, as a 1985 cabinet's chunky pixels were). Small sprites are
written as text, a letter a colour; round things (lanterns, balloons, clouds, the moon) are drawn with shapes.
Everything is packed (tools/png2asset.py --packed): only the visible pixels, a palette each.

    uv run examples/traca/gen/art.py            # art/*.png and assets/
    uv run examples/traca/gen/art.py --png      # only the PNGs (to look at them)
"""
from __future__ import annotations

import math
import random
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

GAME = Path(__file__).resolve().parents[1]
ROOT = GAME.parents[1]
ART, ASSETS = GAME / "art", GAME / "assets"

# The cabinet's colours: bright sprites on a dark field, a few shades each (a 1985 board's palette RAM).
PAL = {
    "K": (0x1A, 0x10, 0x28), "W": (0xF8, 0xF0, 0xD8), "w": (0xC8, 0xB8, 0x98), "R": (0xE8, 0x38, 0x38),
    "r": (0x98, 0x20, 0x30), "Y": (0xFF, 0xD8, 0x48), "y": (0xD8, 0x90, 0x20), "O": (0xFF, 0x90, 0x30),
    "H": (0xFF, 0xFF, 0xFF), "B": (0x9A, 0x68, 0x38), "b": (0x5A, 0x38, 0x18), "F": (0xFF, 0xF0, 0xA0),
    "f": (0xFF, 0x70, 0x20), "G": (0x48, 0xD0, 0x68), "g": (0x20, 0x70, 0x40), "C": (0x58, 0xE0, 0xF8),
    "c": (0x28, 0x78, 0xB0), "P": (0xFF, 0x58, 0xA8), "p": (0xA8, 0x28, 0x70), "V": (0x9C, 0x74, 0xD0),
    "v": (0x3A, 0x28, 0x58), "E": (0xFF, 0x40, 0x30), "S": (0xC0, 0xC8, 0xD8), "N": (0x70, 0x78, 0xA0),
}
NIGHT = (0x1C, 0x16, 0x3C)


def grid(rows: list[str], pal: dict = PAL) -> Image.Image:
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in pal:
                img.putpixel((x, y), (*pal[ch], 255))
    return img


def strip(frames: list[Image.Image]) -> Image.Image:
    w, h = max(f.width for f in frames), max(f.height for f in frames)
    out = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * w + (w - f.width) // 2, h - f.height), f)
    return out


def blank(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def c(ch: str, a: int = 255) -> tuple:
    return (*PAL[ch], a)


# ------------------------------------------------------------------ the rocket (the player): its heart is (4, 7)

ROCKET = [
    "....K....",
    "...KYK...",
    "...KYK...",
    "..KYYyK..",
    "..KRRrK..",
    "..KWWwK..",
    "..KRRrK..",
    "..KWHwK..",
    "..KRRrK..",
    "..KWWwK..",
    "..KRRrK..",
    ".KKKKKKK.",
    "KRK.B.KRK",
    "KK..B..KK",
    "....B....",
    "....B....",
    "....B....",
    "....B....",
    "....B....",
    "....b....",
    "....b....",
    "....b....",
]
FLAMES = [
    {12: "...FBF...", 13: "...fBf..."},
    {12: "..FFBFF..", 13: "...FBF...", 14: "...fBf...", 15: "....f...."},
    {12: "...FBF...", 13: "..fFBFf..", 14: "....f...."},
]


def rocket() -> Image.Image:
    frames = []
    for fl in FLAMES:
        rows = [fl.get(i, r) if i not in fl else "".join(b if b != "." else a for a, b in zip(r, fl[i])) for i, r in enumerate(ROCKET)]
        frames.append(grid(rows))
    return strip(frames)


# ------------------------------------------------------------------ the foes

BAT = [[
    "K..............K",
    "KK............KK",
    "KVK..K....K..KVK",
    ".KVVKVK..KVKVVK.",
    "..KVVVVKKVVVVK..",
    "...KKVEVVEVKK...",
    ".....KVVVVK.....",
    "......KVVK......",
    ".......KK.......",
    "................",
], [
    "................",
    "................",
    "......K..K......",
    ".....KVKKVK.....",
    "..KKKVEVVEVKKK..",
    ".KVVVVVVVVVVVVK.",
    "KVVKKKVVVVKKKVVK",
    "KVK...KVVK...KVK",
    "KK.....KK.....KK",
    "K..............K",
]]


def lantern(body: str, dark: str, glow: int) -> Image.Image:
    img, d = blank(12, 17)
    d.rectangle((4, 0, 7, 2), fill=c("b"))
    d.ellipse((0, 2, 11, 13), fill=c("K"))
    d.ellipse((1, 3, 10, 12), fill=c(body))
    g = 2 + glow
    d.ellipse((6 - g, 7 - g, 5 + g, 8 + g), fill=c("Y"))
    d.ellipse((5, 6, 6, 8), fill=c("F"))
    for y in (5, 8, 11):  # the paper's ribs
        d.line((2, y, 9, y), fill=c(dark))
    d.rectangle((4, 13, 7, 14), fill=c("b"))
    d.line((5, 15, 5, 16), fill=c("Y")), d.line((6, 15, 6, 16), fill=c("y"))
    return img


def balloon(body: str, dark: str) -> Image.Image:
    img, d = blank(12, 21)
    d.ellipse((0, 0, 11, 14), fill=c("K"))
    d.ellipse((1, 1, 10, 13), fill=c(body))
    d.ellipse((6, 6, 10, 13), fill=c(dark))
    d.ellipse((1, 1, 9, 11), fill=c(body))
    d.rectangle((3, 3, 4, 5), fill=c("H"))
    d.polygon([(5, 14), (6, 14), (7, 16), (4, 16)], fill=c(dark))
    for i, y in enumerate(range(17, 21)):
        img.putpixel((5 + (i % 2), y), c("S"))
    return img


DRUNK = [[
    "...F...",
    "..fFf..",
    "...f...",
    ".KKKKK.",
    ".KCCcK.",
    ".KWWwK.",
    ".KCCcK.",
    ".KHKHK.",
    ".KCCcK.",
    ".KWWwK.",
    ".KCCcK.",
    "..KRK..",
    "..KRK..",
    "...K...",
    "...B...",
    "...B...",
], [
    "..f.F..",
    "...Ff..",
    "..fF...",
    ".KKKKK.",
    ".KCCcK.",
    ".KWWwK.",
    ".KCCcK.",
    ".KKHKK.",
    ".KCCcK.",
    ".KWWwK.",
    ".KCCcK.",
    "..KRK..",
    "..KRK..",
    "...K...",
    "....B..",
    "....B..",
]]


def powder(col: str, dark: str) -> Image.Image:
    rows = [
        "...KKKK...",
        "....KK....",
        "...KYYK...",
        "..KXXXXK..",
        ".KXXHXXXK.",
        "KXXHXXXXdK",
        "KXXXXXXXdK",
        "KXXXXXXddK",
        ".KdXXXddK.",
        "..KKKKKK..",
    ]
    pal = dict(PAL, X=PAL[col], d=PAL[dark])
    return grid(rows, pal)


def boom() -> Image.Image:
    frames = []
    rnd = random.Random(7)
    for k in range(4):
        img, d = blank(17, 17)
        if k == 0:
            d.ellipse((5, 5, 11, 11), fill=c("H")), d.ellipse((6, 6, 10, 10), fill=c("F"))
        elif k == 1:
            for a in range(8):
                x, y = 8 + math.cos(a * math.pi / 4) * 7, 8 + math.sin(a * math.pi / 4) * 7
                d.line((8, 8, x, y), fill=c("Y"))
            d.ellipse((4, 4, 12, 12), fill=c("O")), d.ellipse((6, 6, 10, 10), fill=c("F"))
        elif k == 2:
            d.ellipse((2, 2, 14, 14), outline=c("f"))
            for a in range(12):
                x, y = 8 + math.cos(a * math.pi / 6) * 6, 8 + math.sin(a * math.pi / 6) * 6
                img.putpixel((round(x), round(y)), c("Y"))
            d.ellipse((7, 7, 9, 9), fill=c("O"))
        else:
            for _ in range(14):
                a, r = rnd.random() * 6.28, 4 + rnd.random() * 4
                img.putpixel((round(8 + math.cos(a) * r), round(8 + math.sin(a) * r)), c(rnd.choice("fOy")))
        frames.append(img)
    return strip(frames)


# ------------------------------------------------------------------ bullets, shots and sparks

ORB = [".pPp.", "pPHPp", "PHHHP", "pPHPp", ".pPp."]
SPARK = [".Y.", "YFY", ".Y."]
BIG = ["..yOy..", ".yOOOy.", "yOOFOOy", "OOFHFOO", "yOOFOOy", ".yOOOy.", "..yOy.."]
CONF = ["cC.", "CHC", ".Cc"]
SHOT = [".F.", "FHF", "YFY", ".Y.", ".Y.", ".y.", ".O.", ".f."]
EMBER = ["fO", "Of"]
GLINT = ["Y"]
STAR = ["N"]
STAR_B = ["S"]
SPARK_G = ["HF", "FY"]   # the palmera's head: a fresh spark
SPARK_O = ["Y"]          # and the trail it leaves, cooling
SPARK_R = ["f"]
SPARK_P = ["P"]
SPARK_C = ["C"]


# ------------------------------------------------------------------ the village (stage 1)

def town() -> Image.Image:
    """The village's roofs at night, seen from the plaza: 160x84, a cat on a roof, bunting, lit windows."""
    rnd = random.Random(3)
    img, d = blank(160, 84)
    wall, wall2, roof, edge = (0x2A, 0x20, 0x48), (0x34, 0x28, 0x58), (0x5A, 0x2A, 0x38), (0x9A, 0x48, 0x40)
    x = -4
    houses = []
    while x < 164:
        w, h = rnd.choice((18, 22, 26, 30)), rnd.randint(34, 62)
        houses.append((x, w, h))
        x += w - 1
    for i, (x, w, h) in enumerate(houses):
        top = 84 - h
        d.rectangle((x, top, x + w, 83), fill=wall if i % 2 else wall2)
        if i % 3 == 0:  # a pitched roof of tiles, its edge caught by the moon
            d.polygon([(x - 2, top), (x + w // 2, top - 9), (x + w + 2, top)], fill=roof)
            d.line((x - 2, top, x + w // 2, top - 9), fill=edge)
            for k in range(x, x + w, 3):
                img.putpixel((min(159, max(0, k)), top - 1), edge) if 0 <= k < 160 else None
        else:  # a flat roof with a railing (a terrace) and maybe an aerial
            d.rectangle((x, top - 2, x + w, top), fill=roof)
            d.line((x, top - 4, x + w, top - 4), fill=(0x50, 0x48, 0x70))
            for k in range(x, x + w + 1, 4):
                d.line((k, top - 4, k, top - 2), fill=(0x50, 0x48, 0x70))
            if rnd.random() < 0.6:
                ax = x + rnd.randint(3, w - 3)
                d.line((ax, top - 13, ax, top - 2), fill=(0x60, 0x58, 0x80))
                d.line((ax - 4, top - 11, ax + 4, top - 11), fill=(0x60, 0x58, 0x80))
                d.line((ax - 3, top - 8, ax + 3, top - 8), fill=(0x60, 0x58, 0x80))
        for wy in range(top + 6, 80, 9):  # windows, some lit
            for wx in range(x + 3, x + w - 3, 6):
                lit = rnd.random() < 0.45
                d.rectangle((wx, wy, wx + 2, wy + 3), fill=(0xFF, 0xC8, 0x50) if lit else (0x18, 0x12, 0x30))
                if lit and rnd.random() < 0.3:
                    d.line((wx, wy + 4, wx + 2, wy + 4), fill=(0x9A, 0x68, 0x38))  # a balcony's pot
    # the palm tree in the plaza
    px = 118
    for k in range(30):
        img.putpixel((px + k // 10, 83 - k), (0x3A, 0x2A, 0x30))
        img.putpixel((px + 1 + k // 10, 83 - k), (0x4A, 0x36, 0x38))
    for a in range(7):
        ang = math.pi + a * math.pi / 6
        for r in range(1, 13):
            yy = 53 - math.sin(ang) * r * 0.6 + r * r * 0.05
            img.putpixel((min(159, max(0, round(px + 3 + math.cos(ang) * r))), round(yy)), (0x24, 0x48, 0x38))
    # the cat on a roof, its eyes lit
    cx, cy = houses[2][0] + 6, 84 - houses[2][2] - 4
    for dx, dy in [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (0, -1), (1, -1), (2, -1), (3, -1), (4, -1), (4, -2), (5, -2), (4, -3), (6, -3), (-1, -1), (-2, -2), (-2, -3)]:
        img.putpixel((cx + dx, cy + dy), (0x0E, 0x0A, 0x1A))
    img.putpixel((cx + 5, cy - 2), (0xFF, 0xF0, 0x60))
    # bunting across the street
    for k in range(160):
        y = 24 + int(6 * math.sin(k / 160 * math.pi))
        img.putpixel((k, y), (0x90, 0x88, 0xA8))
        if k % 6 == 0:
            col = [(0xE8, 0x38, 0x38), (0xFF, 0xD8, 0x48), (0x48, 0xD0, 0x68), (0x58, 0xA0, 0xF8)][(k // 6) % 4]
            d.polygon([(k, y + 1), (k + 3, y + 1), (k + 1, y + 4)], fill=col)
    return img


def hills() -> Image.Image:
    img, d = blank(160, 40)
    pts = [(0, 40)]
    for x in range(0, 161, 4):
        pts.append((x, 22 - 10 * math.sin(x / 37) - 6 * math.sin(x / 13 + 1) + (8 if 60 < x < 100 else 0)))
    pts.append((160, 40))
    d.polygon(pts, fill=(0x22, 0x1C, 0x48))
    for x, y in pts[1:-1]:
        d.point((x, y), fill=(0x38, 0x30, 0x68))
    return img


def facade(side: str, variant: int) -> Image.Image:
    """A house's edge passing at the side of the street: balconies, pots, a granny waving at her window."""
    rnd = random.Random(10 + variant)
    img, d = blank(26, 96)
    wall, line_, rail = (0x34, 0x2A, 0x5C), (0x26, 0x1E, 0x46), (0x80, 0x78, 0xA8)
    d.rectangle((0, 0, 21, 95), fill=wall)
    d.line((21, 0, 21, 95), fill=(0x48, 0x3C, 0x78))
    for y in range(0, 96, 32):
        d.line((0, y, 21, y), fill=line_)
        lit = rnd.random() < 0.6
        d.rectangle((6, y + 6, 15, y + 19), fill=(0xFF, 0xC0, 0x48) if lit else (0x14, 0x10, 0x28))
        d.line((10, y + 6, 10, y + 19), fill=(0x6A, 0x40, 0x30))
        d.rectangle((3, y + 20, 25, y + 21), fill=(0x50, 0x48, 0x78))  # the balcony
        for k in range(4, 26, 3):
            d.line((k, y + 15, k, y + 20), fill=rail)
        d.line((3, y + 15, 25, y + 15), fill=rail)
        if rnd.random() < 0.7:  # a pot of geraniums
            d.rectangle((22, y + 12, 24, y + 14), fill=(0xB0, 0x58, 0x30))
            d.point([(22, y + 11), (24, y + 11), (23, y + 10)], fill=(0xE8, 0x38, 0x48))
        if lit and variant == 1 and y == 32:  # the granny at the window, waving at the rocket
            d.rectangle((9, y + 10, 12, y + 14), fill=(0x80, 0x40, 0x60))
            d.rectangle((9, y + 8, 12, y + 10), fill=(0xF0, 0xC0, 0x98))
            d.point([(8, y + 7), (13, y + 7), (9, y + 7), (12, y + 7)], fill=(0xE0, 0xE0, 0xE8))
            d.line((13, y + 9, 15, y + 6), fill=(0xF0, 0xC0, 0x98))
    return img if side == "L" else img.transpose(Image.FLIP_LEFT_RIGHT)


def bunting() -> Image.Image:
    img, d = blank(160, 12)
    for k in range(160):
        y = 1 + int(5 * math.sin(k / 160 * math.pi))
        img.putpixel((k, y), (0xB0, 0xA8, 0xC8))
        if k % 7 == 3:
            col = [(0xE8, 0x38, 0x38), (0xFF, 0xD8, 0x48), (0x48, 0xD0, 0x68), (0x58, 0xA0, 0xF8), (0xFF, 0x58, 0xA8)][(k // 7) % 5]
            d.polygon([(k - 1, y + 1), (k + 3, y + 1), (k + 1, y + 5)], fill=col)
    return img


# ------------------------------------------------------------------ the bell tower (stage 2)

BRICK, BRICK2, MORTAR = (0x6A, 0x3A, 0x40), (0x58, 0x30, 0x3A), (0x3A, 0x22, 0x30)


def bricks(d: ImageDraw.ImageDraw, w: int, h: int) -> None:
    d.rectangle((0, 0, w - 1, h - 1), fill=BRICK)
    for y in range(0, h, 4):
        d.line((0, y, w - 1, y), fill=MORTAR)
        for x in range((y // 4) % 2 * 4, w, 8):
            d.line((x, y, x, y + 3), fill=MORTAR)
    d.line((w - 1, 0, w - 1, h - 1), fill=BRICK2)
    d.line((0, 0, 0, h - 1), fill=(0x8A, 0x50, 0x50))


def tower_mid(window: bool) -> Image.Image:
    img, d = blank(40, 32)
    bricks(d, 40, 32)
    if window:
        d.rectangle((17, 8, 22, 22), fill=(0x14, 0x0E, 0x22))
        d.pieslice((17, 5, 22, 11), 180, 360, fill=(0x14, 0x0E, 0x22))
    return img


def tower_clock() -> Image.Image:
    img, d = blank(40, 32)
    bricks(d, 40, 32)
    d.ellipse((10, 4, 29, 23), fill=(0xE8, 0xE0, 0xC8), outline=(0x30, 0x20, 0x30))
    for a in range(12):
        x, y = 19.5 + math.cos(a * math.pi / 6) * 8, 13.5 + math.sin(a * math.pi / 6) * 8
        d.point((round(x), round(y)), fill=(0x30, 0x20, 0x30))
    d.line((19, 14, 19, 7), fill=(0x30, 0x20, 0x30)), d.line((20, 14, 25, 14), fill=(0x30, 0x20, 0x30))  # nearly midnight: the fireworks
    return img


def belfry() -> Image.Image:
    img, d = blank(40, 44)
    bricks(d, 40, 44)
    d.rectangle((0, 40, 39, 43), fill=(0x9A, 0x80, 0x78))  # the cornice
    d.rectangle((6, 6, 33, 38), fill=(0x10, 0x0A, 0x1C))  # the arch where the bell hangs
    d.pieslice((6, -4, 33, 16), 180, 360, fill=BRICK)
    d.pieslice((6, 0, 33, 22), 180, 360, fill=(0x10, 0x0A, 0x1C))
    d.line((19, 5, 19, 11), fill=(0x60, 0x50, 0x48))  # the bell's beam
    d.line((8, 11, 31, 11), fill=(0x60, 0x50, 0x48))
    return img


def dome() -> Image.Image:
    """The blue glazed-tile cupola of the bell tower, and its weathervane."""
    img, d = blank(40, 46)
    d.rectangle((2, 38, 37, 45), fill=(0x9A, 0x80, 0x78))
    d.pieslice((3, 14, 36, 62), 180, 360, fill=(0x28, 0x50, 0xA8))
    for k in range(5, 36, 4):  # the tiles' ribs
        d.line((k, 38, 19 + (k - 19) // 3, 16), fill=(0x48, 0x80, 0xD8))
    d.arc((3, 14, 36, 62), 200, 260, fill=(0x90, 0xC8, 0xF8))
    d.rectangle((18, 6, 21, 15), fill=(0xD8, 0xB0, 0x48))
    d.line((19, 0, 19, 6), fill=(0x90, 0x90, 0xA8))
    d.polygon([(13, 2), (19, 1), (25, 2), (19, 3)], fill=(0x90, 0x90, 0xA8))  # the vane, an arrow
    return img


def bell() -> Image.Image:
    frames = []
    for k in (-1, 0, 1):
        img, d = blank(20, 20)
        base = [(6, 3), (13, 3), (16, 14), (17, 16), (2, 16), (3, 14)]
        cx = 9.5
        pts = []
        for x, y in base:  # the bell tilted about its top
            a = k * 0.35
            pts.append((cx + (x - cx) * math.cos(a) - (y - 2) * math.sin(a), 2 + (x - cx) * math.sin(a) + (y - 2) * math.cos(a)))
        d.polygon(pts, fill=(0xC8, 0x90, 0x40), outline=(0x70, 0x48, 0x20))
        d.line((pts[0][0] + 1, pts[0][1] + 1, pts[5][0] + 2, pts[5][1] - 1), fill=(0xF8, 0xD8, 0x80))
        tx, ty = cx + k * -5, 17
        d.ellipse((tx - 1, ty - 1, tx + 1, ty + 1), fill=(0x50, 0x30, 0x18))
        d.rectangle((8, 0, 11, 2), fill=(0x50, 0x30, 0x18))
        frames.append(img)
    return strip(frames)


# ------------------------------------------------------------------ clouds (stage 3)

def cloud(w: int, h: int, seed: int) -> Image.Image:
    rnd = random.Random(seed)
    img, d = blank(w, h)
    blobs = [(rnd.uniform(h * 0.4, w - h * 0.4), rnd.uniform(h * 0.45, h * 0.7), rnd.uniform(h * 0.28, h * 0.48)) for _ in range(w // 7)]
    for col, dy in (((0x30, 0x34, 0x6C), 1.0), ((0x4A, 0x50, 0x8C), 0), ((0x6A, 0x72, 0xA8), -1.5)):
        for x, y, r in blobs:
            rr = r if dy <= 0 else r
            d.ellipse((x - rr, y - rr + dy, x + rr, y + rr + dy), fill=col) if dy >= 0 else d.ellipse((x - rr * 0.6, y - rr * 0.9, x + rr * 0.5, y + rr * 0.1), fill=col)
    d.rectangle((0, h - 2, w, h), fill=(0, 0, 0, 0))
    return img


# ------------------------------------------------------------------ the cardboard moon (the boss) and the real one

def moon_face(mood: int) -> Image.Image:
    """64x64: 0 smiling, 1 cross, 2 patched up (a plaster and a bite torn out of the cardboard), 3 dizzy."""
    img, d = blank(64, 64)
    edge, card, shade, line_ = (0xA0, 0x70, 0x30), (0xF0, 0xD0, 0x70), (0xD8, 0xB0, 0x58), (0x50, 0x30, 0x20)
    d.ellipse((2, 2, 61, 61), fill=edge)
    d.ellipse((4, 4, 59, 59), fill=card)
    d.chord((4, 4, 59, 59), 20, 160, fill=shade)
    d.ellipse((4, 4, 59, 59), fill=None, outline=edge)
    for a in range(0, 360, 30):  # the cardboard's cut edge, notched by the scissors
        x, y = 31.5 + math.cos(math.radians(a)) * 30, 31.5 + math.sin(math.radians(a)) * 30
        d.point((round(x), round(y)), fill=(0, 0, 0, 0))
    d.rectangle((29, 0, 34, 4), fill=(0x90, 0x90, 0xA8))  # the hook it hangs from
    # cheeks
    d.ellipse((10, 36, 19, 42), fill=(0xF0, 0x90, 0x80)), d.ellipse((44, 36, 53, 42), fill=(0xF0, 0x90, 0x80))
    # eyes
    if mood == 3:
        for ex in (20, 43):
            for t in range(0, 26):
                a, r = t * 0.6, t * 0.18
                d.point((round(ex + math.cos(a) * r), round(26 + math.sin(a) * r)), fill=line_)
    else:
        for ex in (20, 43):
            d.ellipse((ex - 4, 22, ex + 4, 31), fill=(0xFF, 0xF8, 0xE8), outline=line_)
            d.ellipse((ex - 2, 25, ex + 2, 30), fill=line_)
            d.point((ex - 1, 26), fill=(0xFF, 0xFF, 0xFF))
        if mood == 1:  # cross brows
            d.line((14, 17, 24, 21), fill=line_, width=2), d.line((39, 21, 49, 17), fill=line_, width=2)
        else:
            d.arc((15, 15, 25, 21), 200, 340, fill=line_), d.arc((38, 15, 48, 21), 200, 340, fill=line_)
    # nose
    d.arc((28, 28, 36, 38), 300, 120, fill=line_)
    # mouth
    if mood == 0:
        d.chord((20, 34, 43, 50), 20, 160, fill=(0x90, 0x30, 0x30), outline=line_)
        d.rectangle((27, 45, 36, 47), fill=(0xFF, 0x80, 0x80))
    elif mood == 1:
        d.arc((22, 44, 41, 54), 200, 340, fill=line_, width=2)
    elif mood == 2:
        d.line((23, 46, 40, 44), fill=line_, width=2)
    else:
        d.ellipse((27, 42, 36, 50), fill=(0x90, 0x30, 0x30), outline=line_)
    if mood >= 2:  # the plaster, and the bite out of the edge showing the cardboard's waves
        d.polygon([(44, 40), (54, 35), (56, 38), (46, 43)], fill=(0xF8, 0xE8, 0xD0), outline=(0xB8, 0x98, 0x80))
        d.polygon([(48, 37), (50, 36), (51, 39), (49, 40)], fill=(0xE0, 0xC0, 0xA0))
        d.pieslice((40, 48, 70, 72), 180, 270, fill=(0, 0, 0, 0))
        for k in range(46, 58, 2):
            d.point((k, 54 + (k % 4 == 0)), fill=edge)
    return img


def moon() -> Image.Image:
    return strip([moon_face(i) for i in range(4)])


def real_moon() -> Image.Image:
    img, d = blank(40, 40)
    d.ellipse((0, 0, 39, 39), fill=(0xE8, 0xE8, 0xD8))
    d.chord((0, 0, 39, 39), 300, 120, fill=(0xD0, 0xD0, 0xC8))
    for x, y, r in ((12, 12, 4), (25, 20, 3), (16, 27, 2), (28, 9, 2)):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(0xC0, 0xC0, 0xB8))
    return img


def icons() -> Image.Image:
    """The status line's icons: a life (a little rocket), a traca (a string of firecrackers), a shield."""
    life = grid(["..K..", ".KYK.", ".KRK.", ".KWK.", ".KRK.", "KKKKK", "..B..", "..B.."])
    traca = grid(["K....", "RK...", ".RK..", "..RK.", "...RK", "....F", ".....", "....."])
    shield = grid([".CCC.", "CHHHC", "CHCHC", "CHHHC", ".CHC.", "..C..", ".....", "....."])
    return strip([life, traca, shield])


# ------------------------------------------------------------------ build

PICTURES = {
    "SPR_ROCKET": (rocket, 3), "SPR_BAT": (lambda: strip([grid(f) for f in BAT]), 2),
    "SPR_LANTERN": (lambda: strip([lantern("R", "r", 0), lantern("R", "r", 1), lantern("G", "g", 0), lantern("G", "g", 1)]), 4),
    "SPR_BALLOON": (lambda: strip([balloon("P", "p"), balloon("C", "c"), balloon("Y", "y")]), 3),
    "SPR_DRUNK": (lambda: strip([grid(f) for f in DRUNK]), 2),
    "SPR_POWDER": (lambda: strip([powder("R", "r"), powder("G", "g"), powder("C", "c")]), 3),
    "SPR_BOOM": (boom, 4), "SPR_BELL": (bell, 3), "SPR_MOON": (moon, 4), "SPR_ICONS": (icons, 3),
    "B_ORB": (lambda: grid(ORB), 1), "B_SPARK": (lambda: grid(SPARK), 1), "B_BIG": (lambda: grid(BIG), 1),
    "B_CONF": (lambda: grid(CONF), 1), "B_SHOT": (lambda: grid(SHOT), 1), "B_EMBER": (lambda: grid(EMBER), 1),
    "B_GLINT": (lambda: grid(GLINT), 1), "B_STAR": (lambda: grid(STAR), 1), "B_STAR2": (lambda: grid(STAR_B), 1),
    "B_PALM_G": (lambda: grid(SPARK_G), 1), "B_PALM_O": (lambda: grid(SPARK_O), 1), "B_PALM_R": (lambda: grid(SPARK_R), 1),
    "B_PALM_P": (lambda: grid(SPARK_P), 1), "B_PALM_C": (lambda: grid(SPARK_C), 1),
    "BG_TOWN": (town, 1), "BG_HILLS": (hills, 1), "BG_BUNTING": (bunting, 1),
    "BG_FACADE_L": (lambda: strip([facade("L", 0), facade("L", 1)]), 2),
    "BG_FACADE_R": (lambda: strip([facade("R", 0), facade("R", 1)]), 2),
    "BG_TOWER": (lambda: strip([tower_mid(False), tower_mid(True), tower_clock()]), 3),
    "BG_BELFRY": (belfry, 1), "BG_DOME": (dome, 1),
    "BG_CLOUDS": (lambda: strip([cloud(96, 26, 1), cloud(64, 20, 2), cloud(44, 16, 3)]), 3),
    "BG_MOON": (real_moon, 1),
}


def main() -> None:
    ART.mkdir(exist_ok=True), ASSETS.mkdir(exist_ok=True)
    for pid, (make, frames) in PICTURES.items():
        img = make()
        png = ART / f"{pid.lower()}.png"
        img.save(png)
        if "--png" in sys.argv:
            continue
        subprocess.run([sys.executable, str(ROOT / "tools" / "png2asset.py"), str(png), str(ASSETS), pid, "--packed", "--frames", str(frames), "--anchor", "0,0"],
                       check=True, stdout=subprocess.DEVNULL)
    print(f"{len(PICTURES)} pictures in {ART.relative_to(ROOT)}" + ("" if "--png" in sys.argv else f" and {ASSETS.relative_to(ROOT)}"))


if __name__ == "__main__":
    main()
