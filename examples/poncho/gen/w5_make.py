"""POLISH round art: raw sheets (gen/w5_jobs.py) -> new assets in art/w3, art/w2, art/env, art/w4 and the costume jump frames appended to art/poncho_<outfit>.png/.json.
    python3 gen/w5_make.py [group ...]     groups: w3 w2 w4 costumes"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import env_make as E  # noqa: E402
import gpt_make as M  # noqa: E402
import w2_make as W2  # noqa: E402

GAME = HERE.parent
RAW = E.RAW


def to(world: str) -> None:
    E.ART = GAME / "art" / world
    E.ART.mkdir(parents=True, exist_ok=True)


def w3() -> None:
    to("w3")
    ob = E.objects("x3_a", 8)
    pal = E.pal_from(E.opaque_px("x3_a", False))
    hop = [E.fit_to(o, pal, 36, "h") for o in ob[:2]]
    # both hopscotch boards at the same scale (96 px wide): one cell for the pair
    k = 96 / ob[0].shape[1]
    hop = [E.tight(E.shrink(o, pal, k)) for o in ob[:2]]
    cells, anchor = E.place(hop, [E.feet_anchor(h) for h in hop])
    E.save("CT_HOP", cells, anchor, ["normal", "cracked"])
    ramp = E.shrink_to(E.tight(ob[2]), pal, 64, 32)
    a, b = ramp[:, :32], ramp[:, 32:]
    E.save("CT_RAMP_RB", [a, b, b[:, ::-1].copy(), a[:, ::-1].copy()], (0, 0), ["a", "b", "c", "d"])
    k = 60 / ob[3].shape[1]
    pf = [E.tight(E.shrink(o, pal, k)) for o in ob[3:6]]
    cells, anchor = E.place(pf, [E.feet_anchor(p) for p in pf])
    E.save("CI_PUDDLE", cells, anchor, ["calm", "ripple_0", "ripple_1"])
    k = 110 / ob[6].shape[1]
    sf = [E.tight(E.shrink(o, pal, k)) for o in ob[6:8]]
    cells, anchor = E.place(sf, [E.feet_anchor(p) for p in sf])
    E.save("CI_SEESAW", cells, anchor, ["left_down", "right_down"])
    f, a_, _ = E.anim_frames("x3_peck", 4, 0, k=_pigeon_k())
    cells, anchor = E.place(f, a_)
    E.save("CE_PIGEON_PECK", cells, anchor, [f"peck_{i}" for i in range(4)])


def _pigeon_k() -> float:
    """The peck sheet's scale: its standing frame as tall as the walking pigeon's (56 px)."""
    return 56 / E.objects("x3_peck", 4)[0].shape[0]


def w2() -> None:
    to("w2")
    A = E.objects("x2_melon_a", 10)
    B = E.objects("x2_melon_b", 10)
    pal = E.pal_from(np.concatenate([E.opaque_px("x2_melon_a", False), E.opaque_px("x2_melon_b", False)]), E.NCOL, halo=False)
    k = 50 / A[0].shape[0]
    fa = [E.tight(E.shrink(o, pal, k)) for o in A]
    fb = [E.tight(E.shrink(o, pal, k)) for o in B[:6]]
    fa = [np.asarray(M.clean(Image.fromarray(x), x.shape[1])) for x in fa]
    fb = [np.asarray(M.clean(Image.fromarray(x), x.shape[1])) for x in fb]
    E.strip("FE_MELON", [(fa[:8], [E.feet_anchor(x) for x in fa[:8]], [f"walk_{i}" for i in range(8)]), (fb, [E.feet_anchor(x) for x in fb], [f"roll_{i}" for i in range(6)]),
                         (fa[8:], [E.feet_anchor(x) for x in fa[8:]], ["hurt_0", "def_0"])])
    peel = [E.fit_to(B[6], pal, 26, "h"), E.fit_to(B[7], pal, 26, "h")]
    cells, anchor = E.place(peel, [E.feet_anchor(p) for p in peel])
    E.save("FI_PEEL", cells, anchor, ["peel", "peel_shine"])
    taut, press = E.fit_to(B[8], pal, 64, "w"), None
    k = taut.shape[1] / E.tight(B[8]).shape[1]
    press = E.tight(E.shrink(B[9], pal, k))
    mid_h = (taut.shape[0] + press.shape[0]) // 2
    mid = E.shrink_to(E.tight(B[8]), pal, taut.shape[1], mid_h)
    mid = np.asarray(M.clean(Image.fromarray(mid), mid.shape[1]))
    fr = [taut, mid, press]
    cells, anchor = E.place(fr, [E.feet_anchor(x) for x in fr])
    E.save("FT_PAD", cells, anchor, ["taut", "press", "squash"])
    to("env")
    E.save("TOY_PAD", cells, anchor, ["taut", "press", "squash"])


def w4() -> None:
    to("w4")
    ob = E.objects("x4_a", 7)
    pal = E.pal_from(E.opaque_px("x4_a", False))
    cur = Image.open(GAME / "art/w4/KT_FLOORCOL.png").convert("RGBA")
    base = np.asarray(cur)
    body = base[32:96]
    black = E.shrink_to(E.tight(ob[0]), pal, 32, 32)
    pressed = E.shrink_to(E.tight(ob[1]), pal, 32, 32)
    top = np.zeros((32, 32, 4), np.uint8)
    cols = [np.concatenate([black, body], axis=0), np.concatenate([pressed, body], axis=0)]
    E.save("KT_FLOORKEY", cols, (0, 0), ["blackkey", "pressed"])
    lights = E.fit_to(ob[2], pal, 180, "w")
    E.single("KM_LIGHTS", lights, "top")
    fl = [E.fit_to(o, pal, 150) for o in ob[3:7]]
    cells, anchor = E.place(fl, [E.feet_anchor(f) for f in fl])
    cols_ = np.where(np.stack(cells)[..., 3].any(axis=(0, 1)))[0]
    x0, x1 = int(max(0, cols_.min() - 2)), int(min(cells[0].shape[1], cols_.max() + 3))
    E.save("KI_FLAG", [c[:, x0:x1] for c in cells], (int(anchor[0] - x0), int(anchor[1])), [f"wave_{i}" for i in range(4)])
    bp = E.pal_from(E.opaque_px("x4_burst", False))
    from sprite_kit import split_frames
    bo = [np.asarray(f) for f in split_frames(E.loadkeyed("x4_burst"), 4)]   # an effect is many separate specks: cut by the sheet's gaps, nothing dropped
    k = 120 / max(max(o.shape[:2]) for o in bo)
    bf = [E.tight(E.shrink(o, bp, k)) for o in bo]
    cells, anchor = E.place(bf, [(b.shape[1] // 2, b.shape[0] // 2) for b in bf])
    E.save("FX_BURST", cells, anchor, [f"burst_{i}" for i in range(4)])


HEIGHT = {"dino": 82, "barretina": 84, "boots": 80, "futbol": 80}


def costumes() -> None:
    for x, hgt in HEIGHT.items():
        js = GAME / "art" / f"poncho_{x}.json"
        m = json.loads(js.read_text())
        names = ["jump_0", "jump_1", "fall_0"]
        if all(n in m["frames"] for n in names):
            print(f"  poncho_{x}: jump frames already there")
            continue
        strip = np.array(Image.open(GAME / "art" / f"poncho_{x}.png").convert("RGBA"))
        w, h = m["w"], m["h"]
        used = strip[strip[..., 3] > 0][:, :3]
        pal = np.unique(used, axis=0)
        grid, boxes = M.regrid(Image.open(RAW / f"x5_j_{x}.png"), 3)
        idx, mask = M.flat_palette(grid, pal)
        # the scale: the three frames' mean height is about the standing height
        mean_h = np.mean([b[3] - b[1] for b in boxes])
        k = hgt / (mean_h / 0.99)
        tw, th = max(1, round(grid.width * k)), max(1, round(grid.height * k))
        art = M.vote(idx, mask, np.linspace(0, grid.width, tw + 1).astype(int), np.linspace(0, grid.height, th + 1).astype(int), pal)
        cw = grid.width // 3
        new = []
        for i in range(3):
            sub = art[:, int(i * cw * k):int((i + 1) * cw * k)]
            ys, xs = np.where(sub[..., 3] > 0)
            f = sub[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
            f = np.asarray(M.clean(Image.fromarray(f), f.shape[1]))
            ax, ay = E.feet_anchor(f)
            cell = np.zeros((h, w, 4), np.uint8)
            x0, y0 = m["anchor"][0] - ax, m["anchor"][1] - ay
            if x0 < 0 or y0 < 0 or x0 + f.shape[1] > w or y0 + f.shape[0] > h:
                print(f"  poncho_{x} {names[i]}: does not fit its cell ({f.shape[1]}x{f.shape[0]} at {x0},{y0} in {w}x{h}): clipped")
            xa, ya = max(0, x0), max(0, y0)
            sub_f = f[ya - y0:ya - y0 + (h - ya), xa - x0:xa - x0 + (w - xa)]
            cell[ya:ya + sub_f.shape[0], xa:xa + sub_f.shape[1]] = sub_f[:h - ya, :w - xa]
            new.append(cell)
        Image.fromarray(np.concatenate([strip] + new, axis=1)).save(GAME / "art" / f"poncho_{x}.png")
        m["frames"] += names
        js.write_text(json.dumps(m))
        print(f"  poncho_{x}: +3 frames -> {len(m['frames'])}, k={k:.3f}")


GROUPS = {"w3": w3, "w2": w2, "w4": w4, "costumes": costumes}

if __name__ == "__main__":
    for g in sys.argv[1:] or list(GROUPS):
        print(g)
        GROUPS[g]()
