"""Cut native-size warehouse props from supplied two-state reference sheet."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).parent
SOURCE = ROOT / "raw" / "props_native_reference.png"
OUT = ROOT / "art"
BOXES = {
    "PRESS": ((35, 55, 183, 229), (35, 268, 183, 456)),
    "ROLLER": ((194, 55, 357, 229), (194, 267, 357, 457)),
    "SHUTTER": ((368, 66, 525, 229), (368, 285, 525, 457)),
    "BOX": ((538, 96, 671, 229), (527, 322, 671, 457)),
    "CAMERA": ((682, 85, 803, 229), (682, 293, 803, 457)),
    "LIGHT": ((811, 65, 930, 229), (811, 266, 930, 457)),
    "REC": ((948, 67, 1071, 229), (948, 268, 1071, 457)),
    "EXIT": ((1205, 65, 1362, 229), (1205, 282, 1362, 457)),
}
CLIPS = ((1085, 67, 1200, 161), (1085, 174, 1200, 268), (1085, 305, 1200, 403))


def cut(image, box):
    cell = image.crop(box).convert("RGBA")
    px = cell.load()
    for y in range(cell.height):
        for x in range(cell.width):
            r, g, b, _ = px[x, y]
            if max(abs(r - 24), abs(g - 24), abs(b - 24)) < 5:
                px[x, y] = (0, 0, 0, 0)
    bounds = cell.getbbox()
    return cell.crop(bounds) if bounds else cell


def strip(images):
    width = max(image.width for image in images)
    height = max(image.height for image in images)
    result = Image.new("RGBA", (width * len(images), height))
    for index, image in enumerate(images):
        result.alpha_composite(image, (index * width + (width - image.width) // 2, height - image.height))
    return result, (width, height)


def build():
    image = Image.open(SOURCE)
    OUT.mkdir(exist_ok=True)
    preview = Image.new("RGBA", (960, 440), (24, 24, 24, 255))
    entries = []
    for index, (name, boxes) in enumerate(BOXES.items()):
        pictures = [cut(image, box) for box in boxes]
        atlas, size = strip(pictures)
        atlas.save(OUT / f"{name.lower()}_native.png")
        preview.alpha_composite(pictures[0], (index % 4 * 240 + 20, index // 4 * 215 + 20))
        entries.append((name, size))
    clips, clip_size = strip([cut(image, box) for box in CLIPS])
    clips.save(OUT / "clips_native.png")
    print(entries, ("CLIPS", clip_size))
    preview.save(OUT / "props_native_preview.png")


if __name__ == "__main__":
    build()
