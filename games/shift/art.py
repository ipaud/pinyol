# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10.1"]
# ///
"""Build SHIFT's era skins using Pinyol's packed-image pipeline.

    uv run games/shift/art.py
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ART, ASSETS = HERE / "art", HERE / "assets"
SOURCE = ART / "nodi_eras_source.png"
PIXEL = Image.Resampling.NEAREST
PALETTES = {
    "8": [(17, 24, 32), (215, 71, 60), (241, 148, 118), (242, 232, 206)],
    "GB": [(37, 60, 52), (80, 110, 80), (138, 166, 107), (233, 233, 193)],
}


def remap_luma(image: Image.Image, colours: list[tuple[int, int, int]],
               thresholds: tuple[int, int, int]) -> Image.Image:
    out = Image.new("RGBA", image.size)
    src, dst = image.convert("RGBA").load(), out.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = src[x, y]
            level = (r * 299 + g * 587 + b * 114) // 1000
            index = sum(level >= edge for edge in thresholds)
            dst[x, y] = (*colours[index], a)
    return out


def background(source: Path, output: Path, palette: list[tuple[int, int, int]] | None = None,
               thresholds: tuple[int, int, int] = (120, 180, 230)) -> None:
    image = Image.open(source).convert("RGBA").resize((512, 320), PIXEL)
    (remap_luma(image, palette, thresholds) if palette else image).save(output)


def nodi_frames() -> None:
    sheet = Image.open(SOURCE).convert("RGBA")
    w, h = sheet.size
    for col, era in enumerate(("8", "GB", "16", "ARCADE")):
        strip = Image.new("RGBA", (128, 32))
        for pose in range(4):
            x0, x1 = round(col * w / 4), round((col + 1) * w / 4)
            y0, y1 = round(pose * h / 4), round((pose + 1) * h / 4)
            cell = sheet.crop((x0, y0, x1, y1))
            bounds = cell.getchannel("A").getbbox()
            if not bounds:
                raise ValueError(f"empty NODI frame: era={era}, pose={pose}")
            sprite = cell.crop(bounds)
            target_h = 30
            target_w = min(28, max(1, round(sprite.width * target_h / sprite.height)))
            sprite = sprite.resize((target_w, target_h), PIXEL)
            frame = Image.new("RGBA", (32, 32))
            frame.alpha_composite(sprite, ((32 - target_w) // 2, 2))
            if era in PALETTES:
                frame = remap_luma(frame, PALETTES[era], (72, 142, 205))
            strip.alpha_composite(frame, (pose * 32, 0))
        strip.save(ART / f"nodi_{era.lower()}.png")


def convert(png: Path, asset_id: str, *, frames: int = 1, colours: int = 64,
            kind: str = "background", anchor: str | None = None) -> None:
    command = [sys.executable, str(ROOT / "tools" / "png2asset.py"), str(png), str(ASSETS), asset_id,
               "--packed", "--colours", str(colours), "--type", kind]
    if frames > 1:
        command += ["--frames", str(frames)]
    if anchor:
        command += ["--anchor", anchor]
    subprocess.run(command, check=True)


def main() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    ASSETS.mkdir(parents=True, exist_ok=True)
    demos = ROOT / "examples"
    mountain = demos / "plataformas" / "art" / "mountains.png"
    hills = demos / "plataformas" / "art" / "hills.png"
    for era, palette in (("8", PALETTES["8"]), ("GB", PALETTES["GB"]), ("16", None)):
        for layer, source in (("far", mountain), ("near", hills)):
            png = ART / f"{era.lower()}_{layer}.png"
            thresholds = (120, 180, 230) if layer == "far" else (80, 100, 125)
            background(source, png, palette, thresholds)
            convert(png, f"BG_{era}_{layer.upper()}", colours=4 if era in ("8", "GB") else 64)
    city = demos / "calle" / "art" / "street.png"
    convert(city, "BG_ARCADE", colours=128)
    nodi_frames()
    for era, colours in (("8", 4), ("GB", 4), ("16", 16), ("ARCADE", 16)):
        convert(ART / f"nodi_{era.lower()}.png", f"NODI_{era}", frames=4, colours=colours,
                kind="sprite", anchor="16,31")


if __name__ == "__main__":
    main()
