"""Fit generated PSX art and convert it to Piñol packed picture assets."""
from pathlib import Path
import subprocess
import sys

from PIL import Image

HERE = Path(__file__).resolve().parent
CONVERT = HERE.parents[1] / "tools" / "png2asset.py"
RAW, ART, ASSETS = (HERE / name for name in ("raw", "art", "assets"))


def solid(image):
    image = image.convert("RGBA")
    image.putalpha(image.getchannel("A").point(lambda value: 255 if value >= 128 else 0))
    return image


def fitted(image, frame_size, body_height):
    image = solid(image)
    image = image.crop(image.getchannel("A").getbbox())
    width = round(image.width * body_height / image.height)
    image = solid(image.resize((width, body_height), Image.Resampling.NEAREST))
    frame = Image.new("RGBA", frame_size)
    frame.alpha_composite(image, ((frame_size[0] - width) // 2, frame_size[1] - body_height - 2))
    return frame


def convert(filename, asset_id, *options):
    subprocess.run(
        [sys.executable, str(CONVERT), str(ART / filename), str(ASSETS), asset_id, "--packed", *options],
        check=True,
    )


def main():
    ART.mkdir(exist_ok=True)
    ASSETS.mkdir(exist_ok=True)

    Image.open(RAW / "digestion-bg.png").convert("RGB").resize(
        (480, 320), Image.Resampling.LANCZOS
    ).save(ART / "digestion-bg.png")
    convert("digestion-bg.png", "BG_DIGESTION", "--type", "background")

    for name, size, height in (("yuri", (72, 100), 90), ("stanley", (64, 108), 98)):
        fitted(Image.open(RAW / f"{name}.png"), size, height).save(ART / f"{name}.png")
        convert(f"{name}.png", f"SPR_{name.upper()}")

    source = Image.open(RAW / "objects.png")
    frame_size = (54, 46)
    strip = Image.new("RGBA", (frame_size[0] * 3, frame_size[1]))
    for index in range(3):
        left = index * source.width // 3
        right = (index + 1) * source.width // 3
        strip.alpha_composite(fitted(source.crop((left, 0, right, source.height)), frame_size, 37),
                              (index * frame_size[0], 0))
    strip.save(ART / "objects.png")
    convert("objects.png", "OBJ_ITEMS", "--frames", "3")


if __name__ == "__main__":
    main()
