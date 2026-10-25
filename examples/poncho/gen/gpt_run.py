"""Runs the image-model jobs of gen/gpt_jobs.py (the codex bridge) with tools/sheet_jobs.py: raw pictures in the game's raw/ (git-ignored), nothing asked twice, a missing reference reported.

    python3 gen/gpt_run.py --plan                      # what would be asked (a call is about 1% of a five-hour window)
    python3 gen/gpt_run.py                             # ask what is missing (the references first)
    python3 gen/gpt_run.py --only poncho_dino          # one outfit
    python3 gen/gpt_run.py --redo poncho_run.png       # ask one again (the old one goes to raw/old/)
The default outfit's references are free crops of raw/poncho_canon_a.png and raw/poncho_style_a.png (made by the user's approved pictures); the four costumes' are asked."""
from __future__ import annotations

import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[2] / "tools"))
import gpt_jobs as J  # noqa: E402
import sheet_jobs as SJ  # noqa: E402

SJ.BRIDGE = HERE / "bridge.sh"   # the same bridge, with the "@@WxH" size marker
RAW = SJ.raw_dir(HERE.parent)
CANON, STYLE = RAW / "poncho_canon_a.png", RAW / "poncho_style_a.png"


def crops() -> None:
    """The two free references: the three-quarter view facing right from the canonical sheet, and the boy on his scooter from the approved style test (one character per picture)."""
    from PIL import Image
    for out, src, box in ((RAW / "poncho_ref.png", CANON, (385, 190, 712, 740)), (RAW / "poncho_scooter_ref.png", STYLE, (520, 220, 1000, 900))):
        if not SJ.done(out) and src.exists():
            Image.open(src).convert("RGB").crop(box).save(out)


def jobs() -> list[SJ.Job]:
    crops()
    out = []
    for cid, c in J.CHARS.items():
        ref = RAW / f"{cid}_ref.png"
        if c["ref"]:
            out.append(SJ.Job(c["ref"], ref, RAW / "poncho_ref.png"))
        sheet_ref = ref if c["ref"] or cid == "poncho_scooter" else RAW / "poncho_ref.png"
        if cid == "poncho":
            ref = RAW / "poncho_ref.png"
        for name, n, desc, _, _, size in c["sheets"]:
            who = J.BOY + " wearing " + J.BASE if cid in ("poncho", "poncho_scooter") else "the boy of the reference in the outfit of the reference"
            out.append(SJ.Job(SJ.sheet(f"{n} frames of {who}: {desc}. " + J.STYLE + " " + J.SHEET + (J.STRICT if name in ("jump", "hurt", "brake", "b") else "")) + size, RAW / f"{cid}_{name}.png", ref))
    return out


if __name__ == "__main__":
    SJ.main(jobs(), int(os.environ.get("GPT_WORKERS", 4)))
