"""Original pixel art for Zebby's warehouse prototype. Supplied mockups are references."""
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).parent
ART = HERE / "art"
ART.mkdir(exist_ok=True)
NAVY = "#0b2d3f"
WALL = "#164355"
BEAM = "#20576a"
TEAL = "#2b8290"
LIGHT = "#66b8b4"
ORANGE = "#f24406"
GOLD = "#f7c457"
CREAM = "#f4f0e7"
INK = "#0a1d2b"
WOOD = "#8a543b"
WOOD_L = "#c08352"
PINK = "#b86a76"


def background():
    im = Image.new("RGB", (720, 160), WALL)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 719, 30), fill=NAVY)
    for x in range(0, 720, 64):
        d.rectangle((x, 28, x + 7, 136), fill=BEAM)
        d.rectangle((x + 1, 29, x + 2, 135), fill=TEAL)
        d.rectangle((x + 45, 43, x + 61, 64), fill=NAVY)
        d.line((x + 48, 47, x + 58, 47), fill=TEAL)
        d.line((x + 48, 52, x + 55, 52), fill=TEAL)
    d.rectangle((0, 70, 719, 75), fill=BEAM)
    d.rectangle((0, 90, 719, 92), fill=NAVY)
    for x in (46, 350, 580):
        for xx in (x, x + 38):
            d.ellipse((xx, 48, xx + 28, 76), fill=NAVY, outline=TEAL, width=2)
            for ox, oy in ((8, 8), (17, 8), (8, 17), (17, 17)):
                d.rectangle((xx + ox, 48 + oy, xx + ox + 3, 48 + oy + 3), fill=BEAM)
    d.rectangle((356, 43, 445, 88), fill=INK, outline=WOOD_L, width=3)
    d.ellipse((387, 49, 414, 76), fill=GOLD)
    d.rectangle((368, 67, 382, 83), fill=BEAM)
    d.rectangle((420, 63, 434, 83), fill=BEAM)
    for x in (80, 235, 475, 620):
        d.line((x, 20, x, 42), fill=INK, width=2)
        d.polygon([(x - 9, 41), (x + 9, 41), (x + 5, 47), (x - 5, 47)], fill=GOLD, outline=INK)
        d.rectangle((x - 13, 47, x + 13, 49), fill="#806f52")
    for x0, x1 in ((100, 146), (396, 440)):
        d.rectangle((x0, 104, x1, 110), fill=WOOD_L, outline=INK)
        for x in range(x0 + 4, x1, 10):
            d.line((x, 105, x, 109), fill=WOOD)
    d.rectangle((0, 136, 719, 159), fill=WOOD)
    d.rectangle((0, 136, 719, 140), fill=WOOD_L)
    for x in range(0, 720, 24):
        d.line((x, 141, x, 159), fill=INK)
        d.line((x + 2, 143, x + 21, 143), fill=WOOD_L)
    for x in (18, 62, 356, 470, 590):
        d.rectangle((x, 108, x + 17, 134), fill=NAVY, outline=WOOD_L)
        d.line((x + 2, 111, x + 15, 131), fill=WOOD)
    im.save(ART / "warehouse.png")


def limb(d, points, white=True):
    d.line(points, fill=INK, width=4, joint="curve")
    if white:
        d.line(points, fill=CREAM, width=2, joint="curve")


def hero_frame(kind):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    if kind == "flat":
        d.ellipse((3, 3, 26, 12), fill=ORANGE, outline=INK)
        d.point((11, 7), fill=INK); d.point((17, 7), fill=INK)
        limb(d, [(4, 9), (0, 11)]); limb(d, [(25, 9), (30, 11)])
        return im
    if kind == "jump":
        limbs = ([(8, 13), (3, 5)], [(22, 13), (28, 5)])
        legs = ([(12, 20), (7, 24), (4, 22)], [(20, 20), (24, 24), (28, 22)])
    elif kind == "dash":
        limbs = ([(8, 13), (2, 17)], [(22, 13), (30, 11)])
        legs = ([(12, 20), (5, 23), (1, 23)], [(20, 20), (25, 23), (29, 24)])
    elif kind == "walk1":
        limbs = ([(8, 13), (3, 18)], [(22, 13), (28, 10)])
        legs = ([(12, 20), (7, 24), (4, 24)], [(20, 20), (25, 23), (29, 23)])
    elif kind == "walk2":
        limbs = ([(8, 13), (3, 10)], [(22, 13), (28, 18)])
        legs = ([(12, 20), (7, 23), (4, 23)], [(20, 20), (25, 24), (29, 24)])
    else:
        limbs = ([(8, 13), (4, 20)], [(22, 13), (27, 20)])
        legs = ([(12, 20), (10, 24), (7, 24)], [(20, 20), (22, 24), (25, 24)])
    for p in legs: limb(d, p)
    for p in limbs: limb(d, p)
    d.ellipse((6, 0, 25, 21), fill=ORANGE, outline=INK)
    d.rectangle((10, 2, 20, 18), fill=ORANGE)
    d.rectangle((11, 8, 12, 10), fill=INK)
    d.rectangle((18, 8, 19, 10), fill=INK)
    d.point((15, 11), fill=INK)
    d.line((12, 15, 15, 17, 19, 15), fill=INK)
    return im


def props_frame(kind):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    if kind == "clip":
        d.rectangle((7, 8, 25, 24), fill=INK, outline=CREAM)
        d.rectangle((8, 9, 24, 14), fill=CREAM)
        for x in (9, 15, 21): d.line((x, 9, x + 3, 14), fill=INK)
        d.rectangle((10, 17, 22, 19), fill=GOLD)
    elif kind == "box":
        d.rectangle((6, 11, 26, 31), fill=WOOD, outline=INK, width=2)
        d.line((8, 13, 24, 29), fill=WOOD_L, width=2)
        d.line((24, 13, 8, 29), fill=WOOD_L, width=2)
    elif kind == "rec":
        d.rectangle((6, 6, 27, 31), fill=INK, outline=LIGHT, width=2)
        d.ellipse((11, 11, 22, 22), fill=ORANGE)
        d.rectangle((12, 26, 20, 27), fill=GOLD)
    elif kind == "exit":
        d.rectangle((5, 4, 28, 31), fill=NAVY, outline=LIGHT, width=2)
        d.rectangle((10, 9, 23, 27), fill=INK)
        d.polygon([(17, 14), (22, 18), (17, 22)], fill=GOLD)
    elif kind == "press":
        d.rectangle((3, 26, 29, 31), fill=TEAL, outline=INK)
        d.rectangle((6, 2, 25, 7), fill=LIGHT, outline=INK)
        d.rectangle((7, 8, 10, 26), fill=BEAM)
        d.rectangle((22, 8, 25, 26), fill=BEAM)
        d.rectangle((9, 19, 23, 24), fill=GOLD, outline=INK)
    elif kind == "roller":
        d.rectangle((1, 26, 31, 31), fill=TEAL, outline=INK)
        d.rectangle((3, 5, 7, 27), fill=BEAM, outline=INK)
        d.rectangle((25, 5, 29, 27), fill=BEAM, outline=INK)
        d.ellipse((7, 10, 25, 23), fill=LIGHT, outline=INK, width=2)
    elif kind == "camera":
        d.rectangle((6, 12, 26, 25), fill=NAVY, outline=LIGHT, width=2)
        d.ellipse((12, 14, 21, 23), fill=ORANGE, outline=INK)
        d.rectangle((24, 7, 28, 13), fill=GOLD)
    return im


def sheet(frames, name):
    im = Image.new("RGBA", (32 * len(frames), 32))
    for i, frame in enumerate(frames): im.alpha_composite(frame, (i * 32, 0))
    im.save(ART / name)


if __name__ == "__main__":
    background()
    sheet([hero_frame(k) for k in ("idle", "walk1", "walk2", "flat", "jump", "dash")], "zebby.png")
    sheet([props_frame(k) for k in ("clip", "box", "rec", "exit", "press", "roller", "camera")], "props.png")
