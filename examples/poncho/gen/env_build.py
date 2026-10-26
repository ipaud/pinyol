"""Packs art/env/*.png (gen/env_make.py) into assets/ and writes data/deco.lua (what the game's core/deco.lua reads: size, anchor, frames of each picture) and the slices of the
wide layers (FAR, CASE) with data/far_slices.lua, data/case_slices.lua.   python3 gen/env_build.py"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from build import lua  # noqa: E402

ROOT = HERE.parents[2]
GAME = HERE.parent
ENV = GAME / "art" / "env"
ASSETS = GAME / "assets"
PIECE_BYTES = 80_000


def run(*a) -> None:
    subprocess.run([sys.executable, *map(str, a)], check=True, stdout=subprocess.DEVNULL)


def main() -> None:
    ASSETS.mkdir(exist_ok=True)
    (GAME / "data").mkdir(exist_ok=True)
    for old in list(ASSETS.glob("BG_*")) + list(ASSETS.glob("TOY_*")) + list(ASSETS.glob("FAR_*")) + list(ASSETS.glob("CASE_*")) + list(ASSETS.glob("UI_*")):
        old.unlink()
    out, total = {}, 0
    for js in sorted(p for p in ENV.glob("*.json") if p.stem != "UI_LOGO"):   # (UI_LOGO: the old one-language logo, replaced by UI_LOGO_ES/CA/EN)
        m = json.loads(js.read_text())
        name, n = js.stem, len(m["frames"])
        run(ROOT / "tools/png2asset.py", js.with_suffix(".png"), ASSETS, name, "--packed", "--type", "background", "--colours", 32, "--frames", n, "--anchor", f"{m['anchor'][0]},{m['anchor'][1]}")
        size = (ASSETS / f"{name}.pk").stat().st_size
        per = max(1, min(10, PIECE_BYTES // max(1, size // n)))
        pieces = size > PIECE_BYTES and n > 1
        if pieces:
            run(ROOT / "tools/pk_split.py", ASSETS / f"{name}.pk", "--frames", per, "--remove")
        total += size
        out[name] = {"w": m["w"], "h": m["h"], "ax": m["anchor"][0], "ay": m["anchor"][1], "n": n, "pieces": pieces, "per": per,
                     "frames": {f: i for i, f in enumerate(m["frames"])}}
    (GAME / "data" / "deco.lua").write_text("-- made by gen/env_build.py from art/env/: size, anchor and frames of every picture\nreturn " + lua(out) + "\n")
    wide = {}
    for png, name in (("far", "FAR"), ("case", "CASE")):
        run(ROOT / "tools/slice_pic.py", ENV / f"{png}.png", GAME, name, "--width", 160, "--lua", GAME / "data" / f"{png}_slices.lua", "--colours", 32)
        wide[name] = sum(p.stat().st_size for p in ASSETS.glob(f"{name}_*.pk"))
    print(f"{len(out)} pictures, {total} bytes; wide layers {wide}")


if __name__ == "__main__":
    main()
