# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Traca's letters: the arcade_80s pack (tools/font2fnt.py --pack), each font at one pixel a font pixel, because Traca
draws them on its 160x240 standing canvas, which the screen shows twice as big (the pack's own fonts are made at two
pixels a font pixel, for the 480x320 screen: on the canvas they would be twice too big).

    uv run examples/traca/gen/fonts.py
"""
from __future__ import annotations

import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(GAME.parents[1] / "tools"))
import font2fnt  # noqa: E402

cat = font2fnt.catalog()
for role in font2fnt.ROLES:
    path, o = font2fnt.role_font(cat, cat["packs"]["arcade_80s"]["roles"][role])
    out = GAME / "fonts" / f"arcade_80s_{role}.fnt"
    font2fnt.build(path, str(out), o["px"], 1, o["weight"], o["spacing"], None, 32, o["axes"])
    print("made", out.name)
