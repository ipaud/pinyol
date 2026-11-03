#!/usr/bin/env python3
"""El Faro de las Ánimas' sounds, made by code (numpy) and kept as the PlayStation's ADPCM (tools/wav2vag.py -> audio/<ID>.vag), plus two beds of
sound streamed from the card (rain and sea, audio/<ID>.spum). The game plays them all through one reverb room (core/sound.lua).

    uv run --with numpy python3 gen/sfx.py          every sound (WAVs in raw/sfx/, then the .vag and .spum)
"""
from __future__ import annotations

import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

RATE = 22050
HERE = Path(__file__).resolve().parent
GAME = HERE.parent
ROOT = GAME.parents[1]
OUT = GAME / "raw" / "sfx"
rng = np.random.default_rng(7)


def t_of(sec: float) -> np.ndarray:
    return np.arange(int(sec * RATE)) / RATE


def env(sec: float, a: float, d: float) -> np.ndarray:
    t = t_of(sec)
    e = np.minimum(1, t / max(a, 1e-4)) * np.exp(-np.maximum(0, t - a) / d)
    fade = np.minimum(1, (sec - t) / 0.01)
    return e * fade


def lowpass(x: np.ndarray, hz: float) -> np.ndarray:
    k = np.exp(-2 * np.pi * hz / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - k) * v + k * acc
        y[i] = acc
    return y


def lowpass_sweep(x: np.ndarray, hz0: float, hz1: float) -> np.ndarray:
    n = len(x)
    hz = np.geomspace(hz0, hz1, n)
    k = np.exp(-2 * np.pi * hz / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(n):
        acc = (1 - k[i]) * x[i] + k[i] * acc
        y[i] = acc
    return y


def noise(sec: float) -> np.ndarray:
    return rng.uniform(-1, 1, int(sec * RATE))


def tone(f, sec: float, shape: str = "sine") -> np.ndarray:
    t = t_of(sec)
    f = np.broadcast_to(np.asarray(f, dtype=float), t.shape) if np.ndim(f) else np.full(t.shape, float(f))
    ph = np.cumsum(f) / RATE
    if shape == "sine":
        return np.sin(2 * np.pi * ph)
    if shape == "tri":
        return 2 * np.abs(2 * (ph % 1) - 1) - 1
    if shape == "saw":
        return 2 * (ph % 1) - 1
    return np.sign(np.sin(2 * np.pi * ph))


def norm(x: np.ndarray, peak: float = 0.85) -> np.ndarray:
    return x * (peak / (np.max(np.abs(x)) or 1))


def mix(*xs: np.ndarray) -> np.ndarray:
    n = max(len(x) for x in xs)
    out = np.zeros(n)
    for x in xs:
        out[:len(x)] += x
    return out


def bell(f: float, sec: float, partials=((1, 1.0), (2.0, 0.5), (3.01, 0.25), (4.2, 0.12))) -> np.ndarray:
    return sum(a * tone(f * r, sec) * env(sec, 0.003, sec / (2 + r)) for r, a in partials)


def sounds() -> dict[str, np.ndarray]:
    s = {}
    s["STEP"] = norm(lowpass(noise(0.09), 900) * env(0.09, 0.002, 0.025), 0.5)
    s["JUMP"] = norm(lowpass_sweep(noise(0.22), 500, 2600) * env(0.22, 0.03, 0.08), 0.5)
    s["LAND"] = norm(mix(lowpass(noise(0.16), 400) * env(0.16, 0.002, 0.04), 0.6 * tone(90, 0.16) * env(0.16, 0.002, 0.05)), 0.6)
    s["LIFT"] = norm(mix(lowpass_sweep(noise(0.5), 300, 3000) * env(0.5, 0.12, 0.18), 0.3 * bell(880, 0.6)), 0.6)
    s["CALM"] = norm(mix(bell(659.3, 1.2), 0.7 * bell(987.8, 1.2), 0.5 * bell(1318.5, 1.0)), 0.55)
    up = [mix(np.zeros(int(0.09 * RATE * i)), bell(f, 1.0)) for i, f in enumerate((587.3, 740.0, 880.0, 1174.7, 1480.0))]
    s["FREE"] = norm(mix(*up), 0.7)
    sec = 1.6
    t = t_of(sec)
    f = 150 * (1 + 0.06 * np.sin(2 * np.pi * 3.2 * t)) * (1 - 0.15 * t / sec)
    moan = tone(f, sec, "tri") * 0.6 + tone(f * 2.01, sec) * 0.25 + lowpass(noise(sec), 700) * 0.4
    s["MOAN"] = norm(lowpass(moan, 1200) * env(sec, 0.35, 0.6), 0.5)
    sec = 0.7
    shimmer = sum(tone(2400 * (1 - 0.5 * t_of(sec) / sec) * r, sec) * a for r, a in ((1, 1), (1.33, 0.6), (1.71, 0.4)))
    s["HURT"] = norm(mix(shimmer * env(sec, 0.005, 0.18) * 0.5, lowpass(noise(sec), 1800) * env(sec, 0.005, 0.12)), 0.6)
    sec = 3.2
    crack = lowpass(noise(sec), 3500) * env(sec, 0.003, 0.08)
    rumble = lowpass(lowpass(noise(sec), 160), 120) * env(sec, 0.25, 1.1) * 9
    s["THUNDER"] = norm(mix(crack * 0.5, rumble), 0.9)
    sec = 2.2
    s["WAVE"] = norm(lowpass_sweep(noise(sec), 300, 1600) * env(sec, 0.6, 0.7), 0.7)
    s["GEAR"] = norm(mix(bell(210, 0.4, ((1, 1), (2.7, 0.6), (5.2, 0.4))), lowpass(noise(0.05), 3000) * 0.6), 0.55)
    sec = 0.9
    creak = tone(180 + 40 * np.sin(2 * np.pi * 7 * t_of(sec)), sec, "saw") * env(sec, 0.1, 0.4) * 0.3
    thunk = mix(np.zeros(int(0.6 * RATE)), lowpass(noise(0.3), 300) * env(0.3, 0.002, 0.06) * 3)
    s["HATCH"] = norm(mix(lowpass(creak, 1500), thunk), 0.7)
    s["OIL"] = norm(mix(tone(np.geomspace(300, 900, int(0.18 * RATE)), 0.18) * env(0.18, 0.005, 0.07),
                        mix(np.zeros(int(0.08 * RATE)), tone(1200, 0.2) * env(0.2, 0.002, 0.06))), 0.5)
    sec = 0.9
    s["SPLASH"] = norm(lowpass_sweep(noise(sec), 4000, 400) * env(sec, 0.005, 0.25), 0.7)
    sec = 0.8
    s["BURNER"] = norm(mix(lowpass_sweep(noise(sec), 200, 2500) * env(sec, 0.05, 0.3), 0.4 * tone(70, sec) * env(sec, 0.02, 0.3)), 0.7)
    sec = 1.6
    t = t_of(sec)
    growl = tone(55 * (1 + 0.1 * np.sin(2 * np.pi * 9 * t)), sec, "saw") * (1 + 0.5 * np.sin(2 * np.pi * 23 * t))
    s["ROAR"] = norm(lowpass(growl, 600) * env(sec, 0.2, 0.7) + lowpass(noise(sec), 400) * env(sec, 0.1, 0.5) * 0.5, 0.8)
    s["SLAM"] = norm(mix(lowpass(noise(0.5), 250) * env(0.5, 0.002, 0.12) * 2, tone(np.geomspace(90, 40, int(0.5 * RATE)), 0.5) * env(0.5, 0.002, 0.15)), 0.85)
    s["INK"] = norm(lowpass_sweep(noise(0.6), 2500, 300) * env(0.6, 0.02, 0.2) * (1 + 0.6 * np.sin(2 * np.pi * 31 * t_of(0.6))), 0.55)
    sec = 2.8
    horn = lowpass(tone(73.4, sec, "saw") + 0.5 * tone(110, sec, "saw"), 700) * np.minimum(1, t_of(sec) / 0.25) * np.minimum(1, (sec - t_of(sec)) / 0.6)
    s["HORN"] = norm(horn, 0.8)
    s["LAMP"] = norm(mix(*[bell(f, 2.5) for f in (293.7, 440.0, 587.3, 740.0, 880.0)], lowpass_sweep(noise(1.2), 200, 3000) * env(1.2, 0.3, 0.4) * 0.6), 0.8)
    s["BLIP"] = norm(tone(880, 0.07, "tri") * env(0.07, 0.002, 0.03), 0.4)
    s["OK"] = norm(mix(tone(660, 0.18, "tri") * env(0.18, 0.002, 0.08), mix(np.zeros(int(0.06 * RATE)), tone(990, 0.2, "tri") * env(0.2, 0.002, 0.08))), 0.45)
    return s


def beds() -> dict[str, np.ndarray]:
    """Rain and sea, 8 seconds each, made to loop: the end crossfaded into the start."""
    b = {}
    sec, fade = 8.0, 1.0
    n = int(sec * RATE)
    f = int(fade * RATE)
    hiss = lowpass(noise(sec + fade), 5000) - lowpass(noise(sec + fade), 600) * 0.3
    drops = np.zeros(n + f)
    for i in rng.integers(0, n + f - 400, 900):
        drops[i:i + 300] += np.exp(-np.arange(300) / 40) * rng.uniform(-1, 1) * 0.6
    rain = hiss * 0.5 + lowpass(drops, 3000)
    b["RAIN"] = loop_of(rain, n, f)
    t = np.arange(n + f) / RATE
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * t / 4.0) ** 2
    sea = lowpass(lowpass(noise(sec + fade), 500), 400) * swell * 4
    b["SEA"] = loop_of(sea, n, f)
    return {k: norm(v, 0.5) for k, v in b.items()}


def loop_of(x: np.ndarray, n: int, f: int) -> np.ndarray:
    out = x[:n].copy()
    k = np.linspace(0, 1, f)
    out[:f] = out[:f] * k + x[n:n + f] * (1 - k)
    return out


def write(path: Path, x: np.ndarray) -> None:
    pcm = np.clip(np.round(x * 32767), -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    tool = ROOT / "tools" / "wav2vag.py"
    for name, x in sounds().items():
        p = OUT / f"{name}.wav"
        write(p, x)
        subprocess.run([sys.executable, str(tool), str(p), str(GAME), f"SFX_{name}"], check=True, capture_output=True)
    for name, x in beds().items():
        p = OUT / f"{name}.wav"
        write(p, x)
        subprocess.run([sys.executable, str(tool), str(p), str(GAME), f"AMB_{name}", "--stream", "--loop", "0"], check=True, capture_output=True)
    print("made", ", ".join(sorted(p.name for p in (GAME / "audio").glob("*.vag"))))


if __name__ == "__main__":
    main()
