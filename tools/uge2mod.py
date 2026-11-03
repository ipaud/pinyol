#!/usr/bin/env python3
"""A hUGETracker song (.uge, versions 3 to 6) as a ProTracker module the console plays with music():
    python3 tools/uge2mod.py song.uge games/mygame/audio/SONG.mod
The Game Boy's four channels go to the module's four: Duty 1, Duty 2, Wave and Noise. A duty instrument becomes a one-period
sample of its duty (12.5, 25, 50 or 75 %), a wave instrument its 32-step wave, the noise a burst of noise (short and metallic
in 7-bit mode). A module's periods span three octaves and hUGETracker's notes six (hUGETracker's C3 to C9, 65 Hz to 4 kHz), so each sample is made in two
lengths three octaves apart (64 and 8 bytes a period for the duties, 128 and 16 for the waves) and a note takes the one it fits. The speed is the song's ticks per row at
a tempo of 150 (a tick a frame, 60 a second); an instrument's volume envelope and its length are followed row by row with
volume commands. The wave channel sounds an octave lower than the duty ones for the same note, as on the Game Boy (hUGEDriver
uses one table of periods for all three). Effects kept: 0xy 1xx 2xx 3xx 4xy Axy Bxx Cxx Dxx Exx (note cut) Fxx; the others
(master volume, routines, note delay, panning, duty change) are left out (ponytail: add them when a song needs them).
Instruments' subpatterns (v6) are left out too. The format: hUGETracker's manual, "UGE format".
"""
from __future__ import annotations

import argparse
import math
import struct
from pathlib import Path

# ProTracker periods, C-1 to B-3 (36 notes). A sample of 32 bytes a period at period 428 (C-2) sounds 259 Hz: C4.
PERIODS = [856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453, 428, 404, 381, 360, 339, 320, 302, 285, 269, 254,
           240, 226, 214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113]
DUTIES = [0.125, 0.25, 0.5, 0.75]
# bytes a period, longest (most detail) first: two lengths each, three octaves apart, hold every note of the song (a module has 31
# samples: four duties and the waves twice)
DUTY_LENGTHS = (64, 8)  # notes 0 to 71
WAVE_LENGTHS = (128, 16)  # the wave channel's notes, an octave down: -12 to 59
EMPTY = 90  # a row without a note
ROWS = 64


class Reader:
    def __init__(self, data: bytes):
        self.d, self.p = data, 0

    def take(self, n: int) -> bytes:
        if self.p + n > len(self.d):
            raise SystemExit(f"uge2mod: the file ends at byte {len(self.d)}, {self.p + n} expected (not a .uge, or a version this does not read)")
        b = self.d[self.p:self.p + n]
        self.p += n
        return b

    def u8(self) -> int: return self.take(1)[0]
    def u32(self) -> int: return struct.unpack("<I", self.take(4))[0]
    def short(self) -> str:
        b = self.take(256)
        return b[1:1 + b[0]].decode("latin-1")


def base_note(length: int) -> int:
    """the song note (0: hUGETracker's lowest, 65 Hz) that period index 0 (C-1) plays with a sample of `length` bytes a period: 32 bytes
    at period 428 (index 12) sound 259 Hz, note 24, so index 0 is note 12; each halving of the sample an octave up"""
    return 12 - 12 * round(math.log2(length / 32))


def place(note: int, lengths: tuple[int, ...]) -> tuple[int, int]:
    """(sample length, period index) for a song note: the longest sample whose three octaves hold it, else the nearest end"""
    for length in lengths:
        i = note - base_note(length)
        if 0 <= i < len(PERIODS):
            return length, i
    return (lengths[0], 0) if note < base_note(lengths[0]) else (lengths[-1], len(PERIODS) - 1)


def subpattern(r: Reader) -> None:
    if r.u8():  # enabled or not, its 64 rows are there
        pass
    r.take(64 * 17)


def read_instruments(r: Reader, version: int, kind: int) -> list[dict]:
    out = []
    for _ in range(15):
        r.u32()  # type
        inst = {"name": r.short(), "length": r.u32(), "length_on": bool(r.u8())}
        inst["volume"] = r.u8()
        inst["sweep_down"] = r.u32() == 1
        inst["sweep"] = r.u8()
        r.u32(), r.u32(), r.u32()  # frequency sweep: time, enabled, shift (left out)
        inst["duty"] = r.u8() & 3
        wave_volume, wave_index = r.u32(), r.u32()
        if kind == 1:
            inst["volume"], inst["wave"], inst["sweep"] = (0, 15, 8, 4)[wave_volume & 3], wave_index & 15, 0
        if version < 6:
            r.u32()
        noise_mode = r.u32()
        inst["seven_bit"] = kind == 2 and noise_mode == 1
        if version < 6:
            r.u32()
        else:
            subpattern(r)
        if 4 <= version < 6:
            r.take(6)
        out.append(inst)
    return out


def read(data: bytes) -> dict:
    r = Reader(data)
    version = r.u32()
    if not 3 <= version <= 6:
        raise SystemExit(f"uge2mod: version {version}; this reads hUGETracker's versions 3 to 6")
    song = {"version": version, "name": r.short(), "artist": r.short(), "comment": r.short()}
    song["duty"] = read_instruments(r, version, 0)
    song["wave_inst"] = read_instruments(r, version, 1)
    song["noise"] = read_instruments(r, version, 2)
    song["waves"] = []
    for _ in range(16):
        song["waves"].append(list(r.take(32)))
        if version < 3:
            r.u8()
    song["speed"] = r.u32()
    if version >= 6:
        r.u8(), r.u32()  # timer-based tempo (left out: the rows go at the frame rate)
    patterns = {}
    for _ in range(r.u32()):
        index, rows = r.u32(), []
        for _ in range(ROWS):
            note, inst = r.u32(), r.u32()
            if version >= 6:
                r.u32()
            rows.append((note, inst, r.u32(), r.u8()))
        patterns[index] = rows
    song["patterns"], song["orders"] = patterns, []
    for _ in range(4):
        n = r.u32() - 1
        song["orders"].append([r.u32() for _ in range(max(0, n))])
        r.u32()
    return song


def sample_square(duty: float, length: int) -> bytes:
    return bytes([100 if i / length < duty else 156 for i in range(length)])  # +100 / -100 (signed 8-bit)


def sample_wave(wave: list[int], length: int) -> bytes:
    return bytes([((wave[i * 32 // length] & 15) * 13 - 98) & 255 for i in range(length)])  # nibbles 0..15 -> -98..97


def sample_noise(seven_bit: bool) -> bytes:
    x, out = 0x7FFF, bytearray()  # the Game Boy's LFSR: 15 bits, or 7 (a short, metallic loop)
    for _ in range(127 * 4 if seven_bit else 2048):
        bit = (x ^ (x >> 1)) & 1
        x = (x >> 1) | (bit << 14)
        if seven_bit:
            x = (x & ~0x40) | (bit << 6)
        out.append(100 if x & 1 else 156)
    return bytes(out)


def pt_effect(code: int, param: int) -> tuple[int, int] | None:
    """a hUGETracker effect as ProTracker's, or None when it is left out"""
    if code in (0x0, 0x1, 0x2, 0x3, 0x4, 0xA, 0xB, 0xF):
        return (code, param) if code or param else None
    if code == 0xC:
        return 0xC, min(64, (param & 15) * 4 + (4 if param & 15 == 15 else 0))
    if code == 0xD:
        row = min(63, param)
        return 0xD, (row // 10) << 4 | row % 10  # (ProTracker's row is in decimal digits)
    if code == 0xE:
        return 0xE, 0xC0 | min(15, param)
    return None


def convert(data: bytes) -> bytes:
    song = read(data)
    speed = max(1, min(31, song["speed"]))
    orders = song["orders"]
    length = min(len(o) for o in orders) if all(orders) else max((len(o) for o in orders), default=0)
    if not length:
        raise SystemExit("uge2mod: the song has no orders")
    if length > 128:
        raise SystemExit(f"uge2mod: {length} positions; a module holds 128")
    samples: list[tuple[str, bytes]] = []
    sample_of: dict[str, int] = {}

    def sample(key: str, make) -> int:
        if key not in sample_of:
            if len(samples) == 31:
                raise SystemExit("uge2mod: more than 31 samples (duties, waves and lengths): too many for a module")
            samples.append((key, make()))
            sample_of[key] = len(samples)
        return sample_of[key]

    kinds = [song["duty"], song["duty"], song["wave_inst"], song["noise"]]
    held = [None] * 4  # per channel: the instrument sounding and the frames since its note
    last_inst = [0] * 4
    patterns = []
    for pos in range(length):
        pat = bytearray(ROWS * 16)
        for ch in range(4):
            rows = song["patterns"].get(orders[ch][pos % len(orders[ch])] if orders[ch] else -1, [(EMPTY, 0, 0, 0)] * ROWS)
            for row, (note, inst_no, code, param) in enumerate(rows):
                cell = row * 16 + ch * 4
                vol = None
                if inst_no:
                    last_inst[ch] = inst_no
                if note != EMPTY and 0 <= note <= 72:
                    inst = kinds[ch][(last_inst[ch] or 1) - 1]
                    played = note - 12 if ch == 2 else note  # the wave channel an octave down
                    if ch == 3:
                        played = max(0, min(len(PERIODS) - 1, note // 2))  # noise: its note picks the rate, roughly
                        smp, idx = sample("noise7" if inst["seven_bit"] else "noise", lambda i=inst: sample_noise(i["seven_bit"])), played
                    else:
                        size, idx = place(played, WAVE_LENGTHS if ch == 2 else DUTY_LENGTHS)
                        if ch == 2:
                            w = inst["wave"]
                            smp = sample(f"wave{w}_{size}", lambda w=w, s=size: sample_wave(song["waves"][w], s))
                        else:
                            d = inst["duty"]
                            smp = sample(f"duty{d}_{size}", lambda d=d, s=size: sample_square(DUTIES[d], s))
                    period = PERIODS[idx]
                    pat[cell] = ((smp >> 4) << 4) | (period >> 8)
                    pat[cell + 1] = period & 255
                    pat[cell + 2] = (smp & 15) << 4
                    held[ch] = {"inst": inst, "frames": 0}
                    vol = inst["volume"]
                elif held[ch] is not None:
                    h = held[ch]
                    h["frames"] += speed
                    inst = h["inst"]
                    if inst["length_on"] and h["frames"] >= (64 - inst["length"]) * 60 // 256:
                        held[ch], vol = None, 0
                    elif inst["sweep"]:
                        step = h["frames"] // (inst["sweep"] * 60 // 64 or 1)  # a step every sweep/64 s
                        vol = max(0, min(15, inst["volume"] - step if inst["sweep_down"] else inst["volume"] + step))
                eff = pt_effect(code, param)
                if eff:
                    pat[cell + 2] |= eff[0]
                    pat[cell + 3] = eff[1]
                    if eff[0] == 0xC:
                        held[ch] = None  # the song sets the volume itself from here
                elif vol is not None:
                    pat[cell + 2] |= 0xC
                    pat[cell + 3] = min(64, vol * 4 + (4 if vol == 15 else 0))
        if pos == 0:  # the tempo (a tick a frame) and the speed on the first row, where the song has no effect of its own
            free = [ch for ch in range(4) if pat[ch * 4 + 2] & 15 in (0, 0xC) and not (pat[ch * 4 + 2] & 15 == 0 and pat[ch * 4 + 3])]
            for ch, value in zip(free[-2:], (150, speed)):
                pat[ch * 4 + 2] = (pat[ch * 4 + 2] & 0xF0) | 0xF
                pat[ch * 4 + 3] = value
        patterns.append(pat)
    if not samples:
        samples.append(("duty2_32", sample_square(0.5, 32)))

    header = song["name"].encode("latin-1", "replace")[:20].ljust(20, b"\0")
    for i in range(31):
        if i < len(samples):
            name, data_ = samples[i]
            words = len(data_) // 2
            header += name.encode("ascii", "replace")[:22].ljust(22, b"\0") + struct.pack(">HBBHH", words, 0, 64, 0, words)
        else:
            header += bytes(22) + struct.pack(">HBBHH", 0, 0, 0, 0, 1)
    header += bytes([length, 0]) + bytes(range(length)) + bytes(128 - length) + b"M.K."
    return header + b"".join(bytes(p) for p in patterns) + b"".join(d for _, d in samples)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("uge", type=Path, help="the hUGETracker song")
    ap.add_argument("out", type=Path, help="the module to write (games/<game>/audio/<ID>.mod)")
    a = ap.parse_args()
    data = convert(a.uge.read_bytes())
    a.out.write_bytes(data)
    print(f"{a.out}: {len(data)} bytes")


if __name__ == "__main__":
    main()
