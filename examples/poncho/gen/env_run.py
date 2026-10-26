"""Runs the jobs of gen/env_jobs.py with tools/sheet_jobs.py (raw pictures in raw/, nothing asked twice).   python3 gen/env_run.py --plan | [--only env_ref] | [--redo wall_a.png]"""
from __future__ import annotations

import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[2] / "tools"))
import env_jobs as E  # noqa: E402
import sheet_jobs as SJ  # noqa: E402

SJ.BRIDGE = HERE / "bridge.sh"
GAME = HERE.parent
RAW = SJ.raw_dir(GAME)


def jobs() -> list:
    out = []
    for name, (prompt, ref, size) in E.JOBS.items():
        out.append(SJ.Job(prompt + size, RAW / f"{name}.png", GAME / ref))
    return out


if __name__ == "__main__":
    SJ.main(jobs(), int(os.environ.get("GPT_WORKERS", 4)))
