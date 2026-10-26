"""A preview of art/env: python3 gen/envview.py out.png name ... (strips or single pictures, on blue, magnified by Z with the first arg 'z=2')"""
import json, sys
from pathlib import Path
from PIL import Image
G = Path(__file__).resolve().parent.parent / "art" / "env"
args = sys.argv[1:]
Z = 1
if args[0].startswith("z="): Z = int(args[0][2:]); args = args[1:]
out, names = args[0], args[1:]
ims = []
for n in names:
    im = Image.open(G / f"{n}.png").convert("RGBA")
    j = G / f"{n}.json"
    if j.exists():
        m = json.loads(j.read_text())
        for i in range(im.width // m["w"]):
            ims.append(im.crop((i * m["w"], 0, (i + 1) * m["w"], m["h"])))
    else:
        ims.append(im)
W = 1500
x = y = rowh = 0
pos = []
for i in ims:
    i = i.resize((i.width * Z, i.height * Z), Image.NEAREST)
    if x + i.width > W: x, y, rowh = 0, y + rowh + 4, 0
    pos.append((i, x, y)); x += i.width + 4; rowh = max(rowh, i.height)
c = Image.new("RGBA", (W, y + rowh), (110, 140, 190, 255))
for i, px, py in pos: c.alpha_composite(i, (px, py))
c.convert("RGB").save(Path(__file__).resolve().parent.parent / "raw" / out)
