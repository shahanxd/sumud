"""SUMUD audio generator: every sound in game/assets/audio, synthesised from nothing.

No recordings, no downloads, no AI, no instruments. Everything here is world sound built
from noise, impulses, resonances and envelopes: wind, sea, machines, impacts, cloth, paper,
birds. The generator is deterministic (one fixed seed per sound), so a regenerated folder
is byte-identical and the WAVs can be treated as build output.

Usage, from the repository root:
    .venv/bin/python tools/audio.py            # writes game/assets/audio/*.wav and README.md
    .venv/bin/python tools/audio.py --check    # reloads every file and asserts the contract
    .venv/bin/python tools/audio.py --only strike_bang drone_hum_loop

Loops: a loop is synthesised as an exactly periodic signal of N frames (spectral filtering
is circular, envelopes have whole cycles, events wrap modulo N, recursive filters run
twice so their state is periodic). The file holds N + 1 frames, the last a copy of the
first, and a `smpl` chunk with loop begin 0 and end N. Godot 4.7 reads the chunk under
its default "Detect From WAV" import setting and plays frames (begin, end] per period,
so the seam is sample-exact without touching any .import file.
"""
from __future__ import annotations

import argparse
import math
import os
import struct
import sys

import numpy as np
from scipy import signal

SR = 48000
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets", "audio")
OUT_DIR = os.path.normpath(OUT_DIR)


# --------------------------------------------------------------------------------------
# Small DSP toolkit
# --------------------------------------------------------------------------------------

def db(x: float) -> float:
    """dB to linear amplitude."""
    return 10.0 ** (x / 20.0)


def to_db(a: float) -> float:
    return 20.0 * math.log10(max(a, 1e-12))


def seconds(n: float) -> int:
    return int(round(n * SR))


def t_axis(n: int) -> np.ndarray:
    return np.arange(n) / SR


def rms(x: np.ndarray) -> float:
    return float(np.sqrt(np.mean(np.square(x)))) if x.size else 0.0


def peak(x: np.ndarray) -> float:
    return float(np.max(np.abs(x))) if x.size else 0.0


def white(rng: np.random.Generator, n: int) -> np.ndarray:
    return rng.standard_normal(n).astype(np.float64)


def spectral(x: np.ndarray, gain) -> np.ndarray:
    """Circular (periodic) filtering: multiplies the spectrum by gain(f). `gain` is a
    callable taking the frequency axis in Hz, or an array of that length. Because the
    convolution is circular, the output of a loop stays exactly periodic."""
    n = x.shape[0]
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1.0 / SR)
    g = gain(f) if callable(gain) else gain
    return np.fft.irfft(spec * g, n)


def coloured(rng: np.random.Generator, n: int, slope: float = -1.0, floor_hz: float = 20.0) -> np.ndarray:
    """Noise with a power spectrum of f^slope (slope -1 is pink, -2 is brown), unit RMS.
    Built in the spectrum so a loop-length request is periodic."""
    def gain(f):
        ff = np.maximum(f, floor_hz)
        g = ff ** (slope / 2.0)
        g[0] = 0.0
        return g
    x = spectral(white(rng, n), gain)
    return x / (rms(x) + 1e-12)


def band(x: np.ndarray, lo: float | None, hi: float | None, order: int = 4, zero_phase: bool = False) -> np.ndarray:
    """Butterworth band/low/high-pass with sos, applied once (causal) or twice (zero phase)."""
    nyq = SR * 0.5
    if lo is not None and hi is not None:
        sos = signal.butter(order, [max(lo, 1.0) / nyq, min(hi, nyq * 0.999) / nyq], btype="band", output="sos")
    elif lo is not None:
        sos = signal.butter(order, max(lo, 1.0) / nyq, btype="high", output="sos")
    else:
        sos = signal.butter(order, min(hi, nyq * 0.999) / nyq, btype="low", output="sos")
    return signal.sosfiltfilt(sos, x) if zero_phase else signal.sosfilt(sos, x)


def spectral_band(x: np.ndarray, lo: float, hi: float, order: float = 4.0) -> np.ndarray:
    """Periodic-safe band-pass with Butterworth-like skirts, done in the spectrum."""
    def gain(f):
        fl = np.maximum(f, 1e-3)
        g = np.ones_like(fl)
        if lo > 0:
            g *= 1.0 / np.sqrt(1.0 + (lo / fl) ** (2 * order))
        if hi > 0:
            g *= 1.0 / np.sqrt(1.0 + (fl / hi) ** (2 * order))
        g[0] = 0.0
        return g
    return spectral(x, gain)


def resonator_sos(f0: float, q: float, kind: str = "bandpass", gain_db: float = 0.0) -> np.ndarray:
    """RBJ cookbook biquad as one sos row. kind: bandpass (constant peak gain), lowpass,
    highpass, peaking."""
    w0 = 2.0 * math.pi * min(max(f0, 1.0), SR * 0.49) / SR
    alpha = math.sin(w0) / (2.0 * max(q, 0.05))
    cw = math.cos(w0)
    if kind == "bandpass":
        b = [alpha, 0.0, -alpha]
        a = [1.0 + alpha, -2.0 * cw, 1.0 - alpha]
    elif kind == "lowpass":
        b = [(1 - cw) / 2, 1 - cw, (1 - cw) / 2]
        a = [1.0 + alpha, -2.0 * cw, 1.0 - alpha]
    elif kind == "highpass":
        b = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2]
        a = [1.0 + alpha, -2.0 * cw, 1.0 - alpha]
    elif kind == "peaking":
        A = 10.0 ** (gain_db / 40.0)
        b = [1 + alpha * A, -2 * cw, 1 - alpha * A]
        a = [1 + alpha / A, -2 * cw, 1 - alpha / A]
    else:
        raise ValueError(kind)
    a0 = a[0]
    return np.array([[b[0] / a0, b[1] / a0, b[2] / a0, 1.0, a[1] / a0, a[2] / a0]])


def resonate(x: np.ndarray, f0: float, q: float, kind: str = "bandpass", gain_db: float = 0.0) -> np.ndarray:
    return signal.sosfilt(resonator_sos(f0, q, kind, gain_db), x)


def tv_filter(x: np.ndarray, f_track: np.ndarray, q, kind: str = "lowpass", block: int = 32) -> np.ndarray:
    """Time-varying biquad: the cutoff (and optionally Q) follow arrays sampled per
    frame; coefficients are updated every `block` frames with the state carried over."""
    n = x.shape[0]
    y = np.empty_like(x)
    zi = np.zeros((1, 2))
    q_arr = q if isinstance(q, np.ndarray) else None
    q_val = float(q) if q_arr is None else 1.0
    for i in range(0, n, block):
        j = min(n, i + block)
        f0 = float(f_track[i])
        qq = float(q_arr[i]) if q_arr is not None else q_val
        sos = resonator_sos(f0, qq, kind)
        y[i:j], zi = signal.sosfilt(sos, x[i:j], zi=zi)
    return y


def loop_twice(fn, x: np.ndarray) -> np.ndarray:
    """Runs a causal filter over two copies of a periodic signal and keeps the second, so
    the filter state at the seam matches. `fn` takes and returns one channel."""
    n = x.shape[0]
    return fn(np.concatenate([x, x]))[n:]


def env_ad(n: int, attack: float, decay: float, curve: float = 1.0) -> np.ndarray:
    """Attack (linear, seconds) then exponential decay with time constant `decay`."""
    t = t_axis(n)
    a = np.clip(t / max(attack, 1e-5), 0.0, 1.0) ** curve
    d = np.exp(-np.maximum(t - attack, 0.0) / max(decay, 1e-5))
    return a * d


def env_points(n: int, points: list[tuple[float, float]]) -> np.ndarray:
    """Piecewise-linear envelope from (time, value) pairs."""
    t = t_axis(n)
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return np.interp(t, xs, ys)


def smooth(x: np.ndarray, hz: float, periodic: bool = False) -> np.ndarray:
    """Low-passes a control signal (one-pole equivalent, zero phase)."""
    if periodic:
        return spectral(x, lambda f: 1.0 / np.sqrt(1.0 + (f / hz) ** 4))
    return band(x, None, hz, order=2, zero_phase=True)


def periodic_lfo(rng: np.random.Generator, n: int, f_lo: float, f_hi: float, count: int = 6) -> np.ndarray:
    """Slow random modulation with whole cycles in n frames, so a loop stays periodic.
    Zero mean, unit peak."""
    dur = n / SR
    t = t_axis(n)
    out = np.zeros(n)
    k_lo = max(1, int(math.floor(f_lo * dur)))
    k_hi = max(k_lo, int(math.ceil(f_hi * dur)))
    for _ in range(count):
        k = int(rng.integers(k_lo, k_hi + 1))
        out += rng.uniform(0.4, 1.0) * np.sin(2.0 * math.pi * (k / dur) * t + rng.uniform(0, 2 * math.pi))
    return out / (peak(out) + 1e-12)


def unit(x: np.ndarray) -> np.ndarray:
    """Maps a zero-mean, unit-peak modulation to [0, 1]."""
    return 0.5 * (x + 1.0)


def fade(x: np.ndarray, ms_in: float = 5.0, ms_out: float = 5.0) -> np.ndarray:
    """Raised-cosine fades at both ends (one-shots only; never on a loop)."""
    n = x.shape[0]
    y = x.copy()
    a = min(n // 2, seconds(ms_in / 1000.0))
    b = min(n // 2, seconds(ms_out / 1000.0))
    if a > 0:
        w = 0.5 - 0.5 * np.cos(np.linspace(0, math.pi, a))
        y[:a] = (y[:a].T * w).T
    if b > 0:
        w = 0.5 - 0.5 * np.cos(np.linspace(math.pi, 0, b))
        y[-b:] = (y[-b:].T * w).T
    return y


def soft_clip(x: np.ndarray, drive: float = 1.0) -> np.ndarray:
    return np.tanh(x * drive) / math.tanh(drive)


def place(dst: np.ndarray, grain: np.ndarray, at: int, wrap: bool = False) -> None:
    """Adds `grain` into `dst` starting at frame `at`; wraps modulo the length for loops.
    Works for mono (n,) and stereo (n, 2) with a matching grain."""
    n = dst.shape[0]
    g = grain.shape[0]
    if wrap:
        idx = (np.arange(g) + at) % n
        np.add.at(dst, idx, grain)
        return
    if at >= n or at + g <= 0:
        return
    s = max(0, -at)
    e = min(g, n - at)
    dst[at + s:at + e] += grain[s:e]


def pan(x: np.ndarray, p: float) -> np.ndarray:
    """Constant-power pan of a mono signal; p in [-1, 1]."""
    a = (p + 1.0) * 0.25 * math.pi
    return np.stack([x * math.cos(a), x * math.sin(a)], axis=1)


def stereo(l: np.ndarray, r: np.ndarray) -> np.ndarray:
    return np.stack([l, r], axis=1)


def ping(rng: np.random.Generator, f0: float, decay: float, dur: float, q: float = 12.0, noise: float = 0.6) -> np.ndarray:
    """A tiny noise-excited resonance: an impulse plus a puff of noise through a bandpass,
    decaying exponentially. This is a pebble, a shard, a grain, a click; never a note."""
    n = max(8, seconds(dur))
    exc = np.zeros(n)
    exc[0] = 1.0
    puff = min(n, max(4, seconds(0.0015)))
    exc[:puff] += noise * white(rng, puff) * np.linspace(1.0, 0.0, puff)
    y = resonate(exc, f0, q)
    return y * np.exp(-t_axis(n) / max(decay, 1e-4))


def street_ir(rng: np.random.Generator, length: float, rt_low: float, rt_high: float, early: list[tuple[float, float]] | None = None) -> np.ndarray:
    """A synthetic impulse response of a narrow concrete street: frequency-dependent decay
    (lows ring, highs die fast) plus discrete slaps off the facades. Mono; call twice with
    different seeds for a decorrelated pair."""
    n = seconds(length)
    t = t_axis(n)
    ir = np.zeros(n)
    bands = [(20, 120, rt_low), (120, 400, rt_low * 0.8), (400, 1500, (rt_low + rt_high) * 0.5), (1500, 5000, rt_high), (5000, 16000, rt_high * 0.6)]
    for lo, hi, rt in bands:
        tau = rt / 6.91  # RT60 to time constant
        ir += band(white(rng, n), lo, hi, order=2) * np.exp(-t / tau)
    ir *= np.clip(t / 0.004, 0, 1)  # the direct sound is the dry signal, not the IR
    for delay, gain in (early or []):
        k = seconds(delay)
        if k < n:
            slap = band(white(rng, seconds(0.006)), 300, 6000, order=2) * np.exp(-t_axis(seconds(0.006)) / 0.0015)
            place(ir, slap * gain, k)
    return ir / (np.sqrt(np.sum(ir ** 2)) + 1e-12)


def convolve(x: np.ndarray, ir: np.ndarray) -> np.ndarray:
    return signal.fftconvolve(x, ir)[: x.shape[0]]


def normalise_peak(x: np.ndarray, target_db: float) -> np.ndarray:
    return x * (db(target_db) / (peak(x) + 1e-12))


def normalise_rms(x: np.ndarray, target_db: float, ceiling_db: float = -1.0) -> np.ndarray:
    """Sets the RMS over all channels; if the crest factor would push the peak over the
    ceiling, soft-limits the loudest moments a little and re-measures."""
    y = x * (db(target_db) / (rms(x) + 1e-12))
    if peak(y) > db(ceiling_db):
        over = peak(y) / db(ceiling_db)
        y = soft_clip(y / over * 0.98, drive=1.0 + 0.6 * over) * db(ceiling_db)
        y = y * (db(target_db) / (rms(y) + 1e-12))
        if peak(y) > db(ceiling_db):
            y = y * (db(ceiling_db) / peak(y))
    return y


# --------------------------------------------------------------------------------------
# WAV writing and reading (16-bit PCM, optional smpl loop chunk)
# --------------------------------------------------------------------------------------

def write_wav(path: str, x: np.ndarray, loop: bool, rng: np.random.Generator) -> None:
    """Writes 16-bit PCM at SR with TPDF dither. For a loop of N frames the file holds
    N + 1 frames (the last equals the first) and a smpl chunk looping (0, N]."""
    if x.ndim == 1:
        x = x[:, None]
    x = np.asarray(x, dtype=np.float64)
    if loop:
        x = np.concatenate([x, x[:1]], axis=0)
    frames, channels = x.shape
    dither = (rng.random(x.shape) + rng.random(x.shape) - 1.0) / 32768.0
    pcm = np.clip(np.round((x + dither) * 32767.0), -32768, 32767).astype("<i2")
    data = pcm.tobytes()
    fmt = struct.pack("<HHIIHH", 1, channels, SR, SR * channels * 2, channels * 2, 16)
    chunks = [b"fmt " + struct.pack("<I", len(fmt)) + fmt, b"data" + struct.pack("<I", len(data)) + data]
    if loop:
        n_loop = frames - 1
        smpl = struct.pack("<IIIIIIIII", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<IIIIII", 0, 0, 0, n_loop, 0, 0)
        chunks.append(b"smpl" + struct.pack("<I", len(smpl)) + smpl)
    body = b"WAVE" + b"".join(chunks)
    with open(path, "wb") as fh:
        fh.write(b"RIFF" + struct.pack("<I", len(body)) + body)


def read_wav(path: str) -> dict:
    """Reads back a PCM WAV: samples as float in [-1, 1), rate, bits, channels, loop points."""
    with open(path, "rb") as fh:
        raw = fh.read()
    assert raw[:4] == b"RIFF" and raw[8:12] == b"WAVE", path
    pos = 12
    info = {"loop": None}
    while pos + 8 <= len(raw):
        cid = raw[pos:pos + 4]
        size = struct.unpack("<I", raw[pos + 4:pos + 8])[0]
        body = raw[pos + 8:pos + 8 + size]
        if cid == b"fmt ":
            fmt_tag, ch, rate, _, _, bits = struct.unpack("<HHIIHH", body[:16])
            info.update(format=fmt_tag, channels=ch, rate=rate, bits=bits)
        elif cid == b"data":
            info["raw"] = body
        elif cid == b"smpl":
            n_loops = struct.unpack("<I", body[28:32])[0]
            if n_loops >= 1:
                _, ltype, start, end, _, _ = struct.unpack("<IIIIII", body[36:60])
                info["loop"] = (ltype, start, end)
        pos += 8 + size + (size & 1)
    pcm = np.frombuffer(info["raw"], dtype="<i2").astype(np.float64) / 32768.0
    info["samples"] = pcm.reshape(-1, info["channels"])
    return info


# --------------------------------------------------------------------------------------
# The strike
# --------------------------------------------------------------------------------------

def strike_bang(rng: np.random.Generator) -> np.ndarray:
    """One real, close, ugly impact. Layers, in the order the ear meets them: 20 ms of
    nothing; the shock front (a single asymmetric pressure pulse, full band, 2 ms); the
    crack (a burst of white noise, 12 ms, high-passed, hard-limited like an overloaded
    microphone); the sub thump (a sine falling 60 to 35 Hz with a 1.5 ms attack and a
    0.5 s decay, saturated); the body (brown noise through a low-pass that sweeps from
    4 kHz down to 90 Hz over 1.6 s); the street answering (two decorrelated concrete
    street impulse responses with facade slaps at 31, 47, 74 and 118 ms); then the
    debris: a Poisson rain of noise-excited resonant grains (concrete, glass, grit)
    whose rate decays from 260 to 3 per second across 2.8 s, a few heavier rubble falls,
    and pouring dust as high-passed noise with a long decay."""
    dur = 6.0
    n = seconds(dur)
    t = t_axis(n)
    pre = seconds(0.020)
    out = np.zeros((n, 2))

    # Shock front: an N-wave, positive spike then a slower negative trough.
    front = np.zeros(n)
    k = seconds(0.0025)
    front[pre:pre + k] = np.linspace(1.0, -0.6, k)
    front[pre + k:pre + 4 * k] = np.linspace(-0.6, 0.0, 3 * k)
    front = band(front, 25, None, order=1)

    # Crack.
    ck = seconds(0.014)
    crack_l = white(rng, ck) * np.exp(-t_axis(ck) / 0.0035)
    crack_r = 0.6 * crack_l + 0.8 * white(rng, ck) * np.exp(-t_axis(ck) / 0.0035)
    crack = np.zeros((n, 2))
    crack[pre:pre + ck, 0] = band(crack_l, 900, None, order=2)
    crack[pre:pre + ck, 1] = band(crack_r, 900, None, order=2)
    crack = soft_clip(crack * 3.0, drive=2.5)

    # Sub thump: falling sine, sharp, saturated; a second, lower pulse a few ms later
    # (the ground shock arrives through the floor).
    ts = t - pre / SR
    f_sub = 60.0 * np.exp(-np.maximum(ts, 0) / 0.18) + 35.0 * (1 - np.exp(-np.maximum(ts, 0) / 0.18))
    phase = 2 * np.pi * np.cumsum(f_sub) / SR
    sub = np.sin(phase) * env_ad(n, 0.0015, 0.5)
    sub = np.roll(sub, pre)
    sub[:pre] = 0.0
    floor_k = seconds(0.011)
    ground = np.sin(2 * np.pi * 28.0 * t) * env_ad(n, 0.004, 0.42)
    ground = np.roll(ground, pre + floor_k)
    ground[:pre + floor_k] = 0.0
    sub = soft_clip(1.6 * sub + 0.7 * ground, drive=1.8)

    # Body: brown noise, low-pass sweeping down, exponential decay.
    body_env = env_ad(n, 0.003, 0.55)
    fc = 4000.0 * np.exp(-np.maximum(ts, 0) / 0.45) + 90.0
    body = np.zeros((n, 2))
    for c in range(2):
        src = coloured(rng, n, slope=-1.6) * body_env
        src = tv_filter(src, fc, 0.7, kind="lowpass")
        body[:, c] = np.roll(src, pre)
        body[:pre, c] = 0.0
    body = soft_clip(body * 2.2, drive=2.0)

    # Debris rain.
    debris = np.zeros((n, 2))
    t0 = pre / SR + 0.06
    tt = t0
    while tt < dur - 0.3:
        age = tt - t0
        rate = 3.0 + 257.0 * math.exp(-age / 0.55)
        tt += rng.exponential(1.0 / rate)
        kind = rng.random()
        if kind < 0.55:   # concrete chips
            f0, q, decay, d = rng.uniform(700, 2600), rng.uniform(6, 14), rng.uniform(0.004, 0.02), 0.05
        elif kind < 0.85:  # grit and gravel
            f0, q, decay, d = rng.uniform(2500, 7000), rng.uniform(3, 8), rng.uniform(0.002, 0.008), 0.02
        else:              # glass shards
            f0, q, decay, d = rng.uniform(3500, 9500), rng.uniform(14, 30), rng.uniform(0.01, 0.045), 0.08
        g = ping(rng, f0, decay, d, q=q, noise=0.8)
        amp = rng.uniform(0.15, 1.0) * (0.35 + 0.65 * math.exp(-age / 1.2))
        place(debris, pan(g * amp, rng.uniform(-0.9, 0.9)), seconds(tt))
    # Heavier rubble: a handful of dull falls in the first two seconds.
    for _ in range(9):
        tt = t0 + rng.uniform(0.12, 2.2)
        d = seconds(rng.uniform(0.06, 0.16))
        thud = band(white(rng, d), 70, rng.uniform(220, 520), order=2) * np.exp(-t_axis(d) / rng.uniform(0.02, 0.05))
        thud = soft_clip(thud * 2.0, 1.5) * rng.uniform(0.3, 0.8) * math.exp(-(tt - t0) / 1.4)
        place(debris, pan(thud, rng.uniform(-0.7, 0.7)), seconds(tt))
    debris = normalise_peak(debris, -6.0)

    # Dust pouring: a hiss that swells just after the bang and dies over three seconds.
    dust = np.zeros((n, 2))
    dust_env = env_points(n, [(0, 0), (t0, 0), (t0 + 0.25, 1.0), (t0 + 1.2, 0.5), (t0 + 3.2, 0.08), (dur - 0.2, 0.0), (dur, 0.0)])
    for c in range(2):
        dust[:, c] = band(white(rng, n), 1800, 11000, order=2) * dust_env * (0.7 + 0.3 * unit(smooth(white(rng, n), 12.0)))
    dust = normalise_peak(dust, -22.0)

    # Mix the dry impact, then send it through the street.
    dry = np.zeros((n, 2))
    dry[:, 0] = 0.9 * front + 1.0 * sub
    dry[:, 1] = 0.9 * front + 1.0 * sub
    dry += 0.55 * crack + 0.8 * body
    ir_l = street_ir(rng, 2.6, rt_low=2.2, rt_high=0.9, early=[(0.031, 0.5), (0.047, 0.35), (0.074, 0.3), (0.118, 0.2)])
    ir_r = street_ir(rng, 2.6, rt_low=2.2, rt_high=0.9, early=[(0.029, 0.4), (0.052, 0.35), (0.081, 0.25), (0.126, 0.2)])
    wet = np.zeros((n, 2))
    wet[:, 0] = convolve(dry[:, 0], ir_l)
    wet[:, 1] = convolve(dry[:, 1], ir_r)
    wet = normalise_peak(wet, -10.0)
    dry = soft_clip(dry, drive=1.3)
    dry = normalise_peak(dry, -1.0)

    out = dry + wet + debris + dust
    out[:pre] = 0.0
    out = soft_clip(out, drive=1.15)
    out = fade(normalise_peak(out, -1.0), 0.0, 40.0)
    out[:pre] = 0.0
    return out


def ringing(rng: np.random.Generator) -> np.ndarray:
    """The tinnitus after the bang: white noise through a narrow band around 3.8 kHz
    (Q 28, centre wandering 3.72 to 3.88 kHz), a weaker second band near 5.3 kHz so
    it is not one pitch, a breath of very quiet hiss, all fading over eight seconds."""
    dur = 8.0
    n = seconds(dur)
    t = t_axis(n)
    wander = 3800.0 + 80.0 * smooth(white(rng, n), 0.35) / 0.35
    wander = np.clip(wander, 3700.0, 3900.0)
    main = tv_filter(white(rng, n), wander, 28.0, kind="bandpass")
    main = tv_filter(main, wander, 28.0, kind="bandpass")
    second = resonate(resonate(white(rng, n), 5300.0, 22.0), 5300.0, 22.0) * db(-12.0)
    hiss = band(white(rng, n), 6000, 14000, order=2) * db(-30.0)
    core = main / (rms(main) + 1e-12) + second / (rms(second) + 1e-12) * db(-11.0) + hiss / (rms(hiss) + 1e-12) * db(-24.0)
    env = np.clip(t / 0.06, 0, 1) * np.exp(-t / 2.3) * np.clip((dur - t) / 1.2, 0, 1)
    flutter = 1.0 + 0.12 * smooth(white(rng, n), 5.0) / (peak(smooth(white(rng, n), 5.0)) + 1e-12)
    out = core * env * flutter
    return fade(normalise_peak(out, -24.0))
