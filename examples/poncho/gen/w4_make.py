"""World 4 (the keyboard stage) and BOSS_SILENCIO: raw sheets -> art/w3/<ID>.png + .json (KM_ far/mid/fore, KT_ tiles, KE_ foes, KI_ items), the same surgical pipeline as gen/w2_make.py.
    python3 gen/w4_make.py [group ...]     groups: far mid fore tiles enemies items"""
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
E.ART = GAME / "art" / "w4"
E.ART.mkdir(parents=True, exist_ok=True)
ART, NCOL, period = E.ART, E.NCOL, W2.period


def far() -> None:
    im = Image.open(E.RAW / "k_far.png").convert("RGB")
    im = im.crop((0, 0, im.width, int(im.height * 0.735)))     # sky, trees, railing and flower boxes: down to the foot of the railing; the pavement is the floor
    pal = E.pal_from(np.asarray(im).reshape(-1, 3)[::30], NCOL, halo=False)
    a = np.dstack([np.asarray(im), np.full((im.height, im.width), 255, np.uint8)])
    out = E.shrink(a, pal, 200 / im.height)
    far_ = E.loop_blend(out, 40)
    Image.fromarray(far_).save(ART / "KM_FAR.png")
    print("  KM_FAR:", far_.shape[1], "x", far_.shape[0], "bottom colour 0x%02X%02X%02X" % tuple(far_[-1, far_.shape[1] // 2, :3]))


MID = {"k_mid_a": [("SPEAKERS", 180, "feet"), ("DRUMS", 120, "feet"), ("MIC", 150, "feet"), ("PIANO", 120, "feet"), ("DISCO", 100, "top")],
       "k_mid_b": [("SPOT", 170, "feet"), ("TRUMPET", 80, "feet"), ("EQ", 110, "feet"), ("CLEF", 130, "feet"), ("MONITOR", 60, "feet"), ("CASES", 90, "feet")],
       "k_mid_c": [("CURTAIN", 230, "top"), ("NOTES2", 60, "centre"), ("NOTEPINK", 50, "centre"), ("NOTES16", 56, "centre"), ("CABLE", 40, "feet"), ("LIGHTS", 90, "top")]}


def mid() -> None:
    pal = E.pal_from(np.concatenate([E.opaque_px(n, False) for n in MID]))
    for sheet, items in MID.items():
        for (name, size, anchor), o in zip(items, E.objects(sheet, len(items))):
            E.single(f"KM_{name}", E.fit_to(o, pal, size, "w" if name in ("LIGHTS", "EQ") and False else "h"), anchor)


def fore() -> None:
    pal = E.pal_from(E.opaque_px("k_fore", False))
    for (name, size, by), o in zip((("MIC", 90, "h"), ("STICKS", 100, "w"), ("PICK", 50, "h"), ("PHONES", 80, "h"), ("JACK", 90, "w"), ("NOTES", 70, "h")), E.objects("k_fore", 6)):
        E.single(f"KM_FORE_{name}", E.fit_to(o, pal, size, by), "tl")


def tiles() -> None:
    slab = Image.open(E.RAW / "k_floor.png").convert("RGB")
    px = [np.asarray(slab).reshape(-1, 3)[::30]] + [E.opaque_px(n, False) for n in ("k_tiles_a", "k_tiles_b")]
    pal = E.pal_from(np.concatenate(px), NCOL, halo=True)
    sl = E.shrink_to(np.dstack([np.asarray(slab), np.full((slab.height, slab.width), 255, np.uint8)]), pal, round(slab.width * 98 / slab.height), 98)[2:]
    col = period(sl, 32, 40)
    top, b1, b2 = col[0:32], col[32:64], col[64:96]
    T = [top, b1]
    T += [E.shrink_to(E.tight(o), pal, 32, 32) for o in E.objects("k_tiles_a", 5)]      # 2..5 chalk boxes, 6 the plain one
    ob = E.objects("k_tiles_b", 6)
    hop = E.tight(ob[4])
    hp = E.shrink_to(hop, pal, round(hop.shape[1] * 32 / hop.shape[0]), 32)
    ctile = period(hp, 32, 10)
    T.append(ctile)                                                                    # 7 stage plank
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
    E.save("KT_TILES", T, (0, 0), [f"t{i}" for i in range(len(T))])
    rep = lambda img, n: np.concatenate([img] * n, axis=1)
    col3 = np.concatenate([top, b1, b2], axis=0)
    body3 = np.concatenate([b1, b2, b1], axis=0)
    E.single("KT_FLOORCOL", col3, "tl")
    for n in (2, 4, 8):
        E.single(f"KT_FLOOR{n}", rep(col3, n), "tl")
        E.single(f"KT_COUNTER{n}", rep(ctile, n), "tl")
        E.single(f"KT_CRATES{n}", rep(T[6], n), "tl")
    for n in (1, 2, 4, 8):
        E.single(f"KT_BODY{n}", rep(body3, n), "tl")
    E.single("KT_CART", E.fit_to(ob[5], pal, 96, "w"), "feet")
    pf, pa, _ = E.anim_frames("k_pad", 3, 64, by="w", pal=pal)
    E.strip("KT_PAD", [(pf, pa, ["taut", "press", "squash"])])


def enemies() -> None:
    E.anim("KE_NOTE", 10, [f"hop_{i}" for i in range(8)] + ["hurt_0", "def_0"], 56, sheet="k_note")
    E.anim("KE_CABLE", 13, [f"slide_{i}" for i in range(8)] + [f"coil_{i}" for i in range(3)] + ["def_0", "def_1"], 50, sheet="k_cable")
    E.anim("KE_SPEAKER", 10, [f"pulse_{i}" for i in range(6)] + ["shout_0", "shout_1", "hurt_0", "def_0"], 60, sheet="k_speaker")
    E.anim("KE_BUBBLE", 10, [f"float_{i}" for i in range(8)] + ["def_0", "def_1"], 64, sheet="k_bubble", flying=True)


def blanket(w: int, h: int, pal_red, pal_white, outline) -> np.ndarray:
    c = np.zeros((h, w, 4), np.uint8)
    for y in range(h):
        inset = max(0, 6 - y) if False else 0
        for x in range(w):
            c[y, x] = (*(pal_red if ((x // 8) + (y // 6)) % 2 == 0 else pal_white), 255)
    c[0, :] = (*outline, 255); c[-1, :] = (*outline, 255); c[:, 0] = (*outline, 255); c[:, -1] = (*outline, 255)
    return c


def items() -> None:
    E.anim("KI_COIN", 8, [f"spin_{i}" for i in range(8)], 36, flying=True, sheet="k_coin")
    pal = E.pal_from(E.opaque_px("k_pack", False))
    ob = E.objects("k_pack", 4)
    lol = [E.tight(E.shrink(o, pal, 44 / o.shape[0])) for o in ob[:2]]
    cells, anchor = E.place(lol, [(x.shape[1] // 2, x.shape[0] // 2) for x in lol])
    E.save("KI_LOLLI", cells, anchor, ["heart", "star"])
    fl = [E.fit_to(ob[2], pal, 150), E.fit_to(ob[3], pal, 150)]
    fl = [fl[0], fl[1], fl[0], fl[1]]
    cells, anchor = E.place(fl, [E.feet_anchor(f) for f in fl])
    E.save("KI_FLAG", cells, anchor, [f"wave_{i}" for i in range(4)])
    rp = Image.open(E.RAW / "k_riser.png")
    rpal = E.pal_from(E.opaque_px("k_riser", False))
    risers = [E.fit_to(o, rpal, 120, "w") for o in E.objects("k_riser", 2)]
    km = json.loads((GAME / "art/env/TOY_KEYBOARD.json").read_text())
    kim = Image.open(GAME / "art/env/TOY_KEYBOARD.png").convert("RGBA")
    kts = []
    for i in range(6):
        kf = np.asarray(kim.crop((i * km["w"], 0, (i + 1) * km["w"], km["h"])))
        ys, xs = np.where(kf[..., 3] > 0)
        kts.append(kf[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
    kts = [np.asarray(Image.fromarray(k).resize((round(k.shape[1] * 0.7), round(k.shape[0] * 0.7)), Image.NEAREST)) for k in kts]   # a MINI keyboard
    kmax = max(k.shape[0] for k in kts) + 6
    frames = []
    for i, kt in enumerate(kts):
        r = risers[1 if i >= 2 else 0]
        H, W = r.shape[0] + kmax, r.shape[1]
        c = np.zeros((H, W, 4), np.uint8)
        c[H - r.shape[0]:] = r
        y0 = H - r.shape[0] - kt.shape[0] + 6
        sub = c[y0:y0 + kt.shape[0], (W - kt.shape[1]) // 2:(W - kt.shape[1]) // 2 + kt.shape[1]]
        sub[kt[..., 3] > 0] = kt[kt[..., 3] > 0]
        frames.append(c)
    E.save("KI_KEYBOARD", frames, (frames[0].shape[1] // 2, frames[0].shape[0] - 1), ["idle_0", "idle_1", "play_0", "play_1", "play_2", "play_3"])


def silencio() -> None:
    W2.boss("sil", [("sil_a", 6, [f"idle_{i}" for i in range(6)]), ("sil_b", 6, [f"shh_{i}" for i in range(6)]), ("sil_c", 6, [f"swallow_{i}" for i in range(6)]),
                    ("sil_d", 7, [f"hurt_{i}" for i in range(3)] + [f"angry_{i}" for i in range(4)]), ("sil_e", 8, [f"stun_{i}" for i in range(4)] + [f"def_{i}" for i in range(4)])], 170, "BOSS_SILENCIO")


GROUPS = {"far": far, "mid": mid, "fore": fore, "tiles": tiles, "enemies": enemies, "items": items, "silencio": silencio}

if __name__ == "__main__":
    for g in sys.argv[1:] or list(GROUPS):
        print(g)
        GROUPS[g]()
