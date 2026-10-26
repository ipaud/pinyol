"""World 2 (the living fruit market) and the boss Capitan Cuerda: raw sheets -> art/w2/<ID>.png + .json, with gen/env_make.py's surgical pipeline (blob cutting, one locked palette per group,
majority-vote reduction, cleaning).   python3 gen/w2_make.py [group ...]      groups: far mid fore tiles enemies sandia cuerda items"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import env_make as E  # noqa: E402
import gpt_make as M  # noqa: E402

GAME = HERE.parent
E.ART = GAME / "art" / "w2"
E.ART.mkdir(parents=True, exist_ok=True)
ART = E.ART
RAW = E.RAW
NCOL = E.NCOL


def period(img: np.ndarray, w: int = 32, lo: int = 0) -> np.ndarray:
    """A w px wide piece of a picture that repeats without a seam: the x where the column at x and the one w px on differ least (no dissolve, so no dots)."""
    best = min(range(lo, img.shape[1] - w - 1), key=lambda x: float(np.abs(img[:, x].astype(int) - img[:, x + w].astype(int)).sum() + 0.3 * np.abs(img[:, x + 1].astype(int) - img[:, x + w + 1].astype(int)).sum()))
    return img[:, best:best + w].copy()


def far() -> None:
    ims = [Image.open(RAW / f"m_far_{k}.png").convert("RGB") for k in "ab"]
    pal = E.pal_from(np.concatenate([np.asarray(i).reshape(-1, 3)[::40] for i in ims]), NCOL, halo=False)
    out = []
    for im in ims:
        a = np.dstack([np.asarray(im), np.full((im.height, im.width), 255, np.uint8)])
        out.append(E.shrink(a, pal, 150 / im.height))
    h = min(o.shape[0] for o in out)
    far_ = E.loop_blend(E.seam_blend(out[0][:h], out[1][:h], 40), 40)
    Image.fromarray(far_).save(ART / "FM_FAR.png")
    print("  FM_FAR:", far_.shape[1], "x", far_.shape[0])


MID = {"m_mid_a": [("STALL_1", 180, "feet"), ("STALL_2", 180, "feet"), ("STALL_3", 180, "feet"), ("STALL_4", 180, "feet"), ("STALL_5", 180, "feet")],
       "m_mid_b": [("FOUNTAIN", 150, "feet"), ("CART", 110, "feet"), ("BARRELS", 90, "feet"), ("CRATEPYR", 120, "feet"), ("LAMP", 210, "feet"), ("CRATEPEAR", 100, "feet")],
       "m_mid_c": [("BUNTING", 440, "top"), ("LANTERNS", 90, "top"), ("SIGN", 130, "feet"), ("WHEELBARROW", 70, "feet"), ("SACKS", 60, "feet"), ("PARASOL", 170, "feet")]}


def mid() -> None:
    pal = E.pal_from(np.concatenate([E.opaque_px(n, False) for n in MID]))
    for sheet, items in MID.items():
        for (name, size, anchor), o in zip(items, E.objects(sheet, len(items))):
            E.single(f"FM_{name}", E.fit_to(o, pal, size, "w" if name == "BUNTING" else "h"), anchor)


def fore() -> None:
    pal = E.pal_from(E.opaque_px("m_fore", False))
    for (name, size, by), o in zip((("CABBAGE", 100, "w"), ("CAT", 80, "h"), ("BASKET", 70, "h"), ("CAN", 64, "h"), ("SACK", 76, "h"), ("CARROTS", 90, "w")), E.objects("m_fore", 6)):
        E.single(f"FM_FORE_{name}", E.fit_to(o, pal, size, by), "tl")


def tiles() -> None:
    slab = Image.open(RAW / "t_floor.png").convert("RGB")
    px = [np.asarray(slab).reshape(-1, 3)[::30]] + [E.opaque_px(n, False) for n in ("t_crates", "t_belt", "t_ramp")]
    pal = E.pal_from(np.concatenate(px), NCOL, halo=True)
    sl = E.shrink_to(np.dstack([np.asarray(slab), np.full((slab.height, slab.width), 255, np.uint8)]), pal, round(slab.width * 96 / slab.height), 96)
    col = period(sl, 32, 40)
    top, b1, b2 = col[0:32], col[32:64], col[64:96]
    T = [top, b1]
    crates = E.objects("t_crates", 5)
    T += [E.shrink_to(E.tight(o), pal, 32, 32) for o in crates]            # 2..5 fruit crates, 6 the empty one
    ramp_o = E.objects("t_ramp", 4)
    counter = E.tight(ramp_o[1])
    cr = E.shrink_to(counter, pal, round(counter.shape[1] * 32 / counter.shape[0]), 32)
    ctile = period(cr, 32, 10)
    T.append(ctile)                                                          # 7 stall counter tile
    ramp = E.shrink_to(E.tight(ramp_o[0]), pal, 64, 32)
    a, b = ramp[:, :32], ramp[:, 32:]
    T += [a, b, b[:, ::-1].copy(), a[:, ::-1].copy()]                        # 8..11 ramps a b c d
    belt_o = E.objects("t_belt", 3)
    bm = E.tight(belt_o[0])
    bt = E.shrink_to(bm, pal, round(bm.shape[1] * 32 / bm.shape[0]), 32)
    btile = period(bt, 32, 0)
    for i in range(4):                                                       # 12..15 the tread moves 8 px a frame (its middle rows)
        f = btile.copy()
        f[8:24] = np.roll(btile[8:24], 8 * i, axis=1)
        T.append(f)
    T.append(E.shrink_to(E.tight(belt_o[1]), pal, 32, 32))                   # 16 left end
    T.append(E.shrink_to(E.tight(belt_o[2]), pal, 32, 32))                   # 17 right end
    E.save("FT_TILES", T, (0, 0), [f"t{i}" for i in range(len(T))])
    rep = lambda img, n: np.concatenate([img] * n, axis=1)
    col3 = np.concatenate([top, b1, b2], axis=0)
    body3 = np.concatenate([b1, b2, b1], axis=0)
    E.single("FT_FLOORCOL", col3, "tl")
    for n in (2, 4, 8):
        E.single(f"FT_FLOOR{n}", rep(col3, n), "tl")
        E.single(f"FT_COUNTER{n}", rep(ctile, n), "tl")
        E.single(f"FT_CRATES{n}", rep(T[6], n), "tl")
    for n in (1, 2, 4, 8):
        E.single(f"FT_BODY{n}", rep(body3, n), "tl")
    E.single("FT_CART", E.fit_to(ramp_o[2], pal, 96, "w"), "feet")
    pf, pa, _ = E.anim_frames("t_awning", 3, 64, by="w", pal=pal)
    E.strip("FT_PAD", [(pf, pa, ["taut", "press", "squash"])])


def enemies() -> None:
    f, a, pal = E.anim_frames("apple_a", 12, 56)
    k = E.LAST_K[0]
    f2, a2, _ = E.anim_frames("apple_b", 8, 0, k=k, pal=pal)
    E.strip("FE_APPLE", [(f[:8], a[:8], [f"walk_{i}" for i in range(8)]), (f[8:], a[8:], [f"curl_{i}" for i in range(4)]),
                         (f2[:6], a2[:6], [f"roll_{i}" for i in range(6)]), (f2[6:], a2[6:], ["hurt_0", "def_0"])])
    E.anim("FE_BANANA", 13, [f"slide_{i}" for i in range(8)] + [f"squash_{i}" for i in range(3)] + ["def_0", "def_1"], 52, sheet="banana")
    E.anim("FE_BEE", 14, [f"fly_{i}" for i in range(8)] + [f"dive_{i}" for i in range(4)] + ["def_0", "def_1"], 56, sheet="bee", by="w", flying=True)
    E.anim("FE_CHERRY", 10, [f"bounce_{i}" for i in range(8)] + ["def_0", "def_1"], 52, sheet="cherry")


def boss(prefix: str, sheets: list, height: int, out: str) -> None:
    """A boss: every sheet by ONE scale (frame 0 of the first is `height` px tall) and ONE locked palette; [(sheet, count, [names])]."""
    pal = E.pal_from(np.concatenate([E.opaque_px(s, False) for s, _, _ in sheets]), NCOL, halo=False)
    parts, k = [], None
    for sheet, n, names in sheets:
        f, a, _ = E.anim_frames(sheet, n, height, k=k, pal=pal)
        k = E.LAST_K[0]
        parts.append((f, a, names))
    E.strip(out, parts)


def sandia() -> None:
    boss("sandia", [("sandia_a", 6, [f"idle_{i}" for i in range(6)]), ("sandia_b", 8, [f"roll_{i}" for i in range(8)]), ("sandia_c", 6, [f"spit_{i}" for i in range(6)]),
                    ("sandia_d", 7, [f"hurt_{i}" for i in range(3)] + [f"angry_{i}" for i in range(4)]), ("sandia_e", 4, [f"def_{i}" for i in range(4)])], 140, "BOSS_SANDIA")


def cuerda() -> None:
    boss("cuerda", [("cuerda_a", 9, [f"idle_{i}" for i in range(6)] + [f"hurt_{i}" for i in range(3)]), ("cuerda_b", 8, [f"walk_{i}" for i in range(8)]),
                    ("cuerda_c", 10, [f"stomp_{i}" for i in range(6)] + [f"angry_{i}" for i in range(4)]), ("cuerda_d", 10, [f"spin_{i}" for i in range(6)] + [f"def_{i}" for i in range(4)])],
         140, "BOSS_CUERDA")


def items() -> None:
    E.anim("FI_COIN", 8, [f"spin_{i}" for i in range(8)], 36, flying=True, sheet="w2_coin")
    pal = E.pal_from(E.opaque_px("w2_pack", False))
    ob = E.objects("w2_pack", 5)
    lol = [E.tight(E.shrink(o, pal, 52 / o.shape[0])) for o in ob[:3]]
    cells, anchor = E.place(lol, [(x.shape[1] // 2, x.shape[0] // 2) for x in lol])
    E.save("FI_LOLLI", cells, anchor, ["rainbow", "pink", "green"])
    tables = [E.fit_to(o, pal, 110, "w") for o in ob[3:]]
    for i, t in enumerate(tables):
        E.single(f"FI_TABLE_{i + 1}", t, "feet")
    # the checkpoint: Poncho's toy keyboard (world 1's frames) sitting on the first table
    km = __import__("json").loads((GAME / "art/env/TOY_KEYBOARD.json").read_text())
    kim = Image.open(GAME / "art/env/TOY_KEYBOARD.png").convert("RGBA")
    t = tables[0]
    frames = []
    kmax = max(int(np.asarray(kim.crop((i * km['w'], 0, (i + 1) * km['w'], km['h'])))[..., 3].any(1).sum()) for i in range(6)) + 8
    for i in range(6):
        kf = np.asarray(kim.crop((i * km["w"], 0, (i + 1) * km["w"], km["h"])))
        kf = E.tight(kf) if False else kf
        ys, xs = np.where(kf[..., 3] > 0)
        kt = kf[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        H = t.shape[0] + kmax
        W = max(t.shape[1], kt.shape[1])
        c = np.zeros((H + 0, W, 4), np.uint8)
        c[H - t.shape[0]:, (W - t.shape[1]) // 2:(W - t.shape[1]) // 2 + t.shape[1]] = t
        y0 = H - t.shape[0] - kt.shape[0] + 4
        assert y0 >= 0
        sub = c[y0:y0 + kt.shape[0], (W - kt.shape[1]) // 2:(W - kt.shape[1]) // 2 + kt.shape[1]]
        sub[kt[..., 3] > 0] = kt[kt[..., 3] > 0]
        frames.append(c)
    E.save("FI_KEYBOARD", frames, (frames[0].shape[1] // 2, frames[0].shape[0] - 1), ["idle_0", "idle_1", "play_0", "play_1", "play_2", "play_3"])
    f, a, _ = E.anim_frames("w2_flag", 6, 150)
    cells, anchor = E.place(f, a)
    cols = np.where(np.stack(cells)[..., 3].any(axis=(0, 1)))[0]
    x0, x1 = int(max(0, cols.min() - 2)), int(min(cells[0].shape[1], cols.max() + 3))
    E.save("FI_FLAG", [c[:, x0:x1] for c in cells], (int(anchor[0] - x0), int(anchor[1])), [f"wave_{i}" for i in range(6)])


GROUPS = {"far": far, "mid": mid, "fore": fore, "tiles": tiles, "enemies": enemies, "sandia": sandia, "cuerda": cuerda, "items": items}

if __name__ == "__main__":
    for g in sys.argv[1:] or list(GROUPS):
        print(g)
        GROUPS[g]()
