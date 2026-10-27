"""Checks art/env: no frame of a strip touches its cell's edge (nothing cut) and every picture has some pixels; prints a table of flags (empty = good). Also writes raw/seams.png:
the far wall's joint and its loop, shifted by half, the floor repeated, to look at the seams.   python3 gen/env_verify.py"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

G = Path(__file__).resolve().parent.parent
import os
ENV = G / "art" / os.environ.get("ENVDIR", "env")
flags, n = [], 0
for js in sorted(ENV.glob("*.json")):
    m = json.loads(js.read_text())
    a = np.asarray(Image.open(js.with_suffix(".png")).convert("RGBA"))
    w, h = m["w"], m["h"]
    for i, name in enumerate(m["frames"]):
        c = a[:, i * w:(i + 1) * w, 3] > 0
        n += 1
        if not c.any():
            flags.append((js.stem, name, "empty"))
            continue
        ys, xs = np.where(c)
        solid_edge = js.stem.startswith(("BG_TILES", "FT_", "CT_", "BG_FLOOR", "BG_BODY", "BG_SHELF", "BG_TBOX", "TOY_HUD", "TOY_HEARTS"))
        if len(m["frames"]) > 1 and not solid_edge and (ys.min() == 0 or xs.min() == 0 or ys.max() == h - 1 or xs.max() == w - 1):
            flags.append((js.stem, name, "touches the cell edge"))
print(f"{n} frames checked, {len(flags)} flagged")
for f in flags:
    print("  %-22s %-14s %s" % f)
far = np.asarray(Image.open(ENV / (next(n for n in ("far.png", "FM_FAR.png", "CM_FAR.png") if (ENV / n).exists()))).convert("RGB"))
half = np.roll(far, far.shape[1] // 2, axis=1)
floor = np.asarray(Image.open(ENV / (next(n for n in ("BG_FLOOR8.png", "FT_FLOOR8.png", "CT_FLOOR8.png") if (ENV / n).exists()))).convert("RGB"))
rows = [far[:, :480], half[:, :480], np.concatenate([floor, floor], axis=1)[:, :480]]
rows = [np.pad(r, ((0, 0), (0, 480 - r.shape[1]), (0, 0))) for r in rows]
Image.fromarray(np.concatenate(rows, axis=0)).save(G / "raw" / "seams.png")
loopjoin = np.concatenate([far[:, -240:], far[:, :240]], axis=1)
Image.fromarray(loopjoin).save(G / "raw" / "seams_loop.png")
sys.exit(1 if flags else 0)
