"""Runs gen/gpt_jobs.py through the codex bridge: raw pictures in raw/ (ignored by git), nothing asked twice, a job whose reference is missing waits.

    python3 gen/gpt_run.py --plan        what would be asked
    python3 gen/gpt_run.py [--only X]    ask what is missing (wave 1, then wave 2, which takes wave 1's pictures as references)
    python3 gen/gpt_run.py --redo NAME   ask one again (the old one goes to raw/old/)
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gpt_jobs as J  # noqa: E402

RAW = HERE.parent / "raw"
BRIDGE = Path.home() / ".claude/skills/gpt-image-bridge/bin/gpt-image-2"


def done(name: str) -> bool:
    p = RAW / f"{name}.png"
    return p.exists() and p.stat().st_size > 10_000


def ask(item: tuple[str, tuple]) -> bool:
    name, (size, ref, prompt) = item
    if done(name):
        return True
    cmd = [str(BRIDGE), prompt, str(RAW / f"{name}.png")]
    if size:
        cmd += ["--size", size]
    if ref:
        cmd += ["--ref", str(RAW / f"{ref}.png")]
    for _ in range(2):
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=1500)
        if done(name):
            print("ok", name, flush=True)
            return True
        print("FAILED", name, r.stderr[-300:], flush=True)
        time.sleep(5)
    return False


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plan", action="store_true")
    ap.add_argument("--only", nargs="+")
    ap.add_argument("--redo", nargs="+")
    ap.add_argument("--workers", type=int, default=6)
    a = ap.parse_args()
    RAW.mkdir(exist_ok=True)
    for name in a.redo or []:
        p = RAW / f"{name}.png"
        if p.exists():
            (RAW / "old").mkdir(exist_ok=True)
            p.rename(RAW / "old" / f"{int(time.time())}_{name}.png")
    allj = {**J.JOBS, **J.JOBS2}
    pick = lambda d: {k: v for k, v in d.items() if not done(k) and (not a.only or any(t in k for t in a.only))}  # noqa: E731
    if a.plan:
        for k, (_, ref, _) in pick(allj).items():
            print("ask", k, "(ref " + ref + ")" if ref else "")
        return
    bad = 0
    with ThreadPoolExecutor(a.workers) as ex:
        for wave in (J.JOBS, J.JOBS2):
            todo = [(k, v) for k, v in pick(wave).items() if not v[1] or done(v[1])]
            bad += sum(not ok for ok in ex.map(ask, todo))
            # sheets of the first wave whose reference was made in it
            late = [(k, v) for k, v in pick(wave).items() if v[1] and done(v[1])]
            bad += sum(not ok for ok in ex.map(ask, late))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
