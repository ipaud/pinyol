"""Lua source and file reads accept exactly 1 MiB and reject larger inputs."""
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

LIMIT = 1 << 20
HEADLESS = Path(sys.argv[1])
SANDBOX = Path(__file__).parent / "games" / "sandbox"


def padded(source: str, size: int = LIMIT) -> bytes:
    prefix = source.encode()
    assert len(prefix) <= size
    remaining = size - len(prefix)
    return prefix + b"--x\n" * (remaining // 4) + b" " * (remaining % 4)


with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    serial = [0]

    def game(main: str, *, splash: str | None = None, files: dict[str, bytes] | None = None) -> tuple[Path, Path]:
        serial[0] += 1
        path = root / f"game-{serial[0]}"
        shutil.copytree(SANDBOX, path, ignore=shutil.ignore_patterns("saves"))
        manifest = json.loads((path / "game.json").read_text())
        manifest["lua_memory_kb"] = 4096
        if splash:
            manifest["splash"] = "splash.lua"
            (path / "splash.lua").write_bytes(padded(splash))
        (path / "game.json").write_text(json.dumps(manifest))
        (path / "main.lua").write_text(main)
        for name, data in (files or {}).items():
            target = path / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        return path, root / f"saves-{serial[0]}"

    def run(path: Path, saves: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([str(HEADLESS), "--game", str(path), "--saves", str(saves), "--fresh", *args],
                              capture_output=True, text=True)

    def expect_ok(result: subprocess.CompletedProcess[str]) -> None:
        assert result.returncode == 0, result.stdout + result.stderr

    def expect_limit_error(result: subprocess.CompletedProcess[str], message: str) -> None:
        output = result.stdout + result.stderr
        assert result.returncode != 0 and result.returncode >= 0 and message in output, output

    main_ok, saves = game("", files={"main.lua": padded("function _init() end\nfunction _draw() end\n")})
    expect_ok(run(main_ok, saves, "--validate"))
    main_big, saves = game("", files={"main.lua": padded("function _init() end\nfunction _draw() end\n") + b" "})
    expect_limit_error(run(main_big, saves, "--validate"), "cannot read it (missing or over 1024 KB)")

    module_main = "local m = require('large')\nassert(m.value)\nfunction _init() end\nfunction _draw() end\n"
    module_src = padded("return {value = true}\n")
    module_ok, saves = game(module_main, files={"large.lua": module_src})
    expect_ok(run(module_ok, saves, "--validate"))
    module_big, saves = game(module_main, files={"large.lua": module_src + b" "})
    expect_limit_error(run(module_big, saves, "--validate"), "cannot read large.lua (missing or over 1024 KB)")

    splash_main = "function _init() end\nfunction _draw() end\n"
    splash_src = "return {update=function() return true end, draw=function() end}\n"
    splash_ok, saves = game(splash_main, splash=splash_src)
    expect_ok(run(splash_ok, saves, "--validate"))
    splash_big, saves = game(splash_main, splash=splash_src)
    (splash_big / "splash.lua").write_bytes(padded(splash_src) + b" ")
    expect_limit_error(run(splash_big, saves, "--validate"), "splash.lua: cannot read it (missing or over 1024 KB)")

    file_main = "assert(#file('exact.bin') == 1048576)\nfunction _init() end\nfunction _draw() end\n"
    file_ok, saves = game(file_main, files={"exact.bin": b"x" * LIMIT})
    expect_ok(run(file_ok, saves, "--validate"))
    file_main = "local ok, err = pcall(file, 'large.bin')\nassert(not ok and string.find(err, 'bigger than 1024 KB'))\nfunction _init() end\nfunction _draw() end\n"
    file_big, saves = game(file_main, files={"large.bin": b"x" * (LIMIT + 1)})
    expect_ok(run(file_big, saves, "--validate"))

    hot_main = "mod = require('mod')\nfunction _init() end\nfunction _draw() end\n"
    hot_base = {"mod.lua": b"return {value = true}\n"}
    hot_exact, saves = game(hot_main, files={**hot_base, "replacement.lua": padded("return {value = 2}\n")})
    script = root / "hotswap.script"
    script.write_text("new\nhotswap replacement.lua mod\nexpect_ok\n")
    expect_ok(run(hot_exact, saves, "--script", str(script)))
    hot_big, saves = game(hot_main, files={**hot_base, "replacement.lua": padded("return {value = 2}\n") + b" "})
    result = run(hot_big, saves, "--script", str(script))
    expect_limit_error(result, "cannot read replacement.lua (missing or over 1024 KB)")

print("lua file limits: ok")
