"""The desktop app's install (platform/sdl/desktop.c) on what people may drop on its window: a game zipped either way,
paths that climb out or start at the root, links, odd names, the console's menu, a file that is no zip, a game
installed again over its saves. In a folder with accents, as a player's may be.

    python3 tests/desktop_test.py build/desktop_test
"""
import struct
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

GAME = '{"id": "x", "title": "X", "engine": "pinyol@2"}'


def install(games: Path, *zips: Path) -> list[str]:
    out = subprocess.run([sys.argv[1], str(games), *map(str, zips)], capture_output=True, text=True, check=True,
                         encoding="utf-8")
    return out.stdout.split()


def zipped(path: Path, files: dict, links: dict | None = None) -> Path:
    with zipfile.ZipFile(path, "w") as z:
        for name, text in files.items():
            z.writestr(name, text)
        for name, target in (links or {}).items():  # a Unix link, as a zip made on a Mac or Linux can hold
            info = zipfile.ZipInfo(name)
            info.create_system, info.external_attr = 3, 0o120777 << 16
            z.writestr(info, target)
    return path


with tempfile.TemporaryDirectory() as t:
    t = Path(t) / "Jocs d'Àvila"
    games = t / "games"
    games.mkdir(parents=True)
    top = zipped(t / "suelto.zip", {"game.json": GAME, "main.lua": "-- 1"})
    folder = zipped(t / "descarga (1).zip", {"naves/game.json": GAME, "naves/main.lua": "-- 1"})
    odd = zipped(t / "..zip", {"game.json": GAME})
    spaced = zipped(t / "mi juego (2).zip", {"game.json": GAME})
    assert install(games, top, folder, odd, spaced) == ["suelto", "naves", "_", "mi_juego__2_"]
    assert (games / "suelto/main.lua").read_text() == "-- 1" and (games / "naves/game.json").exists()
    legacy = zipped(t / "legacy.zip", {"game.json": GAME, "cafe.txt": "ok"})
    raw = legacy.read_bytes().replace(b"cafe.txt", b"caf\x82.txt")
    legacy.write_bytes(raw)
    assert install(games, legacy) == ["legacy"] and (games / "legacy/café.txt").read_text() == "ok"

    evil = zipped(t / "evil.zip", {"juego/game.json": GAME, "../../escape.lua": "x", str(t / "abs.lua"): "x"})
    assert install(games, evil) == ["-"]
    assert not (t / "escape.lua").exists() and not (t.parent / "escape.lua").exists() and not (t / "abs.lua").exists()
    for i, name in enumerate(("folder/.. /escape", "NUL.txt", "COM¹.txt", "LPT³", "CONIN$", "deep/" * 65 + "game.json")):
        invalid = zipped(t / f"invalid-{i}.zip", {"game.json": GAME, name: "x"})
        assert install(games, invalid) == ["-"]

    victim = t / "victim"
    victim.mkdir()
    (victim / "keep.txt").write_text("mine")
    linked = zipped(t / "link.zip", {"g/game.json": GAME}, {"g/docs": str(victim), "g/note": str(victim / "keep.txt")})
    assert install(games, linked, linked) == ["-", "-"]
    assert (victim / "keep.txt").read_text() == "mine" and not (games / "g").exists()

    link = games / "linked"
    try:
        link.symlink_to(victim, target_is_directory=True)
    except (OSError, NotImplementedError):  # Windows may run without symlink privileges
        pass
    else:
        linked_destination = zipped(t / "linked-destination.zip", {"linked/game.json": GAME, "linked/new.txt": "x"})
        assert install(games, linked_destination) == ["-"]
        assert not (victim / "new.txt").exists()
        link.unlink()

    menu = zipped(t / "menu.zip", {"Cirera/game.json": GAME})
    nozip = t / "nozip.zip"
    nozip.write_text("hola")
    empty = zipped(t / "empty.zip", {"readme.txt": "no game"})
    assert install(games, menu, nozip, empty) == ["-", "-", "-"]
    assert not (games / "Cirera").exists()

    too_many = t / "too_many.zip"
    with zipfile.ZipFile(too_many, "w") as z:
        for i in range(4001):
            z.writestr(f"empty/{i}", "")
    too_big = t / "too_big.zip"
    with zipfile.ZipFile(too_big, "w", compression=zipfile.ZIP_STORED) as z:
        z.writestr("game.json", GAME)
    raw = bytearray(too_big.read_bytes())
    eocd = raw.rfind(b"PK\x05\x06")
    central = struct.unpack_from("<I", raw, eocd + 16)[0]
    struct.pack_into("<I", raw, central + 24, (96 << 20) + 1)  # exceeds cumulative unpack limit
    too_big.write_bytes(raw)
    assert install(games, too_many, too_big) == ["-", "-"]
    assert not (games / ".instalando").exists()

    bomb = t / "bomb.zip"
    with zipfile.ZipFile(bomb, "w", compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr("bomb/game.json", GAME)
        z.writestr("bomb/large.bin", "x" * (4 << 20))
    raw = bytearray(bomb.read_bytes())
    eocd = raw.rfind(b"PK\x05\x06")
    central, count = struct.unpack_from("<IH", raw, eocd + 16)[0], struct.unpack_from("<H", raw, eocd + 10)[0]
    pos = central
    for _ in range(count):
        name_len, extra_len, comment_len = struct.unpack_from("<HHH", raw, pos + 28)
        name = raw[pos + 46:pos + 46 + name_len].decode()
        local = struct.unpack_from("<I", raw, pos + 42)[0]
        if name == "bomb/large.bin":
            struct.pack_into("<I", raw, pos + 24, 1)
            struct.pack_into("<I", raw, local + 22, 1)
        pos += 46 + name_len + extra_len + comment_len
    bomb.write_bytes(raw)
    assert install(games, bomb) == ["-"]
    assert not (games / "bomb").exists() and not (games / ".instalando").exists()

    (games / "naves/saves").mkdir()
    (games / "naves/saves/slot0.sav").write_text("partida")
    (games / "naves/.local-config").write_text("mine")
    again = zipped(t / "naves.zip", {"naves/game.json": GAME, "naves/main.lua": "-- 2", "naves/saves/slot0.sav": "suya"})
    assert install(games, again) == ["naves"]
    assert (games / "naves/main.lua").read_text() == "-- 2" and (games / "naves/saves/slot0.sav").read_text() == "partida"
    assert (games / "naves/.local-config").read_text() == "mine"
    partial = games / "partial"
    (partial / "clash").mkdir(parents=True)
    (partial / "main.lua").write_text("old")
    broken_update = zipped(t / "partial.zip", {"partial/game.json": GAME, "partial/main.lua": "new",
                                                "partial/clash": "cannot replace directory"})
    assert install(games, broken_update) == ["-"]
    assert (partial / "main.lua").read_text() == "old" and (partial / "clash").is_dir()
    assert sorted(p.name for p in games.iterdir()) == ["_", "legacy", "mi_juego__2_", "naves", "partial", "suelto"]
print("desktop install: ok")
