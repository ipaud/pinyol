"""Draw 64 Zebby animation frames directly at their final 64x64 resolution."""
from pathlib import Path

from PIL import Image, ImageDraw

FRAME = 64
ORANGE = "#ff4b0b"
SHADE = "#e83a05"
LIGHT = "#ff671d"
INK = "#111111"
WHITE = "#fffdf7"


def limb(draw, points, width=4):
    draw.line(points, fill=INK, width=width, joint="curve")
    draw.line(points, fill=WHITE, width=width - 2, joint="curve")


def hand(draw, x, y):
    draw.polygon(((x - 5, y), (x - 5, y - 6), (x - 3, y - 8),
                  (x - 1, y - 4), (x, y - 9), (x + 2, y - 9),
                  (x + 3, y - 4), (x + 5, y - 6), (x + 6, y - 4),
                  (x + 4, y), (x + 6, y + 2), (x + 3, y + 5),
                  (x - 3, y + 5), (x - 6, y + 2)), fill=WHITE, outline=INK)


def shoe(draw, x, y):
    draw.ellipse((x - 6, y - 4, x + 6, y + 2), fill=WHITE, outline=INK)


def face(draw, cx, top, expression):
    eye_y = top + 19
    if expression == "blink":
        draw.line((cx - 5, eye_y + 1, cx - 4, eye_y + 1), fill=INK)
        draw.line((cx + 4, eye_y + 1, cx + 5, eye_y + 1), fill=INK)
    elif expression == "hurt":
        draw.line((cx - 5, eye_y, cx - 3, eye_y + 2), fill=INK)
        draw.line((cx - 3, eye_y, cx - 5, eye_y + 2), fill=INK)
        draw.line((cx + 3, eye_y, cx + 5, eye_y + 2), fill=INK)
        draw.line((cx + 5, eye_y, cx + 3, eye_y + 2), fill=INK)
    else:
        draw.ellipse((cx - 5, eye_y, cx - 4, eye_y + 2), fill=INK)
        draw.ellipse((cx + 4, eye_y, cx + 5, eye_y + 2), fill=INK)
    draw.rectangle((cx, eye_y, cx + 1, eye_y + 5), fill=INK)
    mouth_y = top + 27
    if expression == "surprise":
        draw.ellipse((cx - 2, mouth_y, cx + 2, mouth_y + 4), fill=INK)
    elif expression in ("strain", "hurt"):
        draw.rectangle((cx - 4, mouth_y, cx + 4, mouth_y + 3), fill=INK)
        draw.line((cx - 3, mouth_y + 1, cx + 3, mouth_y + 1), fill=WHITE)
    elif expression == "neutral":
        draw.line((cx - 4, mouth_y + 2, cx + 4, mouth_y + 2), fill=INK)
    else:
        draw.line(((cx - 4, mouth_y), (cx - 2, mouth_y + 2), (cx, mouth_y + 3),
                   (cx + 2, mouth_y + 2), (cx + 4, mouth_y)), fill=INK, width=2)


def pose(kind, i):
    image = Image.new("RGBA", (FRAME, FRAME))
    draw = ImageDraw.Draw(image)
    bx, by, bw, bh = 10, 4, 20, 24
    left, right = (6, 19), (34, 19)
    feet = ((15, 37), (25, 37))
    expression = "smile"
    if kind in ("walk", "walk_alt"):
        phase = i if kind == "walk" else i * 6 // 8
        left = (5 + (phase % 3), 18 + phase % 2)
        right = (35 - (phase % 3), 17 + phase % 3)
        feet = (((12, 9, 13, 20, 24, 17)[phase], 37),
                ((28, 25, 22, 17, 12, 22)[phase], 37))
        by += i % 2
    elif kind == "run":
        bx, by, bw, bh = 9, 7 + i % 2, 21, 22
        left, right = (4, 19 + i % 3), (36, 20 - i % 3)
        feet = (((9, 6, 15, 22, 27, 22, 15, 7)[i], 37 - (i % 3 == 2) * 3),
                ((29, 33, 29, 20, 12, 8, 12, 23)[i], 37 - (i % 3 == 1) * 3))
        expression = "neutral"
    elif kind == "jump":
        by = (8, 5, 3, 2, 4, 7)[i]
        left, right = ((5, 27), (3, 13), (5, 9), (5, 11), (6, 26), (7, 30))[i], \
                      ((34, 27), (36, 12), (37, 8), (36, 11), (33, 24), (33, 30))[i]
        feet = (((15, 37), (14, 36), (15, 35), (14, 34), (15, 36), (15, 37))[i],
                ((25, 37), (25, 35), (25, 34), (26, 34), (25, 36), (25, 37))[i])
        expression = "surprise" if i in (2, 3) else "smile"
    elif kind == "push":
        bx, by, bw, bh = 7 + i % 2, 7, 21, 22
        left, right = (35 + i % 2, 19), (36 + i % 2, 23)
        feet = ((7 + i % 2, 37), (22 + i % 2, 37))
        expression = "strain"
    elif kind == "dash":
        bx, by, bw, bh = 10, 9 - i % 2, 22, 21
        left, right = (2, 17), (2 + i % 2, 26)
        feet = ((4 + i * 2, 37 - i % 2 * 3), (27 + i, 37))
        expression = "strain" if i < 5 else "smile"
    elif kind == "hit":
        bx, by = 10 + (i % 3), 5 + (i % 2)
        left, right = (3, 12 + i), (36, 16 + i)
        feet = ((13, 37), (29 - i % 3, 34))
        expression = "hurt" if i < 5 else "smile"
    elif kind in ("flatten", "recover"):
        step = i if kind == "flatten" else 5 - i
        bw = (20, 23, 26, 29, 32, 34)[step]
        bh = (24, 20, 17, 13, 10, 8)[step]
        bx, by = (FRAME - bw) // 2, 35 - bh
        left, right = (2, 33), (38, 33)
        feet = ((16, 38), (24, 38))
        expression = "neutral" if step >= 3 else "surprise" if step == 2 else "smile"
    elif kind == "idle":
        by += (0, 0, 1, 1, 0, 0)[i]
        expression = "blink" if i in (2, 3) else "smile"

    if kind in ("flatten", "recover"):
        bw = min(56, round(bw * 1.4) + 8)
        bh = max(12, round(bh * 1.4))
        bx, by = (FRAME - bw) // 2, 58 - bh
    else:
        bx, by = round(bx * 1.5) - 3, round(by * 1.5)
        bw, bh = round(bw * 1.5) + 10, round(bh * 1.5)
    left = (max(5, min(59, round(32 + (left[0] - 20) * 1.9))), min(54, round(left[1] * 1.5) + 4))
    right = (max(5, min(59, round(32 + (right[0] - 20) * 1.9))), min(54, round(right[1] * 1.5) + 4))
    feet = tuple((round(32 + (x - 20) * 1.5), min(60, round(y * 1.5) + 3)) for x, y in feet)
    left_hip, right_hip = bx + bw // 3, bx + 2 * bw // 3
    if kind in ("flatten", "recover") and bh < 13:
        for foot in feet:
            limb(draw, ((foot[0], by + bh - 1), (foot[0], foot[1] - 2)), 3)
            shoe(draw, *foot)
    else:
        for hip, foot in zip((left_hip, right_hip), feet):
            knee = ((hip + foot[0]) // 2, by + bh + 5)
            limb(draw, ((hip, by + bh - 3), knee, (foot[0], foot[1] - 2)))
            shoe(draw, *foot)
    limb(draw, ((bx + 2, by + bh // 2), (bx - 4, by + bh // 2 + 8), (left[0] + 2, left[1] - 2), left))
    limb(draw, ((bx + bw - 2, by + bh // 2), (bx + bw + 4, by + bh // 2 + 8), (right[0] - 2, right[1] - 2), right))
    draw.rounded_rectangle((bx, by, bx + bw - 1, by + bh - 1), radius=min(8, bh // 3), fill=ORANGE, outline=INK)
    if bh >= 25:
        draw.arc((bx + 1, by + 1, bx + bw - 3, by + bh - 2), 190, 270, fill=LIGHT)
        draw.arc((bx + 1, by + 1, bx + bw - 1, by + bh - 1), 5, 70, fill=SHADE)
    if bh >= 22:
        face(draw, bx + bw // 2, by, expression)
    else:
        cx = bx + bw // 2
        ey = by + max(2, bh // 3)
        draw.point((cx - 4, ey), fill=INK)
        draw.point((cx + 4, ey), fill=INK)
        draw.line((cx - 2, ey + 2, cx + 2, ey + 2), fill=INK)
    hand(draw, *left)
    hand(draw, *right)
    return image


def build():
    groups = (("idle", 6), ("walk", 6), ("jump", 6), ("push", 6),
              ("walk_alt", 8), ("run", 8), ("dash", 6), ("hit", 6),
              ("flatten", 6), ("recover", 6))
    frames = [pose(kind, i) for kind, count in groups for i in range(count)]
    assert len(frames) == 64
    atlas = Image.new("RGBA", (FRAME * len(frames), FRAME))
    preview = Image.new("RGBA", (FRAME * 8, FRAME * 8), (37, 49, 61, 255))
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, (index * FRAME, 0))
        preview.alpha_composite(frame, ((index % 8) * FRAME, (index // 8) * FRAME))
    out = Path(__file__).parent / "art"
    out.mkdir(exist_ok=True)
    atlas.save(out / "zebby_native.png")
    preview.save(out / "zebby_native_preview.png")


if __name__ == "__main__":
    build()
