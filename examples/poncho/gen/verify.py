"""Cutting check: for every frame, the fitted frame's full bounding box (feet, hands, wheels, curls) against the raw blob's box scaled by the sheet's own factor. A frame that lost more than
1 px of height (the feet) or of width is flagged. Prints a table of the flags (empty = nothing cut) and exits 1 when there is one.   python3 gen/verify.py [id ...]"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gpt_make as M  # noqa: E402
import gpt_jobs as J  # noqa: E402

K, RAW, ART = M.K, M.RAW, M.ART
flags, total = [], 0
for cid in sys.argv[1:] or list(J.CHARS):
    spec = J.CHARS[cid]
    meta = json.loads((ART / f"{cid}.json").read_text())
    strip = np.asarray(Image.open(ART / f"{cid}.png").convert("RGBA"))
    w = meta["w"]
    for name, n, _, fnames, kf, _ in spec["sheets"]:
        raw = RAW / f"{cid}_{name}.png"
        if not raw.exists():
            continue
        grid, boxes = M.regrid(Image.open(raw), n)
        _, pieces = K.blobs(grid, n)
        k0 = kf if kf != "auto" else K.pick_upright(pieces)
        k = spec["height"] / max(1, pieces[k0]["mbottom"] - pieces[k0]["mtop"])
        for (bx0, by0, bx1, by1), fname in zip(boxes, fnames):
            exp_h, exp_w = (by1 - by0) * k, (bx1 - bx0) * k
            i = meta["frames"].index(fname)
            fa = strip[:, i * w:(i + 1) * w, 3] > 0
            fy, fx = np.where(fa)
            got_h, got_w = fy.max() - fy.min() + 1, fx.max() - fx.min() + 1
            edge = fy.max() >= meta["h"] - 1 or fy.min() == 0 or fx.min() == 0 or fx.max() >= w - 1
            total += 1
            if got_h < exp_h - 1.5 or got_w < exp_w - 2.0 or edge or fy.max() < meta["anchor"][1] - 1 and not fname.startswith(("jump", "fall", "hurt", "die")):
                flags.append((cid, fname, f"{exp_w:.1f}x{exp_h:.1f}", f"{got_w}x{got_h}", "touches cell edge" if edge else f"lost {max(0, exp_h - got_h):.1f}h {max(0, exp_w - got_w):.1f}w"))
print(f"{total} frames checked, {len(flags)} flagged")
for f in flags:
    print("  %-18s %-14s raw*k %-10s got %-9s %s" % f)
sys.exit(1 if flags else 0)
