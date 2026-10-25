#!/usr/bin/env python3
"""Photographs the playroom's decorations (core/deco.lua) into packed picture assets: assets/BG_*.pk and TOY_*.pk.

Each frame of each picture is painted once by the game's own code on a plain green ground (the headless player's `shot`), cropped, keyed out and
put in a strip, and tools/png2asset.py --packed makes the asset. Run from the worktree root, by hand, after changing core/deco.lua or core/tilepaint.lua:

    python3 examples/poncho/decogen/build.py [--headless PATH]
"""
import argparse, re, subprocess, sys, tempfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "examples" / "poncho"
SPECS = GAME / "core" / "deco.lua"


def specs():
    """(id, w, h, ax, ay, n) read from the `def(...)` lines of core/deco.lua."""
    out = []
    for m in re.finditer(r'^def\("(\w+)", (\d+), (\d+), (\d+), (\d+), ([\w.]+),', SPECS.read_text(), re.M):
        i, w, h, ax, ay, n = m.groups()
        out.append((i, int(w), int(h), int(ax), int(ay), 12 if n == "TP.N" else int(n)))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--headless", default="/Users/pauavila/Desktop/DEV/pinyol/pinyol-engine/ramas/np2d-showcase/build/pinyol_headless")
    a = ap.parse_args()
    sp = specs()
    lines = ["new", "tick 5"]
    for i, w, h, ax, ay, n in sp:
        for f in range(n):
            lines += [f'lua D.deco("{i}", {f})', "tick 1", f"shot dz_{i}_{f}"]
    script = Path(tempfile.mkdtemp()) / "deco.script"
    script.write_text("\n".join(lines) + "\n")
    saves = GAME / "saves"
    subprocess.run([a.headless, "--game", str(GAME), "--fresh", "--script", str(script)], check=True, stdout=subprocess.DEVNULL)
    for i, w, h, ax, ay, n in sp:
        strip = Image.new("RGBA", (w * n, h), (0, 0, 0, 0))
        for f in range(n):
            im = Image.open(saves / f"dz_{i}_{f}.ppm").convert("RGBA").crop((8, 8, 8 + w, 8 + h))
            px = im.load()
            for y in range(h):
                for x in range(w):
                    r, g, b, _ = px[x, y]
                    if r < 14 and g > 240 and b < 14:
                        px[x, y] = (0, 0, 0, 0)
            strip.paste(im, (f * w, 0))
        png = Path(tempfile.mkdtemp()) / f"{i}.png"
        strip.save(png)
        subprocess.run([sys.executable, str(ROOT / "tools" / "png2asset.py"), str(png), str(GAME / "assets"), i, "--frames", str(n), "--packed",
                        "--type", "background", "--colours", "64"], check=True, stdout=subprocess.DEVNULL)
        print(i, w, h, n)


if __name__ == "__main__":
    main()
