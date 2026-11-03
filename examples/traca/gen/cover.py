# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Traca's cover, 240x160, for the console's menu. The menu is seen with the console held the usual way, so a shot of
the game (which stands up) would lie on its side there: the cover is composed for the wide screen instead, from the
game's own pictures (art/, made by gen/art.py): the village at night, a palmera bursting over it, the rocket
climbing and the title in the arcade_80s pack's letters.

    uv run examples/traca/gen/cover.py      # art/cover.png, then cover.rgb565 (tools/cover.py --from)
"""
from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

GAME = Path(__file__).resolve().parents[1]
ROOT = GAME.parents[1]
ART = GAME / "art"
FONT = ROOT / "third_party" / "fonts" / "pressstart2p" / "PressStart2P-Regular.ttf"
W, H = 240, 160


def sky(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    top, bot = (0x10, 0x10, 0x40), (0x58, 0x30, 0x60)
    for i in range(10):
        k = i / 9
        c = tuple(round(a + (b - a) * k) for a, b in zip(top, bot))
        d.rectangle((0, i * 16, W, i * 16 + 16), fill=c)


def palmera(img: Image.Image, cx: float, cy: float, n: int, speed: float, cols: list[tuple]) -> None:
    for i in range(n):
        a = i / n * math.tau
        x, y, vx, vy = cx, cy, math.cos(a) * speed, math.sin(a) * speed - 0.3
        for t in range(70):
            vx, vy = vx * 0.975, (vy + 0.03) * 0.975
            x, y = x + vx, y + vy
            if 0 <= x < W and 0 <= y < H:
                c = cols[0] if t > 60 else cols[1] if t > 25 else cols[2]
                img.putpixel((int(x), int(y)), c)


def text(d: ImageDraw.ImageDraw, s: str, x: int, y: int, size: int, fill: tuple, outline: tuple) -> None:
    f = ImageFont.truetype(str(FONT), size)
    w = d.textlength(s, font=f)
    x = round(x - w / 2)
    for ox in (-2, -1, 0, 1, 2):
        for oy in (-2, -1, 0, 1, 2):
            d.text((x + ox, y + oy), s, font=f, fill=outline)
    d.text((x + 2, y + 3), s, font=f, fill=(0x0A, 0x08, 0x18))
    d.text((x, y), s, font=f, fill=fill)


def main() -> None:
    img = Image.new("RGB", (W, H))
    sky(img)
    for x, y in ((20, 20), (64, 52), (200, 70), (150, 14), (226, 30), (110, 60), (8, 70)):
        img.putpixel((x, y), (0xC0, 0xC8, 0xD8))
    moon = Image.open(ART / "bg_moon.png")
    img.paste(moon, (192, 8), moon)
    palmera(img, 168, 52, 36, 1.7, [(0xE8, 0x60, 0x20), (0xFF, 0xB0, 0x40), (0xFF, 0xF0, 0xA0)])
    palmera(img, 60, 44, 24, 1.2, [(0x28, 0x78, 0xB0), (0x58, 0xE0, 0xF8), (0xE8, 0xFF, 0xFF)])
    hills = Image.open(ART / "bg_hills.png")
    town = Image.open(ART / "bg_town.png")
    for x in (0, 160):
        img.paste(hills, (x, H - 64), hills)
    for x in (-40, 120):
        img.paste(town, (x, H - 84), town)
    rocket = Image.open(ART / "spr_rocket.png").crop((9, 0, 18, 22)).resize((18, 44), Image.NEAREST)
    img.paste(rocket, (111, 70), rocket)
    d = ImageDraw.Draw(img)
    text(d, "TRACA", W // 2, 18, 32, (0xFF, 0xD8, 0x48), (0x5A, 0x10, 0x28))
    png = ART / "cover.png"
    img.save(png)
    subprocess.run([sys.executable, str(ROOT / "tools" / "cover.py"), str(GAME), "--from", str(png)], check=True)


if __name__ == "__main__":
    main()
