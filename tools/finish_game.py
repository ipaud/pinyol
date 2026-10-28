#!/usr/bin/env python3
"""The last step of making a game: is it finished? Plays it 50 times as a perfect player and 50 as an imperfect one (tools/playtest.py) and says
PASS or FAIL. A game passes when it has an adapter marked `-- playtest-gate: win` (or `survive`), every perfect game ends as that says, none crashes,
no invariant or number breaks, and the same seed gives the same game.

    uv run tools/finish_game.py games/mygame
    uv run tools/finish_game.py games/mygame --perfect 10 --imperfect 10      # a quicker look while you work

The report is in ~/pinyol-playtests/<game>/report.md (docs/playtest.md). Exit status 0 = PASS, 1 = FAIL. Env PINYOL_HEADLESS names another pinyol_headless."""
from __future__ import annotations

import argparse
import csv
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
from playtest import adapter_for  # noqa: E402


def verdict(adapter: Path | None, rows: list[dict], report: str) -> list[str]:
    """What stops this game from being finished; empty = it is."""
    if not adapter:
        return ["no adapter: add tests/playtest.lua (docs/playtest.md); without a perfect player nothing proves the game can be finished"]
    m = re.search(r"playtest-gate:\s*(win|survive)", "".join(adapter.read_text().splitlines(True)[:5]))
    if not m:
        return [f"{adapter.name} has no `-- playtest-gate: win` (or `survive`) in its first lines: the gate would not keep it true"]
    want, bad = m.group(1), []
    perfect = [r for r in rows if r["mode"] == "perfect"]
    ok = ("win",) if want == "win" else ("win", "timeout")
    fails = [r for r in perfect if r["outcome"] not in ok]
    if not perfect:
        bad.append("no perfect games were played")
    if fails:
        ends = sorted({r["outcome"] for r in fails})
        bad.append(f"{len(fails)} of {len(perfect)} perfect games did not {'win' if want == 'win' else 'survive'} ({', '.join(ends)}; first: {fails[0]['id']} at {fails[0]['where']}): an unreachable part, or a perfect() that is not perfect")
    crashes = [r for r in rows if r["outcome"] == "crash"]
    if crashes:
        bad.append(f"{len(crashes)} games crashed (first: {crashes[0]['id']}: {crashes[0]['error'][:120]})")
    anomalies = sorted({a for r in rows for a in r["anomalies"].split(",") if a not in ("", "-")})
    if anomalies:
        bad.append("anomalies: " + ", ".join(anomalies[:6]))
    if "REPEATED GAMES DIFFERED" in report:
        bad.append("the same seed did not repeat the same game (not deterministic)")
    return bad


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("game")
    ap.add_argument("--perfect", type=int, default=50)
    ap.add_argument("--imperfect", type=int, default=50)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--out", help="output folder (default ~/pinyol-playtests/<game>)")
    a = ap.parse_args()
    game = Path(a.game).resolve()
    out = Path(a.out).expanduser() if a.out else Path.home() / "pinyol-playtests" / game.name
    cmd = [sys.executable, str(ROOT / "tools" / "playtest.py"), str(game), "--perfect", str(a.perfect), "--imperfect", str(a.imperfect),
           "--workers", str(a.workers), "--out", str(out)]
    if subprocess.run(cmd).returncode:
        sys.exit("FAIL: the playtest itself did not run (see above)")
    rows = list(csv.DictReader(open(out / "results.csv")))
    bad = verdict(adapter_for(game), rows, (out / "report.md").read_text())
    for line in (out / "report.md").read_text().splitlines()[:6]:
        print(line)
    if bad:
        print("\nFAIL: this game is not finished:\n  - " + "\n  - ".join(bad) + f"\nReport: {out}/report.md")
        sys.exit(1)
    print(f"\nPASS: {len([r for r in rows if r['mode'] == 'perfect'])} perfect games ended as the adapter says, no crash, no anomaly, deterministic. Report: {out}/report.md")


if __name__ == "__main__":
    main()
