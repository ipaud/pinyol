#!/usr/bin/env python3
"""Compares the hitbox of every foe and boss (core/foes.lua SIZE, core/boss.lua SPEC) with the opaque bounding box of its art (the median over the frames that show it
standing or moving), and flags a hitbox more than 20% bigger or smaller than the visible body, in width or height.

    python3 examples/poncho/gen/hitbox_check.py [--fix]       # --fix prints the sizes to put in the tables (90% of the body: a fair box)
Exit 1 when something is flagged."""
import json, re, statistics, sys
from pathlib import Path
from PIL import Image

G = Path(__file__).resolve().parent.parent
ART = [G / "art" / d for d in ("env", "w2", "w3", "w4")]

# kind -> (art id, frame prefixes that show it standing / moving, scale it is drawn at)
FOES = {
    "car": ("TOY_CAR", ("",), 1), "robot": ("TOY_ROBOT", ("",), 1), "ball": ("TOY_BALL", ("",), 1), "plane": ("TOY_PLANE", ("",), 1),
    "apple": ("FE_APPLE", ("walk",), 1), "banana": ("FE_BANANA", ("slide",), 1), "bee": ("FE_BEE", ("fly",), 1), "cherry": ("FE_CHERRY", ("bounce",), 1),
    "pigeon": ("CE_PIGEON", ("walk",), 1), "snail": ("CE_SNAIL", ("slide",), 1),
    "note": ("KE_NOTE", ("hop",), 1), "cable": ("KE_CABLE", ("slide",), 1), "speaker": ("KE_SPEAKER", ("pulse",), 1), "bubble": ("KE_BUBBLE", ("float",), 1),
    "melon": ("BOSS_SANDIA", ("roll",), 0.4),
}
BOSSES = {"cuerda": ("BOSS_CUERDA", ("idle",), 1), "sandia": ("BOSS_SANDIA", ("idle",), 1), "silencio": ("BOSS_SILENCIO", ("idle",), 1), "paloma": ("CE_PIGEON", ("walk",), 2)}


def find(art):
    for d in ART:
        if (d / f"{art}.json").exists():
            return d
    return None


def body(art, prefixes, scale):
    d = find(art)
    if not d:
        return None
    meta = json.loads((d / f"{art}.json").read_text())
    im = Image.open(d / f"{art}.png").convert("RGBA")
    ws, hs = [], []
    for i, name in enumerate(meta["frames"]):
        if not any(name.startswith(p) for p in prefixes):
            continue
        fr = im.crop((i * meta["w"], 0, (i + 1) * meta["w"], meta["h"]))
        bb = fr.getchannel("A").point(lambda a: 255 if a > 127 else 0).getbbox()
        if bb:
            ws.append(bb[2] - bb[0])
            hs.append(bb[3] - bb[1])
    if not ws:
        return None
    return statistics.median(ws) * scale, statistics.median(hs) * scale


def table(path, name, pat):
    src = (G / "core" / path).read_text()
    block = src[src.index(name):]
    block = block[: block.index("}\n")] if name.startswith("local SIZE") else block[: block.index("\n}\n")]
    return {m.group(1): (int(m.group(2)), int(m.group(3))) for m in re.finditer(pat, block)}


def main():
    sizes = table("foes.lua", "local SIZE", r"(\w+) = \{(\d+), (\d+)\}")
    spec = table("boss.lua", "local SPEC", r"(\w+) = \{w = (\d+), h = (\d+)")
    bad = 0
    for label, hit, art in [("foe", sizes, FOES), ("boss", spec, BOSSES)]:
        for kind, (w, h) in sorted(hit.items()):
            if kind not in art:
                print(f"?    {label} {kind}: no art entry")
                continue
            b = body(*art[kind])
            if not b:
                print(f"-    {label} {kind}: art not found")
                continue
            rw, rh = w / b[0], h / b[1]
            flag = not (0.8 <= rw <= 1.2 and 0.8 <= rh <= 1.2)
            bad += flag
            print(f"{'FLAG' if flag else 'ok  '} {label:4} {kind:9} hitbox {w:3}x{h:3}  body {b[0]:5.0f}x{b[1]:5.0f}  ratio {rw:.2f} x {rh:.2f}   (90%: {round(b[0] * .9)}, {round(b[1] * .9)})")
    sys.exit(1 if bad else 0)


main()
