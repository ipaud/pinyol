"""The feet row of every strip, 3x: the bottom 30% of each cell down to 6 px under the ground line, with the ground line in green: raw/feet_<name>.png. Shoes, wheels and dino feet must be whole."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

G = Path(__file__).resolve().parent.parent
Z = 3
for js in sorted((G / "art").glob("poncho*.json")):
    m = json.loads(js.read_text())
    im = Image.open(js.with_suffix(".png")).convert("RGBA")
    w, h, n = m["w"], m["h"], len(m["frames"])
    y0 = max(0, m["anchor"][1] - int(0.3 * 80))
    ch = h - y0
    cols = 8 if w <= 96 else 6
    s = Image.new("RGBA", (cols * w * Z, ((n + cols - 1) // cols) * ch * Z), (110, 140, 190, 255))
    d = ImageDraw.Draw(s)
    for i in range(n):
        x, y = (i % cols) * w * Z, (i // cols) * ch * Z
        s.alpha_composite(im.crop((i * w, y0, (i + 1) * w, h)).resize((w * Z, ch * Z), Image.NEAREST), (x, y))
        gy = y + (m["anchor"][1] - y0) * Z
        d.line((x, gy, x + w * Z, gy), fill=(0, 255, 0, 255))
        d.rectangle((x, y, x + w * Z - 1, y + ch * Z - 1), outline=(255, 255, 0, 120))
        d.text((x + 3, y + 3), m["frames"][i], fill=(255, 255, 255, 255))
    s.convert("RGB").save(G / "raw" / f"feet_{js.stem}.png")
