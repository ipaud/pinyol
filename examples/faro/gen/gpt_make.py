"""raw/ (the image model's pictures) -> art/ (the pieces at the game's size), for what tools/build_art.py's list cannot say by itself: the props cut out of
their row, the three platform strips cut into a left end, a middle that repeats and a right end, the tentacle and the textures that quads draw at 128x128
or less, the octopus's four faces on one baseline, and the painted rooms at 480 wide. Then `uv run tools/build_art.py examples/faro` packs art.json.

    uv run --with numpy --with scipy python3 gen/gpt_make.py && uv run tools/build_art.py examples/faro
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
GAME = HERE.parent
RAW, ART = GAME / "raw", GAME / "art"


def solid(im: Image.Image, cut: int = 128) -> Image.Image:
    """Transparency is all or nothing in the engine: the glow round a generated sprite goes."""
    a = np.array(im.convert("RGBA"))
    a[..., 3] = np.where(a[..., 3] >= cut, 255, 0)
    return Image.fromarray(a)


def blobs_x(im: Image.Image, gap: int = 8) -> list[tuple[int, int]]:
    """The runs of columns that hold something, split at empty gaps."""
    a = np.array(im.getchannel("A")) >= 128
    cols = a.sum(0) > 2
    runs, start = [], None
    for x, on in enumerate(list(cols) + [False]):
        if on and start is None:
            start = x
        if not on and start is not None:
            runs.append((start, x))
            start = None
    merged = []
    for r in runs:
        if merged and r[0] - merged[-1][1] < gap:
            merged[-1] = (merged[-1][0], r[1])
        else:
            merged.append(r)
    return [r for r in merged if r[1] - r[0] > 20]


def blobs_y(im: Image.Image) -> list[tuple[int, int]]:
    a = np.array(im.getchannel("A")) >= 128
    rows = a.sum(1) > 20
    runs, start = [], None
    for y, on in enumerate(list(rows) + [False]):
        if on and start is None:
            start = y
        if not on and start is not None:
            runs.append((start, y))
            start = None
    return [r for r in runs if r[1] - r[0] > 20]


def crop_alpha(im: Image.Image) -> Image.Image:
    return im.crop(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox())


def fit_box(im: Image.Image, w: int, h: int) -> Image.Image:
    k = min(w / im.width, h / im.height)
    return im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)


def props() -> None:
    src = solid(Image.open(RAW / "props.png"))
    names = ["gear", "lens", "burner", "oilcan", "barrel"]
    sizes = {"gear": (128, 128), "lens": (128, 128), "burner": (56, 56), "oilcan": (28, 28), "barrel": (72, 48)}
    for name, (x0, x1) in zip(names, blobs_x(src)):
        piece = crop_alpha(solid(fit_box(crop_alpha(src.crop((x0, 0, x1, src.height))), *sizes[name])))
        if name in ("gear", "lens"):  # a quad's texture: square, the picture in the middle
            sq = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
            sq.paste(piece, ((128 - piece.width) // 2, (128 - piece.height) // 2))
            piece = sq
        piece.save(ART / f"{name}.png")


def planks() -> None:
    """Each strip at 20 pixels of top and its underside: a left end, a middle of 64 that repeats, a right end."""
    src = solid(Image.open(RAW / "planks.png"))
    for name, (y0, y1) in zip(["wood", "stone", "iron"], blobs_y(src)):
        strip = crop_alpha(src.crop((0, y0, src.width, y1)))
        k = 30 / strip.height
        strip = solid(strip.resize((round(strip.width * k), 30), Image.LANCZOS))
        w = strip.width
        strip.crop((0, 0, 16, 30)).save(ART / f"plank_{name}_l.png")
        strip.crop((w // 2 - 32, 0, w // 2 + 32, 30)).save(ART / f"plank_{name}_m.png")
        strip.crop((w - 16, 0, w, 30)).save(ART / f"plank_{name}_r.png")


def tentacle() -> None:
    t = solid(fit_box(crop_alpha(solid(Image.open(RAW / "tentacle.png"))), 48, 128))
    out = Image.new("RGBA", (48, 128), (0, 0, 0, 0))
    out.paste(t, ((48 - t.width) // 2, 128 - t.height))
    out.save(ART / "tentacle.png")


def pop() -> None:
    """Four faces of the octopus, each scaled to the same width and standing on the cell's bottom row (its mantle rises from below the windows)."""
    src = solid(Image.open(RAW / "pop.png"))
    W, H = 288, 260
    frames = []
    runs = blobs_x(src, gap=8)[:4]
    widths = [x1 - x0 for x0, x1 in runs]
    k = (W - 8) / max(widths)
    for x0, x1 in runs:
        f = crop_alpha(src.crop((x0, 0, x1, src.height)))
        f = solid(f.resize((round(f.width * k), round(f.height * k)), Image.LANCZOS))
        cell = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        cell.paste(f, ((W - f.width) // 2, H - f.height), f)
        frames.append(cell)
    strip = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * W, 0))
    strip.save(ART / "pop.png")


def room(name: str, size: tuple[int, int], out: str) -> None:
    p = RAW / f"{name}.png"
    if not p.exists():
        print("missing", p.name)
        return
    im = Image.open(p).convert("RGB")
    w, h = size
    k = max(w / im.width, h / im.height)
    im = im.resize((max(w, round(im.width * k)), max(h, round(im.height * k))), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    im.crop((x, y, x + w, y + h)).save(ART / f"{out}.png")


def rain() -> None:
    """The rain's two streaks, drawn by code: a thin far one and a longer near one."""
    for name, (w, h, c) in {"rain_far": (1, 9, (120, 150, 200)), "rain_near": (2, 16, (170, 200, 240))}.items():
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        for y in range(h):
            k = 0.45 + 0.55 * y / (h - 1)
            for x in range(w):
                im.putpixel((x, y), (int(c[0] * k), int(c[1] * k), int(c[2] * k), 255))
        im.save(ART / f"{name}.png")


# the character sheets, fitted by tools/sprite_kit.py (each sheet's own scale from its upright first frame, soles on row 142, feet in column 64), as strips in art/
SHEETS = {
    "estel_walk": {"split": 5, "frame": [128, 144], "height": 88},
    "estel_lift": {"split": 5, "frame": [128, 144], "height": 108},
    "estel_moves": {"split": 5, "frame": [128, 144], "height": 88},
    "anima": {"split": 5, "frame": [112, 112], "height": 92, "flying": True},
}


def sheets() -> None:
    import sys
    sys.path.insert(0, str(GAME.parents[1] / "tools"))
    from build_art import frames_of  # noqa: E402
    for name, e in SHEETS.items():
        frames = frames_of(GAME, {"src": f"raw/{name}.png", "fit": "feet", "scale_frame": 0, **e})
        w, h = frames[0].size
        strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
        for i, f in enumerate(frames):
            strip.paste(f, (i * w, 0))
        strip.save(ART / f"{name}.png")


def main() -> None:
    ART.mkdir(exist_ok=True)
    sheets()
    props()
    planks()
    tentacle()
    pop()
    rain()
    for name in ("bg_f1", "bg_f2", "bg_f3", "bg_f4", "bg_lamp"):
        room(name, (480, 720), name)
    for name in ("title", "ending"):
        room(name, (480, 320), name)
    print("art/:", ", ".join(sorted(p.name for p in ART.glob("*.png"))))


if __name__ == "__main__":
    main()
