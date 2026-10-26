"""Packs art/w2/*.png (gen/w2_make.py) into assets/ (FM_*, FT_*, FE_*, FI_*, BOSS_*) and writes data/deco2.lua (the same format as data/deco.lua) and the slices of the far layer
(data/fm_far_slices.lua).   python3 gen/w2_build.py"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from build import lua  # noqa: E402
from env_build import run, ROOT, GAME, ASSETS, PIECE_BYTES  # noqa: E402

ART = GAME / "art" / "w2"
PREFIX = ("FM_", "FT_", "FE_", "FI_", "BOSS_")


def main() -> None:
    for old in list(ASSETS.glob("*.pk")) + list(ASSETS.glob("*.json")):
        if old.name.startswith(PREFIX):
            old.unlink()
    out, total, big = {}, 0, {}
    for js in sorted(ART.glob("*.json")):
        m = json.loads(js.read_text())
        name, n = js.stem, len(m["frames"])
        run(ROOT / "tools/png2asset.py", js.with_suffix(".png"), ASSETS, name, "--packed", "--type", "background", "--colours", 32, "--frames", n, "--anchor", f"{m['anchor'][0]},{m['anchor'][1]}")
        size = (ASSETS / f"{name}.pk").stat().st_size
        per = max(1, min(10, PIECE_BYTES // max(1, size // n)))
        pieces = size > PIECE_BYTES and n > 1
        if pieces:
            run(ROOT / "tools/pk_split.py", ASSETS / f"{name}.pk", "--frames", per, "--remove")
        total += size
        out[name] = {"w": m["w"], "h": m["h"], "ax": m["anchor"][0], "ay": m["anchor"][1], "n": n, "pieces": pieces, "per": per, "frames": {f: i for i, f in enumerate(m["frames"])}}
    (GAME / "data" / "deco2.lua").write_text("-- made by gen/w2_build.py from art/w2/: size, anchor and frames of every world-2 / boss picture (same format as data/deco.lua)\nreturn " + lua(out) + "\n")
    run(ROOT / "tools/slice_pic.py", ART / "FM_FAR.png", GAME, "FM_FAR", "--width", 160, "--lua", GAME / "data" / "fm_far_slices.lua", "--colours", 32)
    far = sum(p.stat().st_size for p in ASSETS.glob("FM_FAR_*.pk"))
    print(f"{len(out)} pictures, {total} bytes; far layer {far} bytes; total {total + far}")


if __name__ == "__main__":
    main()
