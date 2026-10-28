"""The quality gate: a game whose adapter says `-- playtest-gate: win` (or `survive`) in its first lines must be finished (or survived to the cap) by its perfect player.
A game that cannot be finished passes every other test as long as the tests teleport or set flags: four of the engine's examples were like that.
Every example (examples/<id>/main.lua) must have such an adapter, or be named in tests/playtest/without_adapter.txt (the ones made before the gate: the list only
shrinks). tools/new_game.py gives a new Lua game a working one. Run: python3 tests/playtest_gate.py [build dir]   (ctest runs it). Env PINYOL_HEADLESS names another pinyol_headless."""
import csv, os, re, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
build = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build"
env = dict(os.environ, PINYOL_HEADLESS=os.environ.get("PINYOL_HEADLESS") or str(build / "pinyol_headless"))
CAP = {"win": 54000, "survive": 12000}
GATE = re.compile(r"playtest-gate:\s*(win|survive)")
bad, ran = [], 0


def adapters():
    """(game folder, adapter) of every adapter: tests/playtest/<id>.lua for the engine's examples, <game>/tests/playtest.lua in a game."""
    for adapter in sorted((ROOT / "tests" / "playtest").glob("*.lua")):
        game = next((g for g in (ROOT / "examples" / adapter.stem, ROOT / "tests" / "games" / adapter.stem) if (g / "main.lua").exists()), None)
        yield game, adapter
    for adapter in sorted(ROOT.glob("examples/*/tests/playtest.lua")) + sorted(ROOT.glob("tests/games/*/tests/playtest.lua")):
        yield adapter.parent.parent, adapter


def gate_of(adapter):
    m = GATE.search("".join(adapter.read_text().splitlines(True)[:5]))
    return m.group(1) if m else None


gated = {g.name for g, a in adapters() if g and gate_of(a)}
exempt = {l.split("#")[0].strip() for l in (ROOT / "tests" / "playtest" / "without_adapter.txt").read_text().splitlines()} - {""}
for game in sorted(ROOT.glob("examples/*/main.lua")):
    name = game.parent.name
    if name not in gated and name not in exempt:
        bad.append(f"{name}: no playtest adapter marked `-- playtest-gate: win`. Add tests/playtest.lua (docs/playtest.md) and run tools/finish_game.py; "
                   f"a game is not finished until a perfect player can finish it")
    if name in gated and name in exempt:
        bad.append(f"{name}: has an adapter now, take it out of tests/playtest/without_adapter.txt")
for adapter_game, adapter in adapters():
    want = gate_of(adapter)
    if not want:
        continue
    game = adapter_game
    if not game:
        bad.append(f"{adapter.name}: no game {adapter.stem}")
        continue
    with tempfile.TemporaryDirectory() as out:
        r = subprocess.run([sys.executable, str(ROOT / "tools" / "playtest.py"), str(game), "--perfect", "1", "--imperfect", "0", "--cap", str(CAP[want]), "--flash-every", "0", "--out", out],
                           cwd=ROOT, env=env, capture_output=True, text=True)
        rows = list(csv.DictReader(open(Path(out, "results.csv")))) if Path(out, "results.csv").exists() else []
        outcome = rows[0]["outcome"] if rows else "no result"
        if not rows:
            print(r.stdout + r.stderr)
    ok = outcome == "win" if want == "win" else outcome in ("win", "timeout")
    ran += 1
    print(f"{game.name}: perfect player {outcome} (wanted {want}) {'ok' if ok else 'FAIL'}")
    if not ok:
        bad.append(f"{game.name}: the perfect player ended with {outcome}, wanted {want}")
if bad:
    sys.exit("playtest gate failed:\n  " + "\n  ".join(bad))
print(f"playtest gate ok ({ran} games)")
