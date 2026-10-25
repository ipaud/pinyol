"""A contact sheet of every strip in art/ (frames magnified, ground line green, names on them): raw/contact_<name>.png.   python3 gen/contact.py [zoom]"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

G = Path(__file__).resolve().parent.parent
Z = int(sys.argv[1]) if len(sys.argv) > 1 else 3
for js in sorted((G / "art").glob("poncho*.json")):
    m = json.loads(js.read_text())
    im = Image.open(js.with_suffix(".png")).convert("RGBA")
    w, h, n = m["w"], m["h"], len(m["frames"])
    cols = 8 if w <= 64 else 6
    s = Image.new("RGBA", (cols * w * Z, ((n + cols - 1) // cols) * h * Z), (110, 140, 190, 255))
    d = ImageDraw.Draw(s)
    for i, name in enumerate(m["frames"]):
        x, y = (i % cols) * w * Z, (i // cols) * h * Z
        fr = im.crop((i * w, 0, (i + 1) * w, h)).resize((w * Z, h * Z), Image.NEAREST)
        s.alpha_composite(fr, (x, y))
        d.line((x, y + m["anchor"][1] * Z, x + w * Z, y + m["anchor"][1] * Z), fill=(0, 255, 0, 255))
        d.rectangle((x, y, x + w * Z - 1, y + h * Z - 1), outline=(255, 255, 0, 120))
        d.text((x + 3, y + 3), name, fill=(255, 255, 255, 255))
    s.convert("RGB").save(G / "raw" / f"contact_{js.stem}.png")
