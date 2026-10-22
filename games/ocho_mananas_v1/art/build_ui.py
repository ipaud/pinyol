"""The interface's pictures, from the generated sheets in art/raw: panels (9-slice), icons, the photo props, the
logo, the title picture and the notebook.

    python3 games/ocho_mananas_v1/art/build_ui.py

PANELS holds 6 panels x 9 tiles (20x20): frame = panel * 9 + row * 3 + column; ui/frame.lua stretches them.
ICONS holds 18 icons (40x40) in the order of ui/icons.lua.
"""
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_sprites as bs
from build_scenery import magenta_mask, packed  # noqa: E402

RAW = bs.RAW
TILE = 20


def cells_of(src, rows, cols):
    return bs.cells(bs.key_magenta(Image.open(RAW / src)), rows, cols)


def quantized_strip(frames, cw, ch, colours):
    strip = Image.new("RGBA", (cw * len(frames), ch), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.alpha_composite(f, (i * cw, 0))
    return strip


def fit(im, cw, ch, bottom=False):
    """The picture scaled to sit inside cw x ch (centred, or standing on the bottom edge)."""
    s = min(cw / im.width, ch / im.height)
    sz = (max(1, round(im.width * s)), max(1, round(im.height * s)))
    out = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    out.alpha_composite(im.resize(sz, Image.Resampling.BOX), ((cw - sz[0]) // 2, ch - sz[1] if bottom else (ch - sz[1]) // 2))
    return out


def asset(strip, aid, n, colours, kind="background"):
    packed(strip, aid, colours, n, kind)


def panels():
    cells = cells_of("ui_panels_gen.png", 1, 6)
    tiles = []
    for c in cells:
        p = c.resize((TILE * 3, TILE * 3), Image.Resampling.BOX)
        for r in range(3):
            for k in range(3):
                tiles.append(p.crop((k * TILE, r * TILE, (k + 1) * TILE, (r + 1) * TILE)))
    asset(quantized_strip(tiles, TILE, TILE, 0), "PANELS", len(tiles), 64, "sprite")


def icons():
    cells = cells_of("ui_icons_gen.png", 3, 6)
    frames = [fit(c, 40, 40) for c in cells]
    heart = RAW / "icon_scale_gen.png"  # the balance icon: a plain balance scale (the sheet's was a heart on scales)
    if heart.exists():
        frames[5] = fit(bs.cells(bs.key_magenta(Image.open(heart)), 1, 1)[0], 40, 40)
    asset(quantized_strip(frames, 40, 40, 0), "ICONS", len(frames), 64, "sprite")


def photo():
    cells = cells_of("ui_photo_gen.png", 1, 5)
    names = ["PRINT", "PRINT_TILT", "VIEWFINDER", "FLASH", "FILM"]
    sizes = {"PRINT": (96, 112), "PRINT_TILT": (104, 112), "VIEWFINDER": (480, 320), "FLASH": (128, 128), "FILM": (192, 48)}
    for n, c in zip(names, cells):
        if n in ("PRINT_TILT", "FILM"):
            continue
        w, h = sizes[n]
        im = c.resize((w, h), Image.Resampling.BOX) if n == "VIEWFINDER" else fit(c, w, h)
        asset(im, n, 1, 48)


def logo():
    mask = Image.fromarray(np.where(magenta_mask(Image.open(RAW / "logo_gen.png")), 0, 255).astype("uint8"))
    rgba = Image.open(RAW / "logo_gen.png").convert("RGBA")
    rgba.putalpha(mask)
    rgba = rgba.crop(rgba.getbbox())
    asset(fit(rgba, 400, 150), "LOGO", 1, 48)


def shadow():
    """The soft ellipse under every actor (drawn with alpha)."""
    from PIL import ImageDraw
    im = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse((0, 0, 63, 15), fill=(42, 36, 72, 255))
    asset(im, "SHADOW", 1, 4, "sprite")


def zone():
    """The green of the way-out stretch: a small picture a quad stretches over the cobbles (drawn see-through)."""
    im = Image.new("RGBA", (16, 16), (34, 176, 88, 255))
    from PIL import ImageDraw
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 1), fill=(150, 240, 184, 255))   # the edge towards the street is lighter
    d.rectangle((0, 14, 15, 15), fill=(14, 110, 58, 255))
    asset(im, "ZONE", 1, 8, "sprite")


def pictures():
    for aid, src in (("TITLE_ART", "title_art_gen.png"), ("NOTEBOOK", "notebook_gen.png")):
        asset(Image.open(RAW / src).convert("RGBA").resize((480, 320), Image.Resampling.BOX), aid, 1, 64)


if __name__ == "__main__":
    for step in sys.argv[1:] or ["panels", "icons", "photo", "logo", "pictures", "shadow", "zone"]:
        globals()[step]()
