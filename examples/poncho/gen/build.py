"""Packs art/ into assets/SPR_<NAME>.pk (tools/png2asset.py --packed --colours 16), cuts sheets of more than 10 frames into pieces (tools/pk_split.py: a picture needs one block of memory
on the console) and writes data/sheets.lua (where each frame is), as Taller's gen/build.py does.

    python3 gen/build.py
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import contract as C  # noqa: E402

ROOT = HERE.parents[2]
GAME = HERE.parent
PIECE_BYTES = 80_000


def lua(v, indent=0) -> str:
    pad = "  " * indent
    if isinstance(v, dict):
        items = [f'{pad}  [{json.dumps(str(k))}] = {lua(x, indent + 1)}' for k, x in v.items()]
        return "{\n" + ",\n".join(items) + f"\n{pad}}}"
    if isinstance(v, (list, tuple)):
        return "{" + ", ".join(lua(x) for x in v) + "}"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        return json.dumps(v)
    return str(v)


def run(*args) -> None:
    subprocess.run([sys.executable, *map(str, args)], check=True, stdout=subprocess.DEVNULL)


def main() -> None:
    art, assets, data = GAME / "art", GAME / "assets", GAME / "data"
    assets.mkdir(exist_ok=True)
    data.mkdir(exist_ok=True)
    sheets, total = {}, 0
    for name in C.SHEETS:
        meta = json.loads((art / f"{name}.json").read_text())
        n = len(meta["frames"])
        sid = "SPR_" + name.upper()
        run(ROOT / "tools/png2asset.py", art / f"{name}.png", assets, sid, "--packed", "--colours", 32, "--frames", n, "--anchor", f"{meta['anchor'][0]},{meta['anchor'][1]}")
        size = (assets / f"{sid}.pk").stat().st_size
        per = max(1, min(10, PIECE_BYTES // max(1, size // n)))
        pieces = n > per
        if pieces:
            run(ROOT / "tools/pk_split.py", assets / f"{sid}.pk", "--frames", per, "--remove")
        total += size
        sheets[name] = {"id": sid, "w": meta["w"], "h": meta["h"], "ax": meta["anchor"][0], "ay": meta["anchor"][1], "n": n, "pieces": pieces, "per": per,
                        "frames": {f: i for i, f in enumerate(meta["frames"])}}
        print(f"  {sid}: {n} frames {meta['w']}x{meta['h']}, {size} bytes packed, pieces of {per}" if pieces else f"  {sid}: {n} frames {meta['w']}x{meta['h']}, {size} bytes packed")
    (data / "sheets.lua").write_text("-- made by gen/build.py from art/: where each picture is\nreturn " + lua({"sheets": sheets}) + "\n")
    print(f"{len(sheets)} sheets, {total} bytes packed in all")


if __name__ == "__main__":
    main()
