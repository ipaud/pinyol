#!/usr/bin/env python3
"""El Faro de las Ánimas' music: every song as a Standard MIDI File (audio/<name>.mid) played by the game's bank of samples (audio/BANK.bank, the
PlayStation's SEQ and VAB: notes on ADPCM samples, the bank copied from Taller's), all of it in one reverb room, as a 32-bit console's soundtrack sat
in its sound chip's hall. Songs: titulo (a habanera, the sea songs of the Catalan coast), torre (the first floors: a music box and strings in the dark),
maquina (the clockwork room: pizzicato and ticking), tormenta (the gallery outside, the storm), pop (the octopus), fin (the dawn, the habanera in major);
jingles: planta (a floor done), helada (the lantern goes out).

    python3 gen/songs.py               the bank (if it is missing) and every song
    python3 gen/songs.py --check DIR   every song played by the engine and measured (gen/music_check.py)

The notation is gen/music_seq.py's: a sixteenth note is the unit, `C5:4` a quarter note, `|` a bar line (checked).
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from music_seq import Song, arp, bassline, comp, transpose, write_smf  # noqa: E402

GAME = HERE.parent
SONGS: dict = {}


def song(fn):
    SONGS[fn.__name__] = fn
    return fn


def bars(*b: str) -> str:
    return " | ".join(b) + " |"


def rep(grid: str, n: int, last: str | None = None) -> str:
    g = [grid] * n
    if last:
        g[-1] = last
    return "|".join(g) + "|"


def jingle(name: str, bpm: float, key: str, beats: int = 4, about: str = "") -> Song:
    return Song(name, bpm, key, beats=beats, jingle=True, about=about)


# ------------------------------------------------------------------ the habanera (title)

HAB_A = bars("A4:3 D5:1 F5:2 E5:2", "D5:6 A4:2", "C#5:3 D5:1 E5:2 G5:2", "F5:4 E5:4",
             "E5:3 F5:1 G5:2 Bb5:2", "A5:6 F5:2", "G5:3 F5:1 E5:2 C#5:2", "D5:8")
HAB_PA = [("Dm", 8), ("Dm", 8), ("A7", 8), ("A7", 8), ("A7", 8), ("Dm", 8), ("Gm", 4), ("A7", 4), ("Dm", 8)]
HAB_B = bars("C5:3 F5:1 A5:2 G5:2", "F5:6 C5:2", "E5:3 F5:1 G5:2 Bb5:2", "G5:4 E5:4",
             "D5:3 F5:1 Bb5:2 A5:2", "A5:4 F5:4", "G5:3 A5:1 G5:2 E5:2", "F5:8")
HAB_PB = [("F", 8), ("F", 8), ("C7", 8), ("C7", 8), ("Bb", 8), ("F", 8), ("C7", 8), ("F", 8)]
HAB_GUIT = "x--xx-x-"  # the habanera's own step: a dotted eighth, a sixteenth, two eighths
HAB_BASS = "R:3 R:1 5:2 O:2"


@song
def titulo():
    """D minor to F major, 2/4, 76 BPM: a habanera as the fishermen sing them on the beach. The tune on the accordion, a nylon guitar and an
    upright bass on the habanera's step, strings holding the chords, a flute answering; a chapel bell over the intro."""
    s = Song("titulo", 76, "D minor / F major", beats=2, about="title")
    s.track("acc", 0, 21, 96, -0.1, 50).track("gtr", 1, 24, 84, 0.3, 40).track("bass", 2, 32, 110, 0, 30)
    s.track("str", 3, 48, 58, -0.35, 60).track("fl", 4, 73, 80, 0.25, 60).track("bell", 5, 14, 70, 0.1, 70).track("kit", 9, 0, 70)
    s.part("intro", 4, bell="D5:8 | r:8 | A4:8 | r:8 |", str=comp([("Dm", 16), ("A7", 16)], "x-------", "A3", "F5"),
           gtr=comp([("Dm", 16), ("A7", 16)], HAB_GUIT, "D3", "A4", 4, 8), kit=rep("....n...", 3, "...nn.n."))
    s.part("A", 8, acc=HAB_A, gtr=comp(HAB_PA, HAB_GUIT, "D3", "A4", 4, 8), bass=bassline(HAB_PA, HAB_BASS, "A1", 8),
           str=comp(HAB_PA, "x-------", "A3", "F5", 3, 8), kit=rep("k...n.n.", 8))
    s.part("B", 8, fl=HAB_B, acc=transpose(HAB_B, -12), gtr=comp(HAB_PB, HAB_GUIT, "C3", "A4", 4, 8), bass=bassline(HAB_PB, HAB_BASS, "A1", 8),
           str=comp(HAB_PB, "x-------", "A3", "F5", 3, 8), kit=rep("k...n.n.", 8, "k..nn.nn"))
    return s.form(["intro"], ["A", "B"])


@song
def fin():
    """F major, 2/4, 70 BPM: the dawn. The habanera's second tune on the flute, then the first in D major on the accordion, a music box over it."""
    s = Song("fin", 70, "F major / D major", beats=2, about="ending")
    s.track("fl", 0, 73, 92, -0.1, 60).track("acc", 1, 21, 80, 0.2, 50).track("gtr", 2, 24, 80, 0.3, 40).track("bass", 3, 32, 104, 0, 30)
    s.track("mb", 4, 10, 66, -0.3, 70).track("str", 5, 48, 56, 0.35, 60)
    major_a = bars("A4:3 D5:1 F#5:2 E5:2", "D5:6 A4:2", "C#5:3 D5:1 E5:2 G5:2", "F#5:4 E5:4",
                   "E5:3 F#5:1 G5:2 B5:2", "A5:6 F#5:2", "G5:3 F#5:1 E5:2 C#5:2", "D5:8")
    pa = [("D", 8), ("D", 8), ("A7", 8), ("A7", 8), ("A7", 8), ("D", 8), ("G", 4), ("A7", 4), ("D", 8)]
    s.part("B", 8, fl=HAB_B, gtr=comp(HAB_PB, HAB_GUIT, "C3", "A4", 4, 8), bass=bassline(HAB_PB, HAB_BASS, "A1", 8),
           str=comp(HAB_PB, "x-------", "A3", "F5", 3, 8), mb=transpose(HAB_B, 12))
    s.part("A", 8, acc=major_a, gtr=comp(pa, HAB_GUIT, "D3", "A4", 4, 8), bass=bassline(pa, HAB_BASS, "A1", 8),
           str=comp(pa, "x-------", "A3", "F#5", 3, 8), mb=arp(pa, [0, 1, 2, 3], "A5", "F#6", 2, 3))
    return s.form([], ["B", "A"])


# ------------------------------------------------------------------ inside the tower

@song
def torre():
    """D minor, 4/4, 72 BPM: the dark floors. Strings holding the chords, a music box turning arpeggios, a flute singing long notes, an
    upright bass, a bell tolling every two bars; everything wet with the hall."""
    s = Song("torre", 72, "D minor", about="floors 1 and 2")
    s.track("str", 0, 48, 70, -0.3, 70).track("mb", 1, 10, 74, 0.3, 80).track("fl", 2, 73, 84, 0, 70).track("bass", 3, 32, 100, 0, 40)
    s.track("bell", 4, 14, 60, 0.15, 90).track("kit", 9, 0, 60)
    p = [("Dm", 16), ("C", 16), ("Bb", 16), ("A", 16), ("Dm", 16), ("C", 16), ("Gm", 16), ("A", 16)]
    tune = bars("A5:8 G5:4 F5:4", "E5:12 r:4", "F5:6 D5:2 Bb4:8", "C#5:12 r:4",
                "D5:4 F5:4 A5:4 D6:4", "C6:8 G5:8", "Bb5:6 A5:2 G5:8", "A5:12 r:4")
    s.part("A", 8, str=comp(p, "x---------------", "A3", "F5"), mb=arp(p, [0, 1, 2, 1, 3, 2, 1, 2], "D5", "A6", 2, 4),
           bass=bassline(p, "R:8 5:8", "D2"), bell="D4:16 | r:16 | Bb3:16 | r:16 | D4:16 | r:16 | G3:16 | r:16 |",
           kit=rep("k.......k.......", 8))
    s.part("B", 8, str=comp(p, "x-------x-------", "A3", "F5"), mb=arp(p, [0, 1, 2, 3], "D5", "A6", 2, 4), fl=tune,
           bass=bassline(p, "R:8 5:8", "D2"), bell="D4:16 | r:16 | Bb3:16 | r:16 | D4:16 | r:16 | G3:16 | r:16 |",
           kit=rep("k.......k...k...", 8))
    return s.form([], ["A", "B"])


@song
def maquina():
    """A minor, 4/4, 96 BPM: the clockwork room that turns the lamp. Pizzicato strings ticking eighths, wood blocks as the escapement, a
    glockenspiel tune, timpani on the downbeats, strings under it."""
    s = Song("maquina", 96, "A minor", about="floor 3, the clockwork")
    s.track("pizz", 0, 45, 88, -0.25, 40).track("glock", 1, 9, 76, 0.3, 60).track("str", 2, 48, 58, 0.1, 60).track("timp", 3, 47, 90, 0, 40)
    s.track("bass", 4, 32, 104, 0, 30).track("kit", 9, 0, 90)
    p = [("Am", 16), ("F", 16), ("Dm", 16), ("E7", 16), ("Am", 16), ("F", 16), ("Dm", 8), ("E7", 8), ("Am", 16)]
    tune = bars("E5:2 A5:2 C6:2 B5:2 A5:4 E5:4", "F5:2 A5:2 C6:2 A5:2 F5:8", "D5:2 F5:2 A5:2 F5:2 D5:4 F5:4", "E5:2 G#5:2 B5:2 G#5:2 E5:8",
                "E5:2 A5:2 C6:2 E6:2 D6:4 C6:4", "C6:2 A5:2 F5:2 A5:2 C6:8", "A5:4 F5:4 G#5:4 B5:4", "A5:12 r:4")
    s.part("A", 8, pizz=arp(p, [0, 2, 1, 2], "A3", "E5", 2, 3), str=comp(p, "x---------------", "A3", "E5"),
           timp="A1:4 r:12 | F2:4 r:12 | D2:4 r:12 | E2:4 r:12 | A1:4 r:12 | F2:4 r:12 | D2:4 r:4 E2:4 r:4 | A1:4 r:12 |",
           bass=bassline(p, "R:4 r:4 5:4 r:4", "A1"), kit=rep("w.W.w.W.w.W.w.W.", 8))
    s.part("B", 8, pizz=arp(p, [0, 2, 1, 2], "A3", "E5", 2, 3), str=comp(p, "x-------x-------", "A3", "E5"), glock=tune,
           timp="A1:4 r:12 | F2:4 r:12 | D2:4 r:12 | E2:4 r:12 | A1:4 r:12 | F2:4 r:12 | D2:4 r:4 E2:4 r:4 | A1:4 r:12 |",
           bass=bassline(p, "R:4 r:4 5:4 r:4", "A1"), kit=rep("wzWzwzWzwzWzwzWz", 8, "wzWzwzWzWWWWZZZZ"))
    return s.form([], ["A", "B"])


@song
def tormenta():
    """C minor, 4/4, 138 BPM: outside, on the gallery, in the storm. Strings sawing sixteenths, timpani and toms, a trumpet tune over a
    brass section, a crash on every phrase."""
    s = Song("tormenta", 138, "C minor", about="floor 4, the storm outside")
    s.track("str", 0, 49, 86, -0.2, 40).track("tp", 1, 56, 96, 0.15, 40).track("brass", 2, 61, 74, 0.3, 40).track("timp", 3, 47, 100, 0, 30)
    s.track("bass", 4, 32, 110, 0, 20).track("pad", 5, 48, 52, -0.4, 60).track("kit", 9, 0, 100)
    p = [("Cm", 16), ("Ab", 16), ("Fm", 16), ("G7", 16), ("Cm", 16), ("Ab", 16), ("Fm", 8), ("G7", 8), ("Cm", 16)]
    tune = bars("G4:4 C5:4 Eb5:4 D5:4", "C5:8 Ab4:8", "F4:4 Ab4:4 C5:4 Eb5:4", "D5:12 B4:4",
                "G5:4 Eb5:4 C5:4 G5:4", "Ab5:8 Eb5:8", "F5:4 Ab5:4 G5:4 B4:4", "C5:12 r:4")
    s.part("A", 8, str=arp(p, [0, 1, 2, 1], "G3", "Eb5", 1, 3), pad=comp(p, "x---------------", "G3", "Eb5"),
           bass=bassline(p, "R:2 R:2 R:2 R:2 R:2 R:2 5:2 R:2", "C2"),
           timp=rep("C2:4 r:4 G1:4 r:4", 1).replace("|", "") + " | " + " | ".join(["r:16"] * 7) + " |",
           kit=rep("k...s...k.k.s...", 8, "k...s...ffmmMMtt"))
    s.part("B", 8, str=arp(p, [0, 1, 2, 1], "G3", "Eb5", 1, 3), tp=tune, brass=comp(p, "x.....x.x.......", "G3", "Eb5"),
           bass=bassline(p, "R:2 R:2 R:2 R:2 R:2 R:2 5:2 R:2", "C2"),
           timp="C2:2 C2:2 r:12 | " + " | ".join(["r:16"] * 6) + " | G1:1 G1:1 G1:1 G1:1 G1:1 G1:1 G1:1 G1:1 r:8 |",
           kit=rep("c...s...k.k.s...", 8, "k.s.s.s.ffmmMMtt"))
    return s.form([], ["A", "B"])


@song
def pop():
    """E minor, 4/4, 150 BPM: the octopus of the storm around the lamp. A driving ostinato of short strings, brass stabs, timpani, an orchestra
    hit on the bar, a flute shrieking the tune an octave up over the brass in the second half."""
    s = Song("pop", 150, "E minor", about="the boss")
    s.track("str", 0, 49, 90, -0.2, 40).track("brass", 1, 61, 88, 0.25, 40).track("tp", 2, 56, 92, 0.1, 40).track("timp", 3, 47, 104, 0, 30)
    s.track("orch", 4, 55, 74, 0, 40).track("bass", 5, 32, 112, 0, 20).track("kit", 9, 0, 104)
    p = [("Em", 16), ("C", 16), ("Am", 16), ("B7", 16)] * 2
    tune = bars("E5:4 G5:4 B5:6 A5:2", "G5:4 E5:4 C5:8", "A4:4 C5:4 E5:6 D5:2", "D#5:12 B4:4",
                "E5:4 G5:4 B5:4 E6:4", "D6:4 C6:4 G5:8", "A5:4 C6:4 B5:4 A5:4", "B5:12 r:4")
    st = arp(p, [0, 0, 1, 0, 2, 0, 1, 0], "E3", "B4", 1, 3)
    s.part("A", 8, str=st, orch=" | ".join(["E3+B3:2> r:14", "C3+G3:2> r:14", "A2+E3:2> r:14", "B2+F#3:2> r:14"] * 2) + " |",
           bass=bassline(p, "R:2 R:2 O:2 R:2 R:2 R:2 O:2 R:2", "E1"), timp=" | ".join(["E2:2 r:6 E2:2 r:6", "C2:2 r:6 C2:2 r:6", "A1:2 r:6 A1:2 r:6", "B1:2 r:6 B1:2 r:6"] * 2) + " |",
           kit=rep("k.k.s..kk.k.s...", 8, "k.k.s..ks.s.SSSS"))
    s.part("B", 8, str=st, tp=tune, brass=comp(p, "x..x..x.x..x....", "E3", "B4"),
           bass=bassline(p, "R:2 R:2 O:2 R:2 R:2 R:2 O:2 R:2", "E1"), timp=" | ".join(["E2:2 r:14", "C2:2 r:14", "A1:2 r:14", "B1:2 r:14"] * 2) + " |",
           kit=rep("c.k.s..kk.k.s...", 8, "k.k.s..kffmmMMtt"))
    return s.form([], ["A", "B"])


# ------------------------------------------------------------------ jingles

@song
def planta():
    """D major, 96 BPM, 4 s: a floor done, the ánimas gone to sea. A flute and a glockenspiel rising, a bell, a held chord."""
    s = jingle("planta", 96, "D major", about="floor clear")
    s.track("fl", 0, 73, 96, -0.1, 70).track("glock", 1, 9, 80, 0.3, 80).track("str", 2, 48, 66, 0, 70).track("bell", 3, 14, 76, 0.1, 90)
    tune = "A4:2 D5:2 F#5:2 A5:2 G5:2 F#5:2 E5:2 F#5:2 | D6:12 r:4 |"
    s.part("a", 2, fl=tune, glock=transpose(tune, 12), str=comp([("D", 8), ("A", 8), ("D", 16)], "x-------", "A3", "F#5"), bell="r:16 | D5:12 r:4 |")
    return s.form(["a"], [])


@song
def helada():
    """D minor, 60 BPM, 5 s: the cold took her, the lantern goes out. A music box falling, low strings, a bell."""
    s = jingle("helada", 60, "D minor", about="lantern out")
    s.track("mb", 0, 10, 100, -0.1, 80).track("str", 1, 48, 66, -0.3, 70).track("bell", 2, 14, 84, 0.2, 90)
    s.part("a", 2, mb="A5:4 F5:4 E5:4 D5:4 | C#5:4 A4:4 D4:8 |", str=comp([("Dm", 8), ("Gm", 8), ("A", 8), ("Dm", 8)], "x-------", "A2", "F4"),
           bell="D4:16 | A3:16 |")
    return s.form(["a"], [])


LEVELS: dict[str, float] = {"titulo": 1.0, "fin": 1.0, "torre": 1.05, "maquina": 1.0, "tormenta": 0.8, "pop": 0.75, "planta": 1.0, "helada": 1.1}


def make(name: str) -> Song:
    s = SONGS[name]()
    s.master = LEVELS.get(name, 1.0)
    return s


def main(argv: list[str]) -> None:
    if "--check" in argv:
        from music_check import check_all
        i = argv.index("--check")
        check_all(Path(argv[i + 1]), [a for a in argv[i + 2:] if not a.startswith("-")] or list(SONGS), make)
        return
    audio = GAME / "audio"
    audio.mkdir(exist_ok=True)
    if "--bank" in argv or not (audio / "BANK.bank").exists():
        from music_bank import build_bank
        path, size = build_bank()
        print(f"{path}: {size // 1024} KB")
    for name in [a for a in argv if not a.startswith("-")] or list(SONGS):
        s = make(name)
        info = write_smf(s, audio / f"{name}.mid")
        intro = s.seconds(info["loop_start"]) if not s.jingle else s.seconds(info["music_end"])
        body = s.seconds(info["loop_end"] - info["loop_start"]) if not s.jingle else 0.0
        print(f"{name:10} {s.key:20} {s.beats}/4 {s.bpm:4.0f} BPM  intro {intro:5.1f} s  loop {body:5.1f} s  {s.about}")


if __name__ == "__main__":
    main(sys.argv[1:])
