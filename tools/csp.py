"""A Content-Security-Policy for the web player's page: only its own files, the wasm, and its inline scripts by hash.

    python3 tools/csp.py build-web/player.html    # CMake runs it after linking (the shells are platform/web/*.html)

Nothing from another site runs in the page; a game's zip may still come from any https address (?game=URL).
"""
import base64
import hashlib
import re
import sys
from pathlib import Path

POLICY = ("default-src 'self'; script-src 'self' 'wasm-unsafe-eval'{hashes}; style-src 'self' 'unsafe-inline'; "
          "img-src 'self' data: blob:; connect-src 'self' https:; font-src 'self'; object-src 'none'; "
          "base-uri 'self'; form-action 'none'")
META = '<meta http-equiv="Content-Security-Policy" content="{}">\n'


def with_csp(html: str) -> str:
    scripts = re.findall(r"<script>(.*?)</script>", html, re.S)  # the shell's own; Emscripten's comes as src=
    hashes = "".join(" 'sha256-" + base64.b64encode(hashlib.sha256(s.encode("utf-8")).digest()).decode() + "'" for s in scripts)
    html = re.sub(r'<meta http-equiv="Content-Security-Policy" content="[^"]*">\n', "", html)  # run again: the same
    out = html.replace("<title>", META.format(POLICY.format(hashes=hashes)) + "<title>", 1)
    assert out.count("Content-Security-Policy") == 1 and out.count("'sha256-") == len(scripts) > 0, "no title or no script"
    return out


if __name__ == "__main__":
    page = Path(sys.argv[1])
    page.write_bytes(with_csp(page.read_bytes().decode("utf-8")).encode("utf-8"))  # bytes: the hashes need the text as it is
