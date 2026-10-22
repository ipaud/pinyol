"""Checks every built actor and prop strip (art/built_*.png) and draws a contact sheet to look at.

    python3 games/ocho_mananas_v1/art/qa_sprites.py [ID ...]      -> art/qa/<ID>.png and a report; exit 1 on a failure

Failures: a frame with pixels on the edge of its cell (cut), a standing frame whose feet are off the baseline
(it would hop), a standing frame whose height strays from the asset's standing height (the scale would breathe).
Warnings: a frame whose body is far off the cell's middle, a frame with far more or less ink than its neighbours.
"""
import json
import sys
from pathlib import Path

import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
SIZES = json.loads((HERE / "sizes.json").read_text())
OUT = HERE / "qa"
OUT.mkdir(exist_ok=True)


def check(aid):
    z = SIZES[aid]
    strip = Image.open(HERE / f"built_{aid}.png").convert("RGBA")
    cw, ch, base, ref = z["w"], z["h"], z["foot"], z["ref"]
    n = strip.width // cw
    problems, warnings = [], []
    heights, areas = [], []
    frames = []
    for i in range(n):
        a = np.asarray(strip.crop((i * cw, 0, (i + 1) * cw, ch)).getchannel("A")) > 0
        ys, xs = np.nonzero(a)
        frames.append(a)
        heights.append(ys.max() - ys.min() + 1)
        areas.append(a.sum())
    tallest = max(heights)
    for i, a in enumerate(frames):
        ys, xs = np.nonzero(a)
        upright = heights[i] >= 0.7 * tallest
        if xs.min() <= 0 or xs.max() >= cw - 1 or ys.min() <= 0 or ys.max() >= ch - 1:
            problems.append(f"frame {i}: touches the edge of its cell (cut)")
        cum = np.cumsum(a.sum(axis=1)) / a.sum()
        foot = int(np.searchsorted(cum, 0.997))
        if upright and abs(foot - base) > 1:
            problems.append(f"frame {i}: feet at row {foot}, baseline {base} (hops)")
        if upright and not 0.78 * ref <= heights[i] <= 1.12 * ref:
            problems.append(f"frame {i}: {heights[i]} px tall against {ref} (scale)")
        lab, k = ndimage.label(a, structure=np.ones((3, 3)))
        if k > 1:
            sizes = ndimage.sum(a, lab, range(1, k + 1))
            main = int(np.argmax(sizes)) + 1
            away = ndimage.distance_transform_edt(lab != main)
            for j in range(1, k + 1):
                if j != main and sizes[j - 1] < 0.15 * sizes[main - 1] and away[lab == j].min() > 6:
                    problems.append(f"frame {i}: a floating fragment of {int(sizes[j - 1])} px (a stray)")
        cx = np.median(xs)
        if abs(cx - cw / 2) > 0.18 * cw:
            warnings.append(f"frame {i}: body {cx - cw / 2:+.0f} px off the middle")
    med = float(np.median(areas))
    for i, ar in enumerate(areas):
        if upright_ok(heights[i], tallest) and not 0.45 <= ar / med <= 2.2:
            warnings.append(f"frame {i}: ink {ar / med:.2f}x the median")
    # contact sheet: baseline, middle and the cell's edge
    cols = min(n, 10)
    rows = (n + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * (cw + 4), rows * (ch + 4)), (64, 78, 98, 255))
    d = ImageDraw.Draw(sheet)
    for i in range(n):
        x, y = (i % cols) * (cw + 4), (i // cols) * (ch + 4)
        sheet.alpha_composite(strip.crop((i * cw, 0, (i + 1) * cw, ch)), (x, y))
        d.rectangle((x, y, x + cw - 1, y + ch - 1), outline=(255, 255, 255, 90))
        d.line((x, y + base, x + cw - 1, y + base), fill=(0, 255, 255, 200))
        d.line((x + cw // 2, y, x + cw // 2, y + ch - 1), fill=(0, 255, 0, 120))
    sheet.convert("RGB").save(OUT / f"{aid}.png")
    return problems, warnings


def upright_ok(h, tallest):
    return h >= 0.7 * tallest


if __name__ == "__main__":
    failed = False
    for aid in sys.argv[1:] or sorted(SIZES):
        problems, warnings = check(aid)
        print(f"{aid}: {'FAIL' if problems else 'ok'}" + (f" ({len(warnings)} warnings)" if warnings else ""))
        for p in problems:
            print("   !", p)
        for w in warnings:
            print("   ~", w)
        failed |= bool(problems)
    sys.exit(1 if failed else 0)
