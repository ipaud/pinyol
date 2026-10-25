"""The sheets the game gets from art/: name -> frame names (the cell size is found by gpt_make and read from art/<name>.json). gen/build.py packs them as SPR_<NAME>."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gpt_jobs as _J  # noqa: E402

SHEETS = {cid: [f for sh in c["sheets"] for f in sh[3]] for cid, c in _J.CHARS.items()}
