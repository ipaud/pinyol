"""A composed mock screenshot of a market scene (480x320) from art/w2 pieces and Poncho: raw/w2_mock.png (to judge the look). Also prints the colour of the far layer's bottom row, for the
solid fill between it and the floor."""
import json
from collections import Counter
from pathlib import Path

from PIL import Image

G = Path(__file__).resolve().parent.parent
W2, W1 = G / "art" / "w2", G / "art" / "env"


def pic(name, d=W2):
    return Image.open(d / f"{name}.png").convert("RGBA")


def frame(name, i, d=W2):
    m = json.loads((d / f"{name}.json").read_text())
    return pic(name, d).crop((i * m["w"], 0, (i + 1) * m["w"], m["h"])), m["anchor"]


def put(c, im, x, y, anchor=(0, 0)):
    c.alpha_composite(im, (int(x - anchor[0]), int(y - anchor[1])))


far = pic("FM_FAR")
bot = Counter(far.getpixel((x, far.height - 1))[:3] for x in range(far.width)).most_common(1)[0][0]
print("far bottom colour 0x%02X%02X%02X" % bot)
FLOOR = 236
c = Image.new("RGBA", (480, 320), (*bot, 255))
c.alpha_composite(far, (-120, 0))
c.alpha_composite(far, (-120 + far.width, 0))
for name, x in (("FM_STALL_1", 40), ("FM_STALL_2", 250), ("FM_FOUNTAIN", 420), ("FM_LAMP", 150), ("FM_CRATEPYR", 345)):
    im = pic(name)
    put(c, im, x, FLOOR + 4, (im.width // 2, im.height))
im = pic("FM_BUNTING"); put(c, im, 240, 6, (im.width // 2, 0))
floor = pic("FT_FLOOR8")
for x in (0, 256):
    c.alpha_composite(floor, (x, FLOOR))
tiles, _ = frame("FT_TILES", 3)
m = json.loads((W2 / "FT_TILES.json").read_text())
def tile(i):
    return pic("FT_TILES").crop((i * 32, 0, i * 32 + 32, 32))
for k, i in enumerate((2, 3, 4)):
    c.alpha_composite(tile(i), (180 + 32 * k, FLOOR - 32))
c.alpha_composite(tile(2), (212, FLOOR - 64))
for k in range(4):
    c.alpha_composite(tile(12 + k % 4), (300 + 32 * k, FLOOR - 32)) if False else None
a, an = frame("FE_APPLE", 3); put(c, a, 300, FLOOR, an)
b, an = frame("FE_BEE", 2); put(c, b, 380, 150, an)
ch, an = frame("FE_CHERRY", 0); put(c, ch, 340, FLOOR, an)
for k, x in enumerate((130, 160, 190)):
    co, an = frame("FI_COIN", (k * 2) % 8); put(c, co, x, 170, an)
p = json.loads((G / "art" / "poncho.json").read_text())
im = Image.open(G / "art" / "poncho.png").convert("RGBA")
i = p["frames"].index("run_3")
put(c, im.crop((i * p["w"], 0, (i + 1) * p["w"], p["h"])), 110, FLOOR, p["anchor"])
k, an = frame("FI_KEYBOARD", 3); put(c, k, 60, FLOOR + 40, an) if False else None
for name, x, y in (("FM_FORE_CABBAGE", 20, 262), ("FM_FORE_CAT", 400, 250), ("FM_FORE_BASKET", 300, 270)):
    put(c, pic(name), x, y)
c.convert("RGB").save(G / "raw" / "w2_mock.png")
