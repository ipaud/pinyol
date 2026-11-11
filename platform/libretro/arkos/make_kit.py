# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""pinyol for ArkOS handhelds (R36S, RG351...): one zip whose contents go onto the card's EASYROMS partition as they
are (docs/arkos.md). It holds the arm64 core and its installer, Ports' "Instalar Pinyol" entry, the site's games as
.pinyol with their covers and a gamelist.xml, and pinyol's art for the themes these cards carry.

    python3 platform/libretro/arkos/make_kit.py pinyol_libretro-linux-arm64.zip    # -> dist/pinyol-arkos.zip
    python3 platform/libretro/arkos/make_kit.py build/pinyol_libretro.so -o kit.zip  # a core built here (arm64)

The games are the ones the site plays (site/page.py, example_ids); each goes in as tools/pack_game.py packs it.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import tempfile
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path[:0] = [str(ROOT / "tools"), str(ROOT / "site")]
import pack_game  # noqa: E402
import page  # noqa: E402

CORE_FILES = ("pinyol_libretro.so", "pinyol_libretro.info", "LICENSE", "THIRD_PARTY_NOTICES.md")
COVER_W, COVER_H = 240, 160  # cover.rgb565, as tools/cover.py makes it: RGB565 little endian


def card_name(title: str) -> str:
    """A title as a file name on the card (exFAT, FAT32): none of the characters they refuse."""
    return re.sub(r'\s*[\\/:*?"<>|]+\s*', " - ", title).strip(" .-")


def cover_png(rgb565: Path, out: Path) -> None:
    raw = rgb565.read_bytes()
    if len(raw) != COVER_W * COVER_H * 2:
        raise SystemExit(f"{rgb565}: {len(raw)} bytes, not a {COVER_W}x{COVER_H} cover")
    px = bytearray()
    for i in range(0, len(raw), 2):
        v = raw[i] | raw[i + 1] << 8
        px += bytes((((v >> 11) & 31) * 255 // 31, ((v >> 5) & 63) * 255 // 63, (v & 31) * 255 // 31))
    # twice as big, pixels kept whole: the size the menu shows a picture at
    Image.frombytes("RGB", (COVER_W, COVER_H), bytes(px)).resize((COVER_W * 2, COVER_H * 2), Image.NEAREST).save(out, optimize=True)


def core_files(core: Path, tmp: Path) -> dict[str, Path]:
    """The core and its companions, from the release's zip or a .so built here (the rest from the repository)."""
    if core.suffix == ".zip":
        with zipfile.ZipFile(core) as z:
            z.extractall(tmp)
        files = {n: tmp / n for n in CORE_FILES}
    else:
        files = {"pinyol_libretro.so": core, "pinyol_libretro.info": ROOT / "platform/libretro/pinyol_libretro.info",
                 "LICENSE": ROOT / "LICENSE", "THIRD_PARTY_NOTICES.md": ROOT / "THIRD_PARTY_NOTICES.md"}
    missing = [n for n, p in files.items() if not p.exists()]
    if missing:
        raise SystemExit(f"{core}: missing {missing}")
    head = files["pinyol_libretro.so"].read_bytes()[:20]
    if head[:4] != b"\x7fELF" or int.from_bytes(head[18:20], "little") != 183:  # EM_AARCH64
        raise SystemExit(f"{core}: not an arm64 Linux core (ArkOS's RetroArch is 64-bit ARM)")
    return files


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("core", type=Path, help="pinyol_libretro-linux-arm64.zip, or an arm64 pinyol_libretro.so")
    ap.add_argument("-o", "--out", type=Path, default=ROOT / "dist/pinyol-arkos.zip")
    a = ap.parse_args()
    with tempfile.TemporaryDirectory() as t:
        tmp = Path(t)
        core = core_files(a.core, tmp / "core")
        a.out.parent.mkdir(parents=True, exist_ok=True)
        part = a.out.with_suffix(".part")
        names, games = set(), []
        with zipfile.ZipFile(part, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for n, p in core.items():
                z.write(p, f"ports/pinyol/{n}")
            z.write(HERE / "install.sh", "ports/pinyol/install.sh")
            z.write(HERE / "Instalar Pinyol.sh", "ports/Instalar Pinyol.sh")
            for f in sorted((HERE / "themes").rglob("*")):
                if f.is_file() and not f.name.startswith("."):
                    z.write(f, f"ports/pinyol/themes/{f.relative_to(HERE / 'themes').as_posix()}")
            for gid in page.example_ids():
                folder = ROOT / "examples" / gid
                meta = json.loads((folder / "game.json").read_text(encoding="utf-8"))
                name = card_name(meta.get("title") or gid)
                if name.casefold() in names:  # (exFAT: one file for names that differ only in case)
                    name = f"{name} ({gid})"
                names.add(name.casefold())
                packed = pack_game.pack(folder, tmp / "packs", False)
                z.write(packed, f"pinyol/{name}.pinyol")
                cover = tmp / "covers" / f"{gid}.png"
                cover.parent.mkdir(exist_ok=True)
                cover_png(folder / "cover.rgb565", cover)
                z.write(cover, f"pinyol/images/{name}.png")
                games.append((name, meta))
            z.writestr("pinyol/gamelist.xml", gamelist(games))
        part.replace(a.out)
    print(f"{a.out}: {len(games)} games, {a.out.stat().st_size / 1e6:.1f} MB")


def gamelist(games: list[tuple[str, dict]]) -> str:
    """EmulationStation's list for the folder: each game's name, description, author and cover."""
    rows = ['<?xml version="1.0"?>', "<gameList>"]
    for name, meta in games:
        rows += ["\t<game>", f"\t\t<path>./{escape(name)}.pinyol</path>", f"\t\t<name>{escape(meta.get('title') or name)}</name>",
                 f"\t\t<desc>{escape(meta.get('description') or meta.get('subtitle') or '')}</desc>",
                 f"\t\t<image>./images/{escape(name)}.png</image>"]
        if meta.get("author"):
            rows.append(f"\t\t<developer>{escape(meta['author'])}</developer>")
        rows.append("\t</game>")
    return "\n".join(rows + ["</gameList>", ""])


if __name__ == "__main__":
    main()
