"""World 3 (the chalk park): raw sheets -> art/w3/<ID>.png + .json (CM_ far/mid/fore, CT_ tiles, CE_ foes, CI_ items), the same surgical pipeline as gen/w2_make.py.
    python3 gen/w3_make.py [group ...]     groups: far mid fore tiles enemies items"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import env_make as E  # noqa: E402
import w2_make as W2  # noqa: E402

GAME = HERE.parent
E.ART = GAME / "art" / "w3"
E.ART.mkdir(parents=True, exist_ok=True)
ART, NCOL, period = E.ART, E.NCOL, W2.period


def far() -> None:
    im = Image.open(E.RAW / "c_far.png").convert("RGB")
    im = im.crop((0, 0, im.width, int(im.height * 0.7)))     # sky, trees, railing and flower boxes: down to the foot of the railing; the pavement is the floor
    pal = E.pal_from(np.asarray(im).reshape(-1, 3)[::30], NCOL, halo=False)
    a = np.dstack([np.asarray(im), np.full((im.height, im.width), 255, np.uint8)])
    out = E.shrink(a, pal, 190 / im.height)
    far_ = E.loop_blend(out, 40)
    Image.fromarray(far_).save(ART / "CM_FAR.png")
    print("  CM_FAR:", far_.shape[1], "x", far_.shape[0], "bottom colour 0x%02X%02X%02X" % tuple(far_[-1, far_.shape[1] // 2, :3]))


MID = {"c_mid_a": [("SWINGS", 150, "feet"), ("SLIDE", 170, "feet"), ("BENCH", 70, "feet"), ("TREE", 220, "feet"), ("FOUNTAIN", 80, "feet")],
       "c_mid_b": [("LAMP", 190, "feet"), ("SANDBOX", 60, "feet"), ("SEESAW", 70, "feet"), ("CHALKSUN", 120, "feet"), ("CHALKHOUSE", 130, "feet"), ("CHALKBOW", 110, "feet")]}


def mid() -> None:
    pal = E.pal_from(np.concatenate([E.opaque_px(n, False) for n in MID]))
    for sheet, items in MID.items():
        for (name, size, anchor), o in zip(items, E.objects(sheet, len(items))):
            E.single(f"CM_{name}", E.fit_to(o, pal, size), anchor)


def fore() -> None:
    pal = E.pal_from(E.opaque_px("c_fore", False))
    for (name, size, by), o in zip((("CHALKBOX", 80, "w"), ("BALL", 66, "h"), ("HOOP", 90, "h"), ("SCOOTER", 100, "w"), ("BOTTLE", 70, "h"), ("LEAVES", 96, "w")), E.objects("c_fore", 6)):
        E.single(f"CM_FORE_{name}", E.fit_to(o, pal, size, by), "tl")


def tiles() -> None:
    slab = Image.open(E.RAW / "c_floor.png").convert("RGB")
    px = [np.asarray(slab).reshape(-1, 3)[::30]] + [E.opaque_px(n, False) for n in ("c_tiles_a", "c_tiles_b")]
    pal = E.pal_from(np.concatenate(px), NCOL, halo=True)
    sl = E.shrink_to(np.dstack([np.asarray(slab), np.full((slab.height, slab.width), 255, np.uint8)]), pal, round(slab.width * 104 / slab.height), 104)[7:]   # (the slab's top 7 rows are sky above the kerb)
    col = period(sl, 32, 40)
    top, b1, b2 = col[0:32], col[32:64], col[64:96]
    T = [top, b1]
    T += [E.shrink_to(E.tight(o), pal, 32, 32) for o in E.objects("c_tiles_a", 5)]      # 2..5 chalk boxes, 6 the plain one
    ob = E.objects("c_tiles_b", 6)
    hop = E.tight(ob[4])
    hp = E.shrink_to(hop, pal, round(hop.shape[1] * 32 / hop.shape[0]), 32)
    ctile = period(hp, 32, 10)
    T.append(ctile)                                                                    # 7 hopscotch plank
    ramp = E.shrink_to(E.tight(ob[3]), pal, 64, 32)
    a, b = ramp[:, :32], ramp[:, 32:]
    T += [a, b, b[:, ::-1].copy(), a[:, ::-1].copy()]                                  # 8..11 ramps
    bm = E.tight(ob[0])
    bt = E.shrink_to(bm, pal, round(bm.shape[1] * 32 / bm.shape[0]), 32)
    btile = period(bt, 32, 0)
    for i in range(4):
        f = btile.copy()
        f[6:26] = np.roll(btile[6:26], 8 * i, axis=1)
        T.append(f)                                                                    # 12..15 belt
    T.append(E.shrink_to(E.tight(ob[1]), pal, 32, 32))
    T.append(E.shrink_to(E.tight(ob[2]), pal, 32, 32))                                 # 16, 17 ends
    E.save("CT_TILES", T, (0, 0), [f"t{i}" for i in range(len(T))])
    rep = lambda img, n: np.concatenate([img] * n, axis=1)
    col3 = np.concatenate([top, b1, b2], axis=0)
    body3 = np.concatenate([b1, b2, b1], axis=0)
    E.single("CT_FLOORCOL", col3, "tl")
    for n in (2, 4, 8):
        E.single(f"CT_FLOOR{n}", rep(col3, n), "tl")
        E.single(f"CT_COUNTER{n}", rep(ctile, n), "tl")
        E.single(f"CT_CRATES{n}", rep(T[6], n), "tl")
    for n in (1, 2, 4, 8):
        E.single(f"CT_BODY{n}", rep(body3, n), "tl")
    E.single("CT_CART", E.fit_to(ob[5], pal, 96, "w"), "feet")
    pf, pa, _ = E.anim_frames("c_pad", 3, 64, by="w", pal=pal)
    E.strip("CT_PAD", [(pf, pa, ["taut", "press", "squash"])])


def enemies() -> None:
    E.anim("CE_PIGEON", 10, [f"walk_{i}" for i in range(8)] + ["hurt_0", "def_0"], 56, sheet="c_pigeon")
    E.anim("CE_BALL", 10, [f"bounce_{i}" for i in range(8)] + ["hurt_0", "def_0"], 50, sheet="c_ball")
    E.anim("CE_SNAIL", 13, [f"slide_{i}" for i in range(8)] + [f"hide_{i}" for i in range(3)] + ["def_0", "def_1"], 52, sheet="c_snail")
    E.anim("CE_KITE", 10, [f"fly_{i}" for i in range(8)] + ["def_0", "def_1"], 64, sheet="c_kite", flying=True)


def blanket(w: int, h: int, pal_red, pal_white, outline) -> np.ndarray:
    c = np.zeros((h, w, 4), np.uint8)
    for y in range(h):
        inset = max(0, 6 - y) if False else 0
        for x in range(w):
            c[y, x] = (*(pal_red if ((x // 8) + (y // 6)) % 2 == 0 else pal_white), 255)
    c[0, :] = (*outline, 255); c[-1, :] = (*outline, 255); c[:, 0] = (*outline, 255); c[:, -1] = (*outline, 255)
    return c


def items() -> None:
    E.anim("CI_COIN", 8, [f"spin_{i}" for i in range(8)], 36, flying=True, sheet="c_coin")
    pal = E.pal_from(E.opaque_px("c_pack", False))
    ob = E.objects("c_pack", 4)
    lol = [E.tight(E.shrink(o, pal, 56 / o.shape[0])) for o in ob[:2]]
    cells, anchor = E.place(lol, [(x.shape[1] // 2, x.shape[0] // 2) for x in lol])
    E.save("CI_LOLLI", cells, anchor, ["icecream", "lolly"])
    fl = [E.fit_to(ob[2], pal, 150), E.fit_to(ob[3], pal, 150)]
    fl = [fl[0], fl[1], fl[0], fl[1]]
    an = [E.feet_anchor(f) for f in fl]
    cells, anchor = E.place(fl, an)
    E.save("CI_FLAG", cells, anchor, [f"wave_{i}" for i in range(4)])
    # the checkpoint: Poncho's toy keyboard (world 1's frames) on a picnic blanket
    km = json.loads((GAME / "art/env/TOY_KEYBOARD.json").read_text())
    kim = Image.open(GAME / "art/env/TOY_KEYBOARD.png").convert("RGBA")
    out = E.OUT
    blk = blanket(116, 22, (214, 62, 62), (246, 240, 226), tuple(out))
    blk[:3, :] = 0
    frames = []
    kts = []
    for i in range(6):
        kf = np.asarray(kim.crop((i * km["w"], 0, (i + 1) * km["w"], km["h"])))
        ys, xs = np.where(kf[..., 3] > 0)
        kts.append(kf[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
    kmax = max(k.shape[0] for k in kts) + 6
    for kt in kts:
        H, W = blk.shape[0] + kmax, 116
        c = np.zeros((H, W, 4), np.uint8)
        c[H - blk.shape[0]:] = blk
        y0 = H - blk.shape[0] - kt.shape[0] + 6
        sub = c[y0:y0 + kt.shape[0], (W - kt.shape[1]) // 2:(W - kt.shape[1]) // 2 + kt.shape[1]]
        sub[kt[..., 3] > 0] = kt[kt[..., 3] > 0]
        frames.append(c)
    E.save("CI_KEYBOARD", frames, (58, frames[0].shape[0] - 1), ["idle_0", "idle_1", "play_0", "play_1", "play_2", "play_3"])


GROUPS = {"far": far, "mid": mid, "fore": fore, "tiles": tiles, "enemies": enemies, "items": items}

if __name__ == "__main__":
    for g in sys.argv[1:] or list(GROUPS):
        print(g)
        GROUPS[g]()
