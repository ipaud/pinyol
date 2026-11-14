"""Draw deterministic cross-stitch art, then convert PNGs with Pinyol's png2asset.py."""
from pathlib import Path
from PIL import Image, ImageDraw
import random

ROOT = Path(__file__).parent
ART = ROOT / "art"
ART.mkdir(exist_ok=True)
C = {
    "cloth": (241, 232, 208), "thread": (221, 208, 180),
    "sea": (52, 139, 154), "sea_light": (99, 185, 190),
    "green": (70, 137, 107), "green_light": (112, 170, 116),
    "dark": (14, 71, 76), "coral": (238, 115, 96),
    "gold": (243, 190, 84), "cream": (255, 249, 229),
    "wood": (163, 105, 72), "wood_light": (205, 148, 94),
}


def cloth():
    im = Image.new("RGB", (480, 320), C["cloth"])
    d = ImageDraw.Draw(im)
    rng = random.Random(19)
    for y in range(0, 320, 3):
        d.line((0, y, 479, y), fill=(234, 222, 196), width=1)
    for x in range(0, 480, 4):
        d.line((x, 0, x, 319), fill=(247, 239, 218), width=1)
    for _ in range(1900):
        x, y = rng.randrange(480), rng.randrange(320)
        d.point((x, y), fill=(rng.choice((231, 237, 245)), 227, 203))
    return im


def shape(im, kind, box, color, step=7):
    mask = Image.new("1", im.size)
    d = ImageDraw.Draw(mask)
    getattr(d, kind)(box, fill=1)
    stitches(im, mask, color, step)


def stitches(im, mask, color, step=7):
    d = ImageDraw.Draw(im)
    dark = tuple(max(0, c - 43) for c in color)
    for y in range(step // 2, im.height, step):
        for x in range(step // 2, im.width, step):
            if not mask.getpixel((x, y)):
                continue
            r = max(2, step // 2 - 1)
            d.line((x-r+1, y-r+1, x+r+1, y+r+1), fill=dark, width=2)
            d.line((x+r+1, y-r+1, x-r+1, y+r+1), fill=dark, width=2)
            d.line((x-r, y-r, x+r, y+r), fill=color, width=2)
            d.line((x+r, y-r, x-r, y+r), fill=color, width=2)


def tree(im, x, y, scale=1):
    shape(im, "rectangle", (x-7*scale, y, x+7*scale, y+55*scale), C["wood"], 7)
    shape(im, "ellipse", (x-37*scale, y-46*scale, x+37*scale, y+20*scale), C["green"], 7)
    shape(im, "ellipse", (x-26*scale, y-50*scale, x+17*scale, y+2*scale), C["green_light"], 7)
    for bx, by in ((-18,-15), (20,-23), (8,2)):
        shape(im, "ellipse", (x+bx*scale-5, y+by*scale-5, x+bx*scale+5, y+by*scale+5), C["coral"], 7)


def flower(im, x, y):
    shape(im, "ellipse", (x-8, y-8, x+8, y+8), C["coral"], 5)
    shape(im, "ellipse", (x-3, y-3, x+3, y+3), C["gold"], 5)


def sky(im):
    shape(im, "ellipse", (366, 43, 430, 107), C["gold"])
    for x, y in ((35, 67), (160, 100), (288, 64)):
        shape(im, "ellipse", (x, y, x+77, y+24), C["cream"])
        shape(im, "ellipse", (x+20, y-13, x+55, y+27), C["cream"])
    for x, y in ((23,45),(135,68),(267,105),(440,118)):
        shape(im, "ellipse", (x, y, x+8, y+8), C["gold"])


def make_background(farbank=False):
    im = cloth()
    sky(im)
    shape(im, "ellipse", (-50, 216, 530, 420), C["green_light"])
    shape(im, "ellipse", (-50, 258, 530, 440), C["green"])
    if not farbank:
        shape(im, "rectangle", (211, 153, 269, 319), C["sea"])
        for y in range(161, 315, 27):
            shape(im, "ellipse", (220, y, 256, y+8), C["sea_light"])
        tree(im, 78, 203)
        tree(im, 365, 207)
        tree(im, 457, 221, 0.75)
        for x, y in ((140,261),(178,281),(298,263),(412,283),(33,284)):
            flower(im, x, y)
        shape(im, "rectangle", (174, 222, 196, 254), C["wood"])
        shape(im, "rectangle", (281, 222, 300, 254), C["wood"])
    else:
        tree(im, 95, 196)
        tree(im, 350, 198)
        for x, y in ((39,267),(172,276),(242,253),(404,269),(447,291)):
            flower(im, x, y)
        shape(im, "ellipse", (353, 233, 388, 266), C["gold"])
        shape(im, "rectangle", (366, 258, 374, 282), C["coral"])
    im.save(ART / ("farbank.png" if farbank else "river.png"))


def make_bridge():
    im = Image.new("RGBA", (88, 62), (0, 0, 0, 0))
    shape(im, "rectangle", (0, 15, 87, 54), C["wood"])
    shape(im, "rectangle", (2, 18, 85, 24), C["wood_light"])
    shape(im, "rectangle", (2, 45, 85, 51), C["wood_light"])
    for x in (10, 32, 54, 76):
        shape(im, "rectangle", (x, 25, x+5, 45), C["gold"], 5)
    im.save(ART / "bridge.png")


def make_hero():
    im = Image.new("RGBA", (32, 46), (0, 0, 0, 0))
    shape(im, "ellipse", (9, 2, 24, 18), C["coral"], 4)
    shape(im, "rectangle", (5, 18, 28, 34), C["dark"], 4)
    shape(im, "rectangle", (0, 21, 8, 29), C["cream"], 4)
    shape(im, "rectangle", (25, 21, 31, 29), C["cream"], 4)
    shape(im, "rectangle", (8, 34, 14, 45), C["wood"], 4)
    shape(im, "rectangle", (20, 34, 26, 45), C["wood"], 4)
    shape(im, "ellipse", (16, 23, 23, 30), C["gold"], 4)
    im.save(ART / "hero.png")


if __name__ == "__main__":
    make_background()
    make_background(True)
    make_bridge()
    make_hero()
