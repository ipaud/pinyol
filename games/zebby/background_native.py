"""Warehouse panorama painted directly at Pinyol's 480x320 output resolution."""
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw

WIDTH, HEIGHT = 1440, 320
INK = "#071b29"
DEEP = "#0b2938"
WALL = "#113748"
BEAM = "#205568"
EDGE = "#2c6f7b"
STEEL = "#356a78"
WOOD = "#6d4938"
WOOD_L = "#ab7046"
GOLD = "#e5bd62"


def build():
    image = Image.new("RGB", (WIDTH, HEIGHT), WALL)
    draw = ImageDraw.Draw(image)
    rng = Random(31)
    draw.rectangle((0, 0, WIDTH, 42), fill=INK)
    for x in range(0, WIDTH, 112):
        draw.rectangle((x, 42, x + 70, 222), fill="#164353")
        draw.rectangle((x + 4, 48, x + 65, 86), fill="#204d5e")
        draw.rectangle((x + 9, 54, x + 60, 81), fill="#194253")
        draw.rectangle((x + 74, 40, x + 87, 270), fill=INK)
        draw.rectangle((x + 79, 42, x + 82, 264), fill=BEAM)
        draw.rectangle((x + 102, 43, x + 108, 259), fill="#133d4f")
    for y in (92, 151, 209):
        draw.rectangle((0, y, WIDTH, y + 9), fill=INK)
        draw.rectangle((0, y + 2, WIDTH, y + 4), fill=BEAM)
    for x in range(32, WIDTH, 77):
        draw.rectangle((x, 114, x + 42, 143), fill="#264252", outline=INK, width=2)
        draw.rectangle((x + 4, 118, x + 38, 139), outline="#427181")
        draw.line((x + 4, 118, x + 38, 139), fill="#50636b", width=2)
        draw.line((x + 38, 118, x + 4, 139), fill="#50636b", width=2)
    for x in range(0, WIDTH, 181):
        for yy in (100, 162):
            for offset in (0, 31):
                cx = x + 18 + offset
                draw.ellipse((cx, yy, cx + 27, yy + 27), fill=DEEP, outline=STEEL, width=3)
                for dx, dy in ((7, 6), (17, 6), (7, 17), (17, 17)):
                    draw.rectangle((cx + dx, yy + dy, cx + dx + 3, yy + dy + 3), fill=BEAM)
    for x in (84, 315, 580, 860, 1130, 1365):
        draw.line((x, 0, x, 68), fill=INK, width=3)
        draw.polygon(((x - 12, 65), (x + 12, 65), (x + 7, 72), (x - 7, 72)), fill=GOLD, outline=INK)
        draw.line((x - 17, 73, x + 17, 73), fill="#695e4b", width=2)
        draw.line((x - 9, 75, x + 9, 75), fill="#987f54", width=2)
    # Moon film poster repeats as set dressing along long level.
    for x in (410, 1050):
        draw.rectangle((x, 90, x + 126, 210), fill="#5b403a", outline=INK, width=4)
        draw.rectangle((x + 6, 96, x + 120, 204), fill="#1b3851")
        draw.ellipse((x + 47, 105, x + 105, 163), fill="#a3a078")
        for px, py, rr in ((67, 119, 3), (91, 134, 5), (58, 143, 4), (83, 110, 2)):
            draw.ellipse((x + px - rr, py - rr, x + px + rr, py + rr), fill="#6e897e")
        draw.ellipse((x + 64, 130, x + 67, 134), fill="#385a68")
        draw.ellipse((x + 86, 130, x + 89, 134), fill="#385a68")
        draw.arc((x + 68, 137, x + 89, 153), 12, 168, fill="#385a68", width=2)
        for sx, sy in ((23, 119), (30, 170), (108, 182)):
            draw.line((x + sx - 4, sy, x + sx + 4, sy), fill=GOLD)
            draw.line((x + sx, sy - 4, x + sx, sy + 4), fill=GOLD)
    for x in range(0, WIDTH, 16):
        draw.rectangle((x, 211 + rng.randrange(3), x + 13, 225), fill=DEEP)
    draw.rectangle((0, 226, WIDTH, 249), fill=WOOD)
    draw.rectangle((0, 226, WIDTH, 230), fill=WOOD_L)
    draw.rectangle((0, 246, WIDTH, 252), fill=INK)
    for x in range(0, WIDTH, 53):
        draw.line((x, 230, x, 246), fill="#342c2d", width=2)
        draw.line((x + 5, 238, x + 46, 238), fill="#926347", width=2)
        draw.rectangle((x + 5, 228, x + 8, 230), fill=GOLD)
    draw.rectangle((0, 253, WIDTH, 319), fill=INK)
    for x in range(0, WIDTH, 142):
        draw.rectangle((x + 7, 253, x + 17, 319), fill=DEEP, outline=INK)
        draw.rectangle((x + 117, 253, x + 127, 319), fill=DEEP, outline=INK)
        draw.polygon(((x + 17, 253), (x + 25, 253), (x + 117, 318), (x + 109, 318)), fill=BEAM)
        draw.polygon(((x + 117, 253), (x + 109, 253), (x + 17, 318), (x + 25, 318)), fill=BEAM)
        draw.line((x, 253, x + 142, 253), fill=EDGE, width=3)
    output = Path(__file__).parent / "art"
    output.mkdir(exist_ok=True)
    image.crop((0, 0, 720, HEIGHT)).save(output / "warehouse_a.png")
    image.crop((720, 0, WIDTH, HEIGHT)).save(output / "warehouse_b.png")


if __name__ == "__main__":
    build()
