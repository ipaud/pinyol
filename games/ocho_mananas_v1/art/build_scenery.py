"""The street, from the generated pictures in art/raw: the rear view's facades (STREET_REAR, the road keyed out so the
Mode 7 floor shows through), the floor's cobbles (FLOOR), and the side view's three scrolling layers.

    python3 games/ocho_mananas_v1/art/build_scenery.py

Also prints the camera numbers (race/camera.lua HOR, CAM_H) that make the Mode 7 road meet the painted kerbs.
"""
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
GAME = HERE.parent
ROOT = GAME.parents[1]
RAW = HERE / "raw"
ASSETS = GAME / "assets"
SCREEN = (480, 320)


def png2asset(png, aid, *args):
    subprocess.run([sys.executable, str(ROOT / "tools/png2asset.py"), str(png), str(ASSETS), aid, *args], check=True)


def magenta_mask(rgb):
    """True where the picture is the flat magenta key (or its antialiased fringe)."""
    a = np.asarray(rgb.convert("RGB")).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return (r > 190) & (b > 190) & (g < 110) | ((r > 150) & (b > 150) & (g < r * 0.55) & (g < b * 0.55))


def to_screen(im, size=SCREEN):
    return im.resize(size, Image.Resampling.BOX)


def packed(im, aid, colours, frames=1, kind="background"):
    """RGBA -> quantized strip -> packed asset (alpha is 1 bit)."""
    alpha = im.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    q = im.convert("RGB").quantize(colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGBA")
    q.putalpha(alpha)
    tmp = HERE / f"built_{aid}.png"
    q.save(tmp)
    (ASSETS / f"{aid}.idx").unlink(missing_ok=True)
    png2asset(tmp, aid, "--packed", "--colours", str(colours), "--frames", str(frames), "--type", kind)


def tile_x(im, overlap):
    """A picture that wraps sideways: the last `overlap` columns fade into the first ones."""
    a = np.asarray(im.convert("RGB")).astype(float)
    h, w, _ = a.shape
    out = a[:, : w - overlap].copy()
    t = np.linspace(0, 1, overlap)[None, :, None]
    out[:, :overlap] = a[:, w - overlap:] * (1 - t) + a[:, :overlap] * t
    return Image.fromarray(out.round().astype("uint8"))


def street_rear():
    src = Image.open(RAW / "street_rear_gen.png").convert("RGB")
    key = magenta_mask(src)
    alpha = Image.fromarray(np.where(key, 0, 255).astype("uint8")).filter(ImageFilter.MinFilter(9))  # drops the fringe
    rgba = src.convert("RGBA")
    rgba.putalpha(alpha)
    small = to_screen(rgba)
    packed(small, "STREET_REAR", 64)
    # the road's edges on the 480x320 screen: leftmost and rightmost see-through pixel of each row
    a = np.asarray(small.getchannel("A")) < 128
    rows = [(y, np.nonzero(a[y])[0]) for y in range(150, 320) if a[y].any()]
    ys = np.array([y for y, xs in rows], float)
    left = np.array([xs.min() for y, xs in rows], float)
    right = np.array([xs.max() for y, xs in rows], float)
    # both edges are lines through the vanishing point: half-width = slope * (y - horizon)
    width = right - left
    slope, c = np.polyfit(ys, width / 2, 1)
    horizon = -c / slope
    centre = float(np.mean((left + right) / 2))
    print(f"STREET_REAR: horizon y={horizon:.1f} (screen) -> HOR={horizon / 2:.1f}; road centre x={centre:.1f}; "
          f"half-width slope {slope:.3f} -> CAM_H={32 / slope:.1f}"  # HALF=32 units: the slope is the same in world px
          )


def floor():
    src = Image.open(RAW / "cobbles_gen.png").convert("RGB")
    n = 64
    crop = src.crop((0, 0, 640, 640)).resize((n, n), Image.Resampling.BOX)
    a = np.asarray(crop).astype(float)
    rolled = np.roll(a, (n // 2, n // 2), axis=(0, 1))  # its edges are the picture's middle: continuous across the wrap
    m = 14
    ramp = np.clip(np.minimum(np.arange(n), n - 1 - np.arange(n)) / m, 0, 1)
    w = (ramp[:, None] * ramp[None, :])[..., None]
    seamless = Image.fromarray((a * w + rolled * (1 - w)).round().astype("uint8"))
    q = seamless.quantize(24, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    full = Image.new("RGB", (256, 256))
    for ty in range(4):
        for tx in range(4):
            full.paste(q, (tx * n, ty * n))
    tmp = HERE / "built_FLOOR.png"
    full.save(tmp)
    for f in ("FLOOR.tiles", "FLOOR.map", "WORLD.pal"):
        (ASSETS / f).unlink(missing_ok=True)
    png2asset(tmp, "FLOOR", "--tiles", "--affine", "--palette", "WORLD")


def side():
    src = Image.open(RAW / "street_side_gen.png").convert("RGB")
    full = to_screen(src)
    wall_end, ground_end = 203, 253  # screen rows: the buildings' foot, the fence's posts
    layers = {
        "LAT_WALL": full.crop((0, 0, 480, wall_end)),
        "LAT_GROUND": full.crop((0, wall_end, 480, ground_end)),
        "LAT_FENCE": full.crop((0, ground_end, 480, 320)),
    }
    for aid, im in layers.items():  # 400 wide (480 - the 80 that fade), drawn repeated with that period
        packed(tile_x(im, 80).convert("RGBA"), aid, 64)


def scene():
    """The talking scenes' street: the side view's picture whole."""
    packed(to_screen(Image.open(RAW / "street_side_gen.png").convert("RGB")).convert("RGBA"), "SCENE_CALLE", 64)


def pics():
    """The talking scenes' pictures: two backgrounds, and three prints (framed, their dark corners see-through)."""
    for aid, src in (("PIC_TALLER", "pic_taller_gen.png"), ("PIC_BAR", "pic_bar_gen.png"), ("PIC_MESA", "pic_mesa_gen.png"),
                     ("PIC_MERCADERES", "pic_mercaderes_gen.png")):
        packed(to_screen(Image.open(RAW / src).convert("RGB")).convert("RGBA"), aid, 64)
    from PIL import ImageDraw
    for aid, src in (("PIC_FOTO", "pic_foto_gen.png"), ("PIC_NICO", "pic_nico_gen.png"), ("PIC_NICO_OK", "pic_nico_ok_gen.png")):
        im = Image.open(RAW / src).convert("RGBA")
        lum = np.asarray(im.convert("L"))
        ys, xs = np.nonzero(lum > 70)  # the print, not the dark table
        im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        for corner in ((0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1)):
            ImageDraw.floodfill(im, corner, (0, 0, 0, 0), thresh=60)
        w = 270
        packed(im.resize((w, round(w * im.height / im.width)), Image.Resampling.BOX), aid, 48)
    # the film strips: cut out of their dark brown table by their distance from its colour
    for aid, src, w in (("PIC_NEG1", "pic_neg1_gen.png", 330), ("PIC_TIRA", "pic_tira_gen.png", 330)):
        im = Image.open(RAW / src).convert("RGBA")
        a = np.asarray(im.convert("RGB")).astype(int)
        bgc = a[4:20, 4:20].reshape(-1, 3).mean(axis=0)
        far = np.abs(a - bgc).sum(axis=2) > 70
        ys, xs = np.nonzero(far)
        im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        packed(im.resize((w, round(w * im.height / im.width)), Image.Resampling.BOX), aid, 64)


if __name__ == "__main__":
    for step in (sys.argv[1:] or ["street_rear", "floor", "side", "scene", "pics"]):
        globals()[step]()
