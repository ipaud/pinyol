"""Runs gen/w4_jobs.py.   python3 gen/w4_run.py --plan | --only market_ref | --redo m_far_a.png"""
from __future__ import annotations

import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[2] / "tools"))
import w4_jobs as W  # noqa: E402
import sheet_jobs as SJ  # noqa: E402

SJ.BRIDGE = HERE / "bridge.sh"
GAME = HERE.parent
RAW = SJ.raw_dir(GAME)


def jobs() -> list:
    return [SJ.Job(p + size, RAW / f"{n}.png", GAME / ref) for n, (p, ref, size) in W.JOBS.items()]


if __name__ == "__main__":
    SJ.main(jobs(), int(os.environ.get("GPT_WORKERS", 4)))
