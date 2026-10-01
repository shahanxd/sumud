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
            g *= 1.0 / np.sqrt(1.0 + np.clip(lo / fl, 0, 1e6) ** (2 * order))
        if hi > 0:
            g *= 1.0 / np.sqrt(1.0 + np.clip(fl / hi, 0, 1e6) ** (2 * order))
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
    dither = (rng.random(x.shape) + rng.random(x.shape) - 1.0) / 32768.0
    pcm = np.clip(np.round((x + dither) * 32767.0), -32768, 32767).astype("<i2")
    if loop:
        # Duplicate after quantising so the copy is bit-identical to frame 0.
        pcm = np.concatenate([pcm, pcm[:1]], axis=0)
    frames, channels = pcm.shape
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

    # Crack: a clipped broadband burst with a fast and a slower decay, plus the punch
    # (200 Hz to 1.2 kHz, 40 ms) that carries the hit on small speakers.
    ck = seconds(0.026)
    tk = t_axis(ck)
    shape = np.exp(-tk / 0.0035) + 0.35 * np.exp(-tk / 0.012)
    crack_l = white(rng, ck) * shape
    crack_r = 0.6 * crack_l + 0.8 * white(rng, ck) * shape
    crack = np.zeros((n, 2))
    crack[pre:pre + ck, 0] = band(crack_l, 900, None, order=2)
    crack[pre:pre + ck, 1] = band(crack_r, 900, None, order=2)
    crack = soft_clip(crack * 3.0, drive=2.5)
    pk = seconds(0.04)
    punch = band(white(rng, pk), 200, 1200, order=2) * np.exp(-t_axis(pk) / 0.011)
    punch = soft_clip(punch / (peak(punch) + 1e-12) * 2.0, drive=2.0)
    crack[pre:pre + pk, 0] += 0.8 * punch
    crack[pre:pre + pk, 1] += 0.8 * punch

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
        src = coloured(rng, n, slope=-1.2) * body_env
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
    debris = normalise_peak(debris, -5.0)

    # Dust pouring: a hiss that swells just after the bang and dies over three seconds.
    dust = np.zeros((n, 2))
    dust_env = env_points(n, [(0, 0), (t0, 0), (t0 + 0.25, 1.0), (t0 + 1.2, 0.5), (t0 + 3.2, 0.08), (dur - 0.2, 0.0), (dur, 0.0)])
    for c in range(2):
        pour = smooth(white(rng, n), 12.0)
        dust[:, c] = band(white(rng, n), 1800, 11000, order=2) * dust_env * (0.7 + 0.3 * unit(pour / (peak(pour) + 1e-12)))
    dust = normalise_peak(dust, -22.0)

    # Mix the dry impact, then send it through the street.
    dry = np.zeros((n, 2))
    dry[:, 0] = 0.9 * front + 0.8 * sub
    dry[:, 1] = 0.9 * front + 0.8 * sub
    dry += 1.2 * crack + 1.0 * body
    ir_l = street_ir(rng, 2.6, rt_low=1.7, rt_high=0.9, early=[(0.031, 0.5), (0.047, 0.35), (0.074, 0.3), (0.118, 0.2)])
    ir_r = street_ir(rng, 2.6, rt_low=1.7, rt_high=0.9, early=[(0.029, 0.4), (0.052, 0.35), (0.081, 0.25), (0.126, 0.2)])
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
    w = smooth(white(rng, n), 0.35)
    wander = np.clip(3800.0 + 80.0 * w / (peak(w) + 1e-12), 3700.0, 3900.0)
    main = tv_filter(white(rng, n), wander, 28.0, kind="bandpass")
    main = tv_filter(main, wander, 28.0, kind="bandpass")
    second = resonate(resonate(white(rng, n), 5300.0, 22.0), 5300.0, 22.0) * db(-12.0)
    hiss = band(white(rng, n), 6000, 14000, order=2) * db(-30.0)
    core = main / (rms(main) + 1e-12) + second / (rms(second) + 1e-12) * db(-11.0) + hiss / (rms(hiss) + 1e-12) * db(-24.0)
    env = np.clip(t / 0.06, 0, 1) * np.exp(-t / 2.3) * np.clip((dur - t) / 1.2, 0, 1)
    fl = smooth(white(rng, n), 5.0)
    flutter = 1.0 + 0.12 * fl / (peak(fl) + 1e-12)
    out = core * env * flutter
    return normalise_peak(fade(out), -24.0)


# --------------------------------------------------------------------------------------
# Loops (exactly periodic by construction; see the module docstring)
# --------------------------------------------------------------------------------------

def lfo_terms(rng: np.random.Generator, dur: float, f_lo: float, f_hi: float, count: int) -> list[tuple[float, float, float]]:
    """Sinusoid terms (frequency with whole cycles in dur, amplitude, phase) for an LFO
    whose value and whose integral are both exactly periodic."""
    k_lo = max(1, int(math.floor(f_lo * dur)))
    k_hi = max(k_lo, int(math.ceil(f_hi * dur)))
    return [(int(rng.integers(k_lo, k_hi + 1)) / dur, rng.uniform(0.4, 1.0), rng.uniform(0, 2 * math.pi)) for _ in range(count)]


def lfo_eval(terms, t: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Returns the LFO and its time integral, both normalised to the LFO's peak."""
    v = np.zeros_like(t)
    i = np.zeros_like(t)
    for f, a, ph in terms:
        v += a * np.sin(2 * math.pi * f * t + ph)
        i += -a * np.cos(2 * math.pi * f * t + ph) / (2 * math.pi * f)
    p = peak(v) + 1e-12
    return v / p, i / p


def tv_filter_loop(x: np.ndarray, f_track: np.ndarray, q, kind: str = "lowpass") -> np.ndarray:
    """tv_filter over a periodic signal: runs two periods and keeps the second."""
    n = x.shape[0]
    return tv_filter(np.concatenate([x, x]), np.concatenate([f_track, f_track]), q, kind, block=64)[n:]


def rumble_loop(rng: np.random.Generator) -> np.ndarray:
    """Distant thuds under a siege day. Eight impacts across sixteen seconds, spaced
    irregularly (never closer than 0.9 s), each a low sine falling 70 to 24 Hz with a
    soft 8 ms attack (distance removes the front) over low-passed noise whose cutoff and
    tail length depend on a per-impact distance, amplitude-modulated at 2 to 6 Hz so the
    tail rolls the way multiple facades return it. Under it, brown noise band-limited to
    15 to 220 Hz with 0.05 to 0.25 Hz gusts: a low wind, barely there."""
    dur = 16.0
    n = seconds(dur)
    out = np.zeros((n, 2))

    bed_terms = lfo_terms(rng, dur, 0.05, 0.25, 5)
    gust, _ = lfo_eval(bed_terms, t_axis(n))
    gust = unit(gust) ** 1.5
    for c in range(2):
        bed = spectral_band(coloured(rng, n, -2.0), 15, 220, 3)
        out[:, c] += bed / (rms(bed) + 1e-12) * (0.3 + 0.7 * gust) * db(-14.0)

    times: list[float] = []
    while len(times) < 8:
        tt = rng.uniform(0.0, dur)
        if all(min(abs(tt - o), dur - abs(tt - o)) > 0.9 for o in times):
            times.append(tt)
    for tt in sorted(times):
        dist = rng.uniform(0.25, 1.0)  # 1 = far
        L = seconds(3.8)
        te = t_axis(L)
        f_sub = 24.0 + 46.0 * np.exp(-te / 0.16)
        sub = np.sin(2 * np.pi * np.cumsum(f_sub) / SR) * env_ad(L, 0.008, 0.35 + 0.25 * (1 - dist))
        body = coloured(rng, L, -1.5) * env_ad(L, 0.012, 0.7 + 1.5 * dist)
        body = band(body, None, 55.0 + 110.0 * (1.0 - dist), order=3)
        roll = 1.0 + 0.45 * band(white(rng, L), 2.0, 6.0, order=2) / (peak(band(white(rng, L), 2.0, 6.0, order=2)) + 1e-12)
        body *= roll
        ev = (1.4 * sub / (peak(sub) + 1e-12) * (1.0 - 0.5 * dist) + body / (peak(body) + 1e-12))
        ev = soft_clip(ev * 1.2, 1.4) * rng.uniform(0.35, 1.0) * (1.15 - 0.6 * dist)
        place(out, pan(ev, rng.uniform(-0.45, 0.45)), seconds(tt), wrap=True)
    return normalise_rms(out, -30.0)


def drone_hum_loop(rng: np.random.Generator) -> np.ndarray:
    """The zanana. Four rotors at 118.6, 120.0, 121.1 and 122.9 Hz (whole cycles in
    twelve seconds, so the beating is periodic), each a harmonic series to 16 kHz with a
    1/k^0.6 fall, a buzz formant at 1.2 to 3 kHz, motor-whine peaks near the 28th and
    56th harmonics, a weak fundamental, a random phase per harmonic, a 0.4 percent pitch
    wobble and a slow amplitude flutter, plus blade-wash noise (0.8 to 7 kHz) chopped at
    the blade rate. The rotors sit at four pan positions; the sum is saturated a little
    so the rotors intermodulate; a 90 Hz high-pass and a slow left-right drift with a
    matching air-absorption low-pass finish it."""
    dur = 12.0
    n = seconds(dur)
    t = t_axis(n)
    cycles = [1423, 1440, 1453, 1475]
    pans = [-0.55, -0.15, 0.2, 0.6]
    mix = np.zeros((n, 2))

    def machine_shape(f: np.ndarray) -> np.ndarray:
        g = np.ones_like(f)
        g *= np.where(f < 260.0, db(-9.0), 1.0)
        g *= 1.0 + 2.2 * np.exp(-((np.log(f / 1900.0)) ** 2) / (2 * 0.35 ** 2))
        g *= 1.0 / np.sqrt(1.0 + (f / 8500.0) ** 4)
        return g

    for cyc, p in zip(cycles, pans):
        f0 = cyc / dur
        fm, fm_int = lfo_eval(lfo_terms(rng, dur, 0.1, 1.4, 5), t)
        am, _ = lfo_eval(lfo_terms(rng, dur, 0.15, 2.0, 5), t)
        depth = 0.004
        ph = 2 * np.pi * f0 * (t + depth * fm_int)
        k_max = int(16000.0 / f0)
        ks = np.arange(1, k_max + 1)
        fk = ks * f0
        amps = ks ** -0.6 * machine_shape(fk)
        amps *= 1.0 + 3.0 * np.exp(-((ks - 28) ** 2) / (2 * 1.2 ** 2)) + 2.0 * np.exp(-((ks - 56) ** 2) / (2 * 2.0 ** 2))
        amps *= rng.uniform(0.7, 1.0, size=ks.shape)
        phases = rng.uniform(0, 2 * np.pi, size=ks.shape)
        rotor = np.zeros(n)
        for k, a, phk in zip(ks, amps, phases):
            rotor += a * np.sin(k * ph + phk)
        rotor /= peak(rotor) + 1e-12
        wash = spectral_band(white(rng, n), 800, 7000, 3)
        wash *= 0.55 + 0.45 * np.sin(2 * ph + rng.uniform(0, 6.28))
        wash /= peak(wash) + 1e-12
        sig = (rotor + 0.32 * wash) * (1.0 + 0.09 * am) * rng.uniform(0.75, 1.0)
        mix += pan(sig, p)

    mix = soft_clip(mix * 1.5, drive=1.6)
    for c in range(2):
        mix[:, c] = loop_twice(lambda x: band(x, 90.0, None, order=2), mix[:, c])
    # Slow drift across the field, one cycle per loop, with the far side a touch duller.
    drift = np.sin(2 * np.pi * t / dur + 0.7)
    gl = np.cos((drift * 0.35 + 1.0) * 0.25 * np.pi)
    gr = np.sin((drift * 0.35 + 1.0) * 0.25 * np.pi)
    out = np.zeros_like(mix)
    fc_l = 9000.0 - 2500.0 * unit(drift)
    fc_r = 9000.0 - 2500.0 * unit(-drift)
    out[:, 0] = tv_filter_loop(mix[:, 0] * gl * 1.35, fc_l, 0.7)
    out[:, 1] = tv_filter_loop(mix[:, 1] * gr * 1.35, fc_r, 0.7)
    return normalise_rms(out, -24.0)


def wind_loop(rng: np.random.Generator) -> np.ndarray:
    """Coastal wind. One gust signal (whole-cycle sinusoids between 0.05 and 0.3 Hz,
    skewed so lulls last longer) drives three bands the way wind speed does: the low
    pressure band (18 to 160 Hz) grows with speed^1.5, the whoosh (pink noise through a
    low-pass whose cutoff climbs from 250 Hz to 1.85 kHz) with speed^2, the hiss (1.5 to
    9 kHz) with speed^3. The right channel's gust runs 30 ms behind the left. Three
    whistles, narrow (Q 40) noise resonances between 700 and 2.4 kHz, swell for one to
    two seconds at gust peaks and slide upward slightly as the gust builds."""
    dur = 20.0
    n = seconds(dur)
    t = t_axis(n)
    gust, _ = lfo_eval(lfo_terms(rng, dur, 0.05, 0.3, 7), t)
    speed = unit(gust) ** 1.4
    out = np.zeros((n, 2))
    lag = seconds(0.03)

    # Whistle events at the strongest gusts.
    order = np.argsort(-speed)
    whistle_at: list[int] = []
    for idx in order:
        if all(min(abs(idx - o), n - abs(idx - o)) > seconds(4.0) for o in whistle_at):
            whistle_at.append(int(idx))
        if len(whistle_at) == 3:
            break

    low_common = spectral_band(coloured(rng, n, -2.0), 18, 160, 3)
    for c in range(2):
        s = np.roll(speed, lag * c)
        # The pressure band is mostly shared between the ears; the whoosh and hiss are not.
        low = 0.8 * low_common + 0.45 * spectral_band(coloured(rng, n, -2.0), 18, 160, 3)
        low = low / (rms(low) + 1e-12) * (0.2 + 0.8 * s ** 1.5)
        mid_src = spectral_band(coloured(rng, n, -1.0), 60, 7000, 2)
        fc = 250.0 + 1600.0 * s ** 1.5
        mid = tv_filter_loop(mid_src, fc, 0.75)
        mid = mid / (rms(mid) + 1e-12) * (0.12 + 0.88 * s ** 2)
        hi = spectral_band(white(rng, n), 1500, 9000, 3)
        hi = hi / (rms(hi) + 1e-12) * (0.03 + 0.97 * s ** 3)
        whistles = np.zeros(n)
        for w_i, at in enumerate(whistle_at):
            width = seconds(rng.uniform(1.1, 2.2))
            f_w = rng.uniform(700, 2400)
            env = np.zeros(n)
            win = 0.5 - 0.5 * np.cos(np.linspace(0, 2 * np.pi, width))
            idx = (np.arange(width) + at - width // 2) % n
            env[idx] = win ** 1.5
            f_track = f_w * (1.0 + 0.06 * env)
            src = spectral_band(white(rng, n), 300, 6000, 2)
            w = tv_filter_loop(src, f_track, 40.0, kind="bandpass")
            w = tv_filter_loop(w, f_track, 40.0, kind="bandpass")
            side = 1.0 if (w_i % 2 == c) else 0.55
            whistles += w / (peak(w) + 1e-12) * env * side * rng.uniform(0.6, 1.0)
        ch = 0.9 * low + 1.0 * mid + 0.45 * hi + 0.16 * whistles * (rms(mid) + 1e-12) / 0.1
        out[:, c] = ch
    return normalise_rms(out, -26.0)


def sea_loop(rng: np.random.Generator) -> np.ndarray:
    """Mediterranean waves on sand. Three waves at 1.0, 8.4 and 16.9 s (gaps 7.4, 8.5
    and 8.1 s round the loop). Each: the approach, pink noise under a low-pass at 250 Hz
    rising over two seconds; the break, the cutoff opening to 3.2 kHz in 0.4 s while
    6 to 20 Hz flutter tumbles the foam and the image slides across the shore; the
    run-up and retreat, high-passed hiss whose cutoff climbs from 1.2 to 3 kHz as the
    water film thins over four seconds; and foam, a Poisson crackle of 2.5 to 7 kHz
    bubble pops thinning out over five seconds. Under everything a distant surf bed
    (60 to 500 Hz) and a breath of spray."""
    dur = 24.0
    n = seconds(dur)
    t = t_axis(n)
    out = np.zeros((n, 2))
    bed_lfo, _ = lfo_eval(lfo_terms(rng, dur, 0.05, 0.2, 4), t)
    for c in range(2):
        bed = spectral_band(coloured(rng, n, -1.5), 60, 500, 3)
        spray = spectral_band(white(rng, n), 2000, 9000, 3)
        out[:, c] += bed / (rms(bed) + 1e-12) * (0.55 + 0.45 * unit(bed_lfo)) * db(-18.0)
        out[:, c] += spray / (rms(spray) + 1e-12) * (0.6 + 0.4 * unit(bed_lfo)) * db(-34.0)

    for i, (tw, size, direction) in enumerate([(1.0, 1.0, 1.0), (8.4, 0.72, -1.0), (16.9, 0.9, 1.0)]):
        L = seconds(8.0)
        te = t_axis(L)
        env = env_points(L, [(0, 0), (1.0, 0.1), (2.0, 0.55), (2.35, 1.0), (3.0, 0.7), (4.2, 0.3), (6.5, 0.06), (8.0, 0.0)])
        fc = env_points(L, [(0, 240), (1.9, 480), (2.3, 3200), (2.9, 2500), (4.5, 1300), (8.0, 700)])
        body = tv_filter(coloured(rng, L, -1.0), fc, 0.8, kind="lowpass", block=64)
        tumble = band(white(rng, L), 6.0, 20.0, order=2)
        tumble /= peak(tumble) + 1e-12
        break_win = env_points(L, [(0, 0), (1.8, 0), (2.3, 1), (3.6, 1), (5.0, 0), (8, 0)])
        body *= env * (1.0 + 0.4 * tumble * break_win)
        body /= rms(body[seconds(2.0):seconds(3.5)]) + 1e-12

        hiss_env = env_points(L, [(0, 0), (2.4, 0), (3.1, 1.0), (4.0, 0.7), (5.5, 0.3), (7.5, 0.04), (8.0, 0)])
        hp = env_points(L, [(0, 1200), (3.0, 1200), (5.5, 2400), (8.0, 3000)])
        hiss_l = tv_filter(white(rng, L), hp, 0.7, kind="highpass", block=64) * hiss_env
        hiss_r = tv_filter(white(rng, L), hp, 0.7, kind="highpass", block=64) * hiss_env
        hiss_l = band(hiss_l, None, 9000, 2)
        hiss_r = band(hiss_r, None, 9000, 2)
        h_scale = 0.55 / (rms(hiss_l[seconds(3.0):seconds(4.0)]) + 1e-12)

        foam = np.zeros((L, 2))
        tt = 2.2
        while tt < 7.6:
            rate = 4.0 + 150.0 * math.exp(-max(tt - 2.7, 0.0) / 1.5) * min(1.0, (tt - 2.2) / 0.5 + 0.05)
            tt += rng.exponential(1.0 / rate)
            g = ping(rng, rng.uniform(2500, 7000), rng.uniform(0.0005, 0.002), 0.004, q=rng.uniform(3, 6), noise=1.0)
            place(foam, pan(g * rng.uniform(0.2, 1.0), rng.uniform(-0.9, 0.9)), seconds(tt))
        foam *= 0.09 / (peak(foam) + 1e-12)

        wave = np.zeros((L, 2))
        p_track = direction * env_points(L, [(0, -0.35), (2.0, -0.3), (3.4, 0.3), (8.0, 0.35)])
        a = (p_track + 1.0) * 0.25 * np.pi
        wave[:, 0] += body * np.cos(a)
        wave[:, 1] += body * np.sin(a)
        wave[:, 0] += hiss_l * h_scale
        wave[:, 1] += hiss_r * h_scale
        wave += foam
        place(out, wave * size * db(-4.0), seconds(tw), wrap=True)
    return normalise_rms(out, -24.0)


# --------------------------------------------------------------------------------------
# Birds and the placeholder breath
# --------------------------------------------------------------------------------------

def birds_leave(rng: np.random.Generator) -> np.ndarray:
    """A flock leaving a roof at once: fourteen pigeons and ten sparrows, each starting
    within the first 1.4 s. A pigeon flaps at 8 to 10 Hz on take-off and slows toward
    6 Hz in flight; each flap is 45 ms of 250 to 1800 Hz noise with a wing-clap click on
    the first four beats. A sparrow flutters at 14 to 19 Hz, 20 ms bursts of 1.2 to 5 kHz
    noise. Every bird recedes with inverse-distance loss, a low-pass that closes as it
    goes, a Doppler pitch drop from accelerating to 18 m/s away from the listener, and
    a pan that drifts outward. Claws scrape the parapet at the start, the flock's wash
    of air swells at 0.9 s, and five sparrow chirps (40 to 70 ms glides, 3.5 to 7 kHz,
    roughened with 120 Hz modulation) sit inside it."""
    dur = 4.0
    n = seconds(dur)
    out = np.zeros((n, 2))
    for b in range(24):
        pigeon = b < 14
        start = rng.uniform(0.0, 1.4) if pigeon else rng.uniform(0.1, 1.3)
        L = seconds(3.4)
        te = t_axis(L)
        sig = np.zeros(L)
        rate0 = rng.uniform(8.0, 10.0) if pigeon else rng.uniform(14.0, 19.0)
        rate1 = rate0 * (0.62 if pigeon else 0.8)
        tt = rng.uniform(0.0, 0.05)
        beat = 0
        while tt < 3.0:
            frac = min(tt / 1.2, 1.0)
            rate = rate0 * (1 - frac) + rate1 * frac
            tt += (1.0 / rate) * rng.uniform(0.92, 1.08)
            if pigeon:
                d = seconds(0.045)
                g = band(white(rng, d), 250, 1800, order=2) * (0.5 - 0.5 * np.cos(np.linspace(0, 2 * np.pi, d))) ** 0.6
                if beat < 4:
                    ck = seconds(0.003)
                    g[:ck] += band(white(rng, ck), 800, 9000, order=2) * np.linspace(1.6 - 0.3 * beat, 0, ck)
            else:
                d = seconds(0.02)
                g = band(white(rng, d), 1200, 5000, order=2) * (0.5 - 0.5 * np.cos(np.linspace(0, 2 * np.pi, d))) * 0.6
            place(sig, g * rng.uniform(0.7, 1.0), seconds(tt))
            beat += 1
        # Distance, absorption, Doppler.
        v = 18.0 * (1.0 - np.exp(-te / 0.7))
        dist = 1.0 + np.cumsum(v) / SR
        sig *= 1.0 / dist ** 1.1
        sig = tv_filter(sig, np.clip(7000.0 / dist ** 0.8, 600.0, 7000.0), 0.7, kind="lowpass", block=64)
        factor = 343.0 / (343.0 + v)
        warped = np.cumsum(factor) / SR
        sig = np.interp(te, warped, sig)
        p0 = rng.uniform(-0.6, 0.6)
        p1 = np.clip(p0 + np.sign(p0 + 1e-3) * rng.uniform(0.2, 0.7), -1, 1)
        p_track = p0 + (p1 - p0) * np.clip(te / 2.0, 0, 1)
        a = (p_track + 1.0) * 0.25 * np.pi
        bird = np.stack([sig * np.cos(a), sig * np.sin(a)], axis=1) * (1.0 if pigeon else 0.45)
        place(out, bird, seconds(start))

    for _ in range(7):
        g = ping(rng, rng.uniform(1800, 5000), rng.uniform(0.002, 0.006), 0.02, q=rng.uniform(4, 9), noise=1.0)
        place(out, pan(g * rng.uniform(0.1, 0.3), rng.uniform(-0.6, 0.6)), seconds(rng.uniform(0.0, 0.45)))

    wash_env = env_points(n, [(0, 0), (0.25, 0), (0.9, 1.0), (1.6, 0.55), (3.0, 0.0), (4, 0)])
    for c in range(2):
        out[:, c] += band(white(rng, n), 300, 3000, order=2) * wash_env * 0.12

    for _ in range(5):
        d = seconds(rng.uniform(0.04, 0.07))
        tc = t_axis(d)
        f_a, f_b = rng.uniform(3500, 5000), rng.uniform(5500, 7000)
        shape = np.sin(np.pi * tc / tc[-1])
        f_inst = f_a + (f_b - f_a) * shape
        chirp = np.sin(2 * np.pi * np.cumsum(f_inst) / SR)
        chirp *= (0.5 - 0.5 * np.cos(2 * np.pi * tc / tc[-1])) * (0.7 + 0.3 * np.sin(2 * np.pi * 120.0 * tc))
        chirp += 0.15 * band(white(rng, d), 3000, 8000, order=2) * shape
        place(out, pan(chirp * 0.16, rng.uniform(-0.8, 0.8)), seconds(rng.uniform(0.2, 2.4)))
    return normalise_peak(fade(out, 5.0, 60.0), -6.0)


def roof_breath_loop(rng: np.random.Generator) -> np.ndarray:
    """PLACEHOLDER for the friend's recorded vocal pad. Breath and air only, no pitch:
    pinkish noise through three formant band-passes (Q 9, 7, 6) whose centres glide
    between the vowels a, o, u and e, one per exhale, over four 7.5 s breaths; the
    inhale is a thinner hiss (1.5 to 7 kHz) with the formants almost closed. Under it a
    room-air bed of brown noise (30 to 180 Hz). Nothing here has a fundamental."""
    dur = 30.0
    n = seconds(dur)
    t = t_axis(n)
    period = 7.5
    ph = (t / period) % 1.0

    def window(centre: float, half: float, power: float = 1.0) -> np.ndarray:
        d = np.minimum(np.abs(ph - centre), 1.0 - np.abs(ph - centre)) / half
        return np.where(d < 1.0, (0.5 + 0.5 * np.cos(np.pi * np.clip(d, 0, 1))) ** power, 0.0)

    exhale = window(0.30, 0.27, 1.3)
    inhale = window(0.78, 0.16, 1.6) * 0.55
    vowels = [(730, 1090, 2440), (570, 840, 2410), (300, 870, 2240), (530, 1840, 2480)]
    keys = [k * period + 0.30 * period for k in range(4)]
    tracks = []
    for i in range(3):
        xs = [keys[0] - period] + keys + [keys[0] + 4 * period]
        ys = [vowels[3][i]] + [v[i] for v in vowels] + [vowels[0][i]]
        tr = np.interp(t, xs, ys)
        tracks.append(smooth(tr - np.mean(tr), 0.25, periodic=True) + np.mean(tr))
    wander, _ = lfo_eval(lfo_terms(rng, dur, 0.05, 0.2, 4), t)

    out = np.zeros((n, 2))
    src_common = coloured(rng, n, -0.7)
    for c in range(2):
        # One breath heard by two ears: a shared source, a little of its own per side.
        src = 0.8 * src_common + 0.45 * coloured(rng, n, -0.7)
        voice = np.zeros(n)
        for i, (q, g) in enumerate([(9.0, 1.0), (7.0, 0.55), (6.0, 0.3)]):
            f_track = tracks[i] * (1.0 + (0.012 if c else -0.012)) * (1.0 + 0.02 * wander)
            voice += g * tv_filter_loop(src, f_track, q, kind="bandpass")
        voice /= rms(voice) + 1e-12
        hiss = spectral_band(white(rng, n), 1500, 7000, 3)
        hiss /= rms(hiss) + 1e-12
        room = spectral_band(coloured(rng, n, -2.0), 30, 180, 3)
        room /= rms(room) + 1e-12
        out[:, c] = voice * (exhale + 0.12 * inhale) + hiss * (0.35 * inhale + 0.05 * exhale) + room * (0.5 + 0.2 * unit(wander)) * 0.35
    return normalise_rms(out, -30.0)


# --------------------------------------------------------------------------------------
# Small one-shots
# --------------------------------------------------------------------------------------

def candle_out(rng: np.random.Generator) -> np.ndarray:
    """A puff of breath (pink noise, 300 Hz to 4 kHz, 30 ms rise, 120 ms hold, 100 ms
    decay with the low-pass closing as the breath ends) then the wick: a quiet 4 to
    10 kHz hiss with three micro-sizzles fading over 300 ms."""
    n = seconds(0.6)
    t = t_axis(n)
    puff_env = env_points(n, [(0, 0), (0.03, 1.0), (0.15, 0.9), (0.26, 0.0), (0.6, 0)])
    fc = env_points(n, [(0, 4000), (0.12, 4000), (0.27, 900), (0.6, 800)])
    puff = tv_filter(band(coloured(rng, n, -1.0), 300, None, order=2), fc, 0.7, kind="lowpass") * puff_env
    wick_env = env_points(n, [(0, 0), (0.2, 0), (0.24, 1.0), (0.55, 0.05), (0.6, 0)])
    wick = band(white(rng, n), 4000, 10000, order=2) * wick_env * 0.15
    for _ in range(3):
        g = ping(rng, rng.uniform(5000, 9000), 0.003, 0.01, q=5, noise=1.0)
        place(wick, g * 0.25, seconds(rng.uniform(0.22, 0.45)))
    return normalise_peak(fade(puff / (peak(puff) + 1e-12) + wick), -18.0)


def footstep_sand(rng: np.random.Generator, variant: int) -> np.ndarray:
    """A sandal on sand: a dense rain of grain impacts (1 to 5 kHz micro-pings) whose
    density peaks at the heel and again at the toe 55 to 95 ms later, a soft low thud
    (60 to 120 Hz) under the heel, and a shush of displaced sand (300 Hz to 1.5 kHz).
    Variants differ in heel-toe timing, grain count and spectral tilt."""
    n = seconds(0.25)
    toe = rng.uniform(0.055, 0.095)
    grains = np.zeros(n)
    count = int(rng.integers(260, 380))
    tilt = rng.uniform(0.85, 1.15)
    for _ in range(count):
        which = rng.random()
        tt = (rng.normal(0.012, 0.012) if which < 0.55 else rng.normal(toe + 0.01, 0.014))
        if tt < 0:
            continue
        g = ping(rng, rng.uniform(1000, 5000) * tilt, rng.uniform(0.0006, 0.002), 0.005, q=rng.uniform(2, 5), noise=1.0)
        place(grains, g * rng.uniform(0.2, 1.0), seconds(tt))
    thud = band(white(rng, n), 60, 120, order=2) * env_ad(n, 0.004, 0.03)
    shush = band(white(rng, n), 300, 1500, order=2) * (env_ad(n, 0.01, 0.05) + 0.7 * np.roll(env_ad(n, 0.012, 0.05), seconds(toe)))
    out = grains / (peak(grains) + 1e-12) + 0.5 * thud / (peak(thud) + 1e-12) + 0.35 * shush / (peak(shush) + 1e-12)
    return normalise_peak(fade(out), -14.0)


def footstep_concrete(rng: np.random.Generator, variant: int) -> np.ndarray:
    """A sandal on concrete: the sole's slap (a 12 ms noise burst, 400 Hz to 4 kHz)
    twice, heel then sole 18 to 40 ms apart, a short damped body at 150 to 250 Hz, five
    to fifteen grit clicks scattered after the slap, and a 60 ms street reflection."""
    n = seconds(0.25)
    out = np.zeros(n)
    gap = rng.uniform(0.018, 0.04)
    for i, (at, amp) in enumerate([(0.0, 0.7), (gap, 1.0)]):
        d = seconds(0.012)
        slap = band(white(rng, d), 400, 4000, order=2) * np.exp(-t_axis(d) / 0.0025)
        place(out, slap * amp, seconds(at))
        body = ping(rng, rng.uniform(150, 250), 0.02, 0.08, q=3, noise=0.5)
        place(out, body * 0.9 * amp, seconds(at))
    for _ in range(int(rng.integers(5, 16))):
        g = ping(rng, rng.uniform(2000, 6500), rng.uniform(0.0008, 0.003), 0.008, q=rng.uniform(3, 7), noise=1.0)
        place(out, g * rng.uniform(0.1, 0.4), seconds(gap + rng.uniform(0.005, 0.09)))
    ir = street_ir(rng, 0.09, rt_low=0.12, rt_high=0.06, early=[(0.011, 0.5), (0.023, 0.3)])
    out = out + 0.35 * convolve(out, ir)
    return normalise_peak(fade(out), -12.0)


def window_at(n: int, centre: float, width: float, power: float = 1.0) -> np.ndarray:
    """A raised-cosine bump of `width` seconds centred at `centre` seconds."""
    t = t_axis(n)
    d = np.abs(t - centre) / (width * 0.5)
    return np.where(d < 1.0, (0.5 + 0.5 * np.cos(np.pi * np.clip(d, 0, 1))) ** power, 0.0)


def cloth_rustle(rng: np.random.Generator) -> np.ndarray:
    """Fabric moving: noise from 800 Hz to 6 kHz with a 3 kHz lift, three overlapping
    swells of 100 to 200 ms, textured by a fast random envelope (to 200 Hz) so it has
    fibres in it instead of being a smooth hiss."""
    n = seconds(0.5)
    src = resonate(band(white(rng, n), 800, 6000, 2), 3000, 0.9, "peaking", 6.0)
    env = np.zeros(n)
    for _ in range(3):
        env += window_at(n, rng.uniform(0.06, 0.38), rng.uniform(0.1, 0.2)) * rng.uniform(0.5, 1.0)
    tex = band(white(rng, n), None, 200, 2)
    tex = 0.5 + 0.5 * unit(tex / (peak(tex) + 1e-12))
    return normalise_peak(fade(src * env * tex), -18.0)


def paper_page(rng: np.random.Generator) -> np.ndarray:
    """A notebook page turning: fingers gripping (eight tiny 3 to 8 kHz crinkles in the
    first 120 ms), the lift and sweep (900 Hz-high-passed noise under a low-pass that
    opens from 2.5 to 6 kHz and closes again over 380 ms), the page landing at 0.52 s
    (a 20 ms flap from 300 Hz to 3 kHz over a damped 120 Hz thump) and a few crinkles
    as it settles."""
    n = seconds(0.8)
    out = np.zeros(n)
    for _ in range(8):
        g = ping(rng, rng.uniform(3000, 8000), rng.uniform(0.0005, 0.002), 0.006, q=rng.uniform(3, 7), noise=1.0)
        place(out, g * rng.uniform(0.15, 0.45), seconds(rng.uniform(0.0, 0.12)))
    fc = env_points(n, [(0, 2500), (0.14, 2500), (0.33, 6000), (0.52, 2800), (0.8, 2800)])
    sweep = tv_filter(band(white(rng, n), 900, None, 2), fc, 0.8, kind="lowpass") * window_at(n, 0.33, 0.38, 1.4)
    out += 0.7 * sweep / (peak(sweep) + 1e-12)
    d = seconds(0.02)
    flap = band(white(rng, d), 300, 3000, 2) * np.exp(-t_axis(d) / 0.006)
    place(out, flap * 1.0, seconds(0.52))
    place(out, ping(rng, 120.0, 0.015, 0.06, q=2.5, noise=0.3) * 0.5, seconds(0.52))
    for _ in range(5):
        g = ping(rng, rng.uniform(3000, 7000), rng.uniform(0.0005, 0.0015), 0.005, q=rng.uniform(3, 6), noise=1.0)
        place(out, g * rng.uniform(0.1, 0.3), seconds(rng.uniform(0.53, 0.68)))
    return normalise_peak(fade(out), -14.0)


def stitch(rng: np.random.Generator, variant: int) -> np.ndarray:
    """A thread pulled through cloth: the needle's puncture (a 2 ms broadband click),
    then the pull, a run of micro-clicks whose rate accelerates from about 250 to 900 a
    second as the thread runs through the weave, each a 2.5 to 7 kHz grain, under a
    faint friction hiss. The three variants differ in length and rate."""
    n = seconds(0.15)
    out = np.zeros(n)
    ck = seconds(0.002)
    out[:ck] += band(white(rng, ck), 1500, 9000, 2) * np.linspace(1.0, 0.0, ck) * 0.6
    length = rng.uniform(0.08, 0.12)
    r0, r1 = rng.uniform(220, 300), rng.uniform(800, 1000)
    tt = 0.006
    while tt < length:
        frac = (tt - 0.006) / length
        tt += 1.0 / (r0 + (r1 - r0) * frac) * rng.uniform(0.85, 1.15)
        g = ping(rng, rng.uniform(2500, 7000), rng.uniform(0.0003, 0.0007), 0.003, q=rng.uniform(2.5, 4), noise=1.0)
        amp = math.sin(math.pi * min(frac, 1.0)) ** 0.5 * rng.uniform(0.4, 1.0)
        place(out, g * amp, seconds(tt))
    hiss = band(white(rng, n), 3000, 8000, 2) * window_at(n, 0.006 + length * 0.5, length * 1.1)
    out += 0.12 * hiss / (peak(hiss) + 1e-12)
    return normalise_peak(fade(out, 1.0, 5.0), -20.0)


def door_wood(rng: np.random.Generator) -> np.ndarray:
    """A wooden door: the latch (a 2 ms click through resonances at 2.4 and 3.9 kHz),
    the swing (a faint push of air, 100 to 600 Hz), the door meeting the frame at 0.36 s
    (a 6 ms knock from 300 Hz to 2.5 kHz, low-passed noise from 80 to 400 Hz, and three
    damped panel modes at 112, 185 and 262 Hz), the frame rattling for 150 ms, and a
    short hallway reflection."""
    n = seconds(0.8)
    out = np.zeros(n)
    click = np.zeros(seconds(0.03))
    click[:seconds(0.002)] = band(white(rng, seconds(0.002)), 1000, 10000, 2)
    out[:click.size] += resonate(click, 2400, 9) * 1.2 + resonate(click, 3900, 9) * 0.8 + click * 0.3
    swing = band(white(rng, n), 100, 600, 2) * window_at(n, 0.19, 0.32, 1.5)
    out += 0.08 * swing / (peak(swing) + 1e-12)
    at = seconds(0.36)
    d = seconds(0.006)
    place(out, band(white(rng, d), 300, 2500, 2) * np.exp(-t_axis(d) / 0.0015) * 1.0, at)
    d = seconds(0.12)
    place(out, band(white(rng, d), 80, 400, 2) * np.exp(-t_axis(d) / 0.03) * 1.4, at)
    for f0, decay, amp in [(112, 0.09, 1.0), (185, 0.06, 0.7), (262, 0.045, 0.5)]:
        place(out, ping(rng, f0, decay, 0.3, q=4, noise=0.4) * amp, at)
    for _ in range(4):
        g = ping(rng, rng.uniform(900, 1800), rng.uniform(0.003, 0.006), 0.02, q=6, noise=0.8)
        place(out, g * rng.uniform(0.15, 0.4), seconds(rng.uniform(0.39, 0.51)))
    ir = street_ir(rng, 0.25, rt_low=0.3, rt_high=0.15, early=[(0.009, 0.4), (0.019, 0.25)])
    out = soft_clip(out + 0.3 * convolve(out, ir), 1.4)
    return normalise_peak(fade(out), -10.0)


def grab(rng: np.random.Generator) -> np.ndarray:
    """Hands closing on a plastic jerrycan handle: skin touching plastic (20 ms of soft
    300 Hz to 2.5 kHz noise), the handle's tock (a click through a 450 Hz low-Q body and
    a 1.9 kHz plastic ring), the hollow can answering at 190 Hz, and the fingers
    settling with a smaller second tock."""
    n = seconds(0.2)
    out = np.zeros(n)
    d = seconds(0.02)
    out[:d] += band(white(rng, d), 300, 2500, 2) * (0.5 - 0.5 * np.cos(np.linspace(0, 2 * np.pi, d))) * 0.25
    for at, amp in [(0.03, 1.0), (0.075, 0.45)]:
        place(out, ping(rng, 450, 0.012, 0.06, q=2.5, noise=0.7) * amp, seconds(at))
        place(out, ping(rng, 1900, 0.006, 0.03, q=6, noise=0.8) * 0.6 * amp, seconds(at))
    place(out, ping(rng, 190, 0.04, 0.15, q=5, noise=0.3) * 0.35, seconds(0.03))
    d = seconds(0.05)
    place(out, band(white(rng, d), 150, 500, 2) * np.exp(-t_axis(d) / 0.012) * 0.5, seconds(0.03))
    return normalise_peak(fade(out), -14.0)


def drop_heavy(rng: np.random.Generator) -> np.ndarray:
    """A full jerrycan set down: a 90-to-45 Hz thump with a 2 ms attack, a low-passed
    noise body (60 to 350 Hz), the plastic slap (15 ms, 200 Hz to 3 kHz), the can's
    damped 150 Hz resonance, then the water sloshing inside, 200 to 800 Hz noise
    wobbling at 4.2 Hz and dying over 400 ms, with a little grit under the base."""
    n = seconds(0.5)
    t = t_axis(n)
    f_sub = 45.0 + 45.0 * np.exp(-t / 0.05)
    sub = np.sin(2 * np.pi * np.cumsum(f_sub) / SR) * env_ad(n, 0.002, 0.09)
    body = band(white(rng, n), 60, 350, 2) * env_ad(n, 0.003, 0.07)
    d = seconds(0.015)
    slap = np.zeros(n)
    slap[:d] = band(white(rng, d), 200, 3000, 2) * np.exp(-t_axis(d) / 0.004)
    can = ping(rng, 150, 0.08, 0.5, q=4, noise=0.4)
    slosh = band(white(rng, n), 200, 800, 2) * np.clip((t - 0.04) / 0.05, 0, 1) * (0.55 + 0.45 * np.sin(2 * np.pi * 4.2 * t + 1.0)) * np.exp(-np.maximum(t - 0.04, 0) / 0.16)
    grit = np.zeros(n)
    for _ in range(4):
        g = ping(rng, rng.uniform(2000, 6000), rng.uniform(0.001, 0.003), 0.008, q=rng.uniform(3, 6), noise=1.0)
        place(grit, g * rng.uniform(0.1, 0.3), seconds(rng.uniform(0.02, 0.08)))
    out = 1.3 * sub + 1.1 * body / (peak(body) + 1e-12) + 0.8 * slap / (peak(slap) + 1e-12) + 0.5 * can / (peak(can) + 1e-12) + 0.45 * slosh / (peak(slosh) + 1e-12) + grit
    return normalise_peak(fade(soft_clip(out, 1.3)), -6.0)


def kite_flap(rng: np.random.Generator) -> np.ndarray:
    """A plastic-bag kite fluttering: flaps at a rate that wanders between 8 and 20 a
    second with the gusts, each a 3 to 8 ms crackle from 1 to 8 kHz with two or three
    4 to 9 kHz crinkles and a small 200 to 600 Hz pop, over the wind on the bag itself
    (200 Hz to 1.5 kHz noise following the same gust)."""
    n = seconds(1.5)
    g_env = band(white(rng, n), None, 1.2, 2)
    gust = unit(g_env / (peak(g_env) + 1e-12))
    rate = 8.0 + 12.0 * gust
    phase = np.cumsum(rate) / SR
    out = np.zeros(n)
    for k in range(1, int(phase[-1]) + 1):
        at = int(np.searchsorted(phase, k))
        d = seconds(rng.uniform(0.003, 0.008))
        flap = band(white(rng, d), 1000, 8000, 2) * np.exp(-t_axis(d) / (d / SR / 3.0))
        for _ in range(int(rng.integers(2, 4))):
            place(flap, ping(rng, rng.uniform(4000, 9000), 0.0005, 0.003, q=4, noise=1.0) * 0.6, int(rng.integers(0, max(1, d - 20))))
        strength = 0.4 + 0.6 * gust[min(at, n - 1)]
        place(out, flap * strength * rng.uniform(0.6, 1.0), at)
        place(out, ping(rng, rng.uniform(200, 600), 0.004, 0.02, q=2, noise=0.8) * 0.25 * strength, at)
    wind = band(white(rng, n), 200, 1500, 2) * (0.3 + 0.7 * gust)
    out += 0.18 * wind / (peak(wind) + 1e-12)
    return normalise_peak(fade(out), -16.0)


# --------------------------------------------------------------------------------------
# Catalogue, build, README, check
# --------------------------------------------------------------------------------------

class Entry:
    def __init__(self, name, fn, channels, secs, loop, level, purpose, how):
        self.name, self.fn, self.channels, self.seconds, self.loop = name, fn, channels, secs, loop
        self.level, self.purpose, self.how = level, purpose, how

    @property
    def path(self) -> str:
        return os.path.join(OUT_DIR, self.name + ".wav")

    @property
    def seed(self) -> int:
        import zlib
        return zlib.crc32(self.name.encode("utf-8"))


SOUNDS: list[Entry] = [
    Entry("strike_bang", strike_bang, 2, 6.0, False, ("peak", -1.0),
          "the one real, close bang of a strike day (Days 3 and 7); bus strike; the loudest sound in the game",
          "20 ms silence, an N-wave shock front, a clipped white-noise crack, a 60 to 35 Hz sub sine, brown noise under a low-pass sweeping 4 kHz to 90 Hz, two synthetic concrete-street impulse responses with facade slaps, a Poisson rain of noise-excited concrete, grit and glass grains thinning over 2.8 s, and pouring dust"),
    Entry("ringing", ringing, 1, 8.0, False, ("peak", -24.0),
          "the tinnitus after the bang, alone under the white-out; bus strike",
          "white noise through a Q 28 band wandering 3.72 to 3.88 kHz, twice, a weaker band at 5.3 kHz, a breath of hiss, fading over 8 s"),
    Entry("rumble_loop", rumble_loop, 2, 16.0, True, ("rms", -30.0),
          "distant thuds under every siege day; bus rumble (its own slider)",
          "eight low sine-and-noise impacts placed irregularly and wrapped round the loop, each rolled by 2 to 6 Hz modulation, over gusting brown noise from 15 to 220 Hz"),
    Entry("drone_hum_loop", drone_hum_loop, 2, 12.0, True, ("rms", -24.0),
          "the zanana, absent on Day 1, faint from Day 2, gone on the last beach; bus ambience",
          "four rotors at 118.6, 120.0, 121.1 and 122.9 Hz as harmonic series with a buzz formant, motor-whine peaks and blade-wash noise, wobbling and beating, saturated together, drifting left to right once per loop"),
    Entry("wind_loop", wind_loop, 2, 20.0, True, ("rms", -26.0),
          "coastal wind on the beach, the roof and the street; bus ambience",
          "one 0.05 to 0.3 Hz gust signal driving a low pressure band, a swept-low-pass whoosh and a hiss with speed powers 1.5, 2 and 3, the right channel 30 ms behind, and three Q 40 whistles swelling at gust peaks"),
    Entry("sea_loop", sea_loop, 2, 20.0, True, ("rms", -24.0),
          "the Mediterranean on the beach beats and under the sea verse's silence before the full stop; bus ambience",
          "three waves 7.4 to 8.5 s apart, each a low-pass opening from 250 Hz to 3.2 kHz with foam flutter, a retreating high-passed hiss whose cutoff climbs, and Poisson bubble pops, over a distant surf bed"),
    Entry("birds_leave", birds_leave, 2, 4.0, False, ("peak", -6.0),
          "the flock leaving the roof in the seconds before the strike; bus effects",
          "fourteen pigeons and ten sparrows as flap-rate noise bursts with wing-clap clicks, inverse-distance loss, a closing low-pass, Doppler pitch drop and outward pan, plus claws, a wash of air and five sparrow chirps"),
    Entry("roof_breath_loop", roof_breath_loop, 2, 30.0, True, ("rms", -30.0),
          "PLACEHOLDER for the friend's recorded vocal pad on the roof at dusk; bus voices; replace before any build leaves the machine",
          "pinkish noise through three formant band-passes gliding between the vowels a, o, u and e over four 7.5 s breaths, a thinner hiss on the inhale, brown room air; no fundamental anywhere"),
    Entry("candle_out", candle_out, 1, 0.6, False, ("peak", -18.0),
          "a candle blown out in the night street; bus effects",
          "a puff of pink noise with its low-pass closing, then a quiet 4 to 10 kHz wick hiss with three micro-sizzles"),
]
for _i in range(1, 5):
    SOUNDS.append(Entry(f"footstep_sand_{_i}", (lambda rng, v=_i: footstep_sand(rng, v)), 1, 0.25, False, ("peak", -14.0),
                        "sandals on sand, one of four variants chosen by Sound.step(\"sand\"); bus effects",
                        "a rain of 1 to 5 kHz grain pings peaking at heel and toe, a soft 60 to 120 Hz thud and a shush of displaced sand; timing and grain count differ per variant"))
for _i in range(1, 5):
    SOUNDS.append(Entry(f"footstep_concrete_{_i}", (lambda rng, v=_i: footstep_concrete(rng, v)), 1, 0.25, False, ("peak", -12.0),
                        "sandals on concrete, one of four variants chosen by Sound.step(\"concrete\"); bus effects",
                        "two 12 ms slaps 18 to 40 ms apart with damped 150 to 250 Hz bodies, scattered grit clicks and a 60 ms street reflection; gap and grit differ per variant"))
SOUNDS += [
    Entry("cloth_rustle", cloth_rustle, 1, 0.5, False, ("peak", -18.0),
          "clothes moving when a character crouches, sits or picks something up; bus effects",
          "band-limited noise with a 3 kHz lift, three overlapping swells, textured by a fast random envelope"),
    Entry("paper_page", paper_page, 1, 0.8, False, ("peak", -14.0),
          "a page of Layla's notebook turning; bus effects",
          "finger crinkles, a swept-low-pass sweep of paper, a 20 ms flap over a damped 120 Hz thump, settling crinkles"),
]
for _i in range(1, 4):
    SOUNDS.append(Entry(f"stitch_{_i}", (lambda rng, v=_i: stitch(rng, v)), 1, 0.15, False, ("peak", -20.0),
                        "one stitch of the tatreez end card and chapter card stitching itself in; bus effects",
                        "a 2 ms puncture click, then micro-clicks accelerating from about 250 to 900 a second under a faint friction hiss; length and rate differ per variant"))
SOUNDS += [
    Entry("door_wood", door_wood, 1, 0.8, False, ("peak", -10.0),
          "the home's wooden door; bus effects",
          "a latch click through 2.4 and 3.9 kHz resonances, a push of air, a knock plus low-passed noise plus three damped panel modes at 0.36 s, frame rattle, a short hallway reflection"),
    Entry("grab", grab, 1, 0.2, False, ("peak", -14.0),
          "hands closing on the jerrycan handle (and other carryables); bus effects",
          "skin-on-plastic noise, a click through a 450 Hz body and a 1.9 kHz plastic ring, the hollow can at 190 Hz, a smaller second tock"),
    Entry("drop_heavy", drop_heavy, 1, 0.5, False, ("peak", -6.0),
          "a full jerrycan set down; bus effects",
          "a 90 to 45 Hz thump, low-passed noise body, a plastic slap, a damped 150 Hz can resonance, water sloshing at 4.2 Hz and grit"),
    Entry("kite_flap", kite_flap, 1, 1.5, False, ("peak", -16.0),
          "the plastic-bag kite fluttering in the wind; bus effects",
          "crackles at a flap rate wandering 8 to 20 a second with the gust, each with 4 to 9 kHz crinkles and a small pop, over wind on the bag"),
]


def level_text(level: tuple[str, float]) -> str:
    return f"{'RMS' if level[0] == 'rms' else 'peak'} {level[1]:g} dBFS"


def build(only: list[str] | None) -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    for e in SOUNDS:
        if only and e.name not in only:
            continue
        x = e.fn(np.random.default_rng(e.seed))
        if e.channels == 1 and x.ndim == 2:
            x = x.mean(axis=1)
        if e.channels == 2 and x.ndim == 1:
            x = np.stack([x, x], axis=1)
        assert not np.isnan(x).any(), e.name
        write_wav(e.path, x, e.loop, np.random.default_rng(e.seed + 1))
        print(f"wrote {e.name + '.wav':26s} {x.shape[0] / SR:6.2f} s  {e.channels}ch  peak {to_db(peak(x)):6.1f}  rms {to_db(rms(x)):6.1f} dBFS")
    write_readme()


def write_readme() -> None:
    lines = [
        "# game/assets/audio",
        "",
        "Every file in this folder was generated by `tools/audio.py` (numpy and scipy, fixed seeds). "
        "There is no recorded, downloaded or AI-generated material here: everything is world sound "
        "synthesised from noise, impulses, resonances and envelopes. No instruments and nothing that "
        "imitates one. Regenerate with `.venv/bin/python tools/audio.py`; verify with `--check`.",
        "",
        "`roof_breath_loop.wav` is a PLACEHOLDER for the friend's recorded vocal pad: it is breath and "
        "air through moving formants, with no fundamental, and it is listed as a placeholder in "
        "docs/rights.md. Replace it before any build leaves the machine.",
        "",
        "Format: 48 kHz, 16-bit PCM, TPDF-dithered. Loop files are exactly periodic; the file carries one "
        "extra frame (a copy of the first) and a `smpl` chunk looping (0, N], which Godot reads under "
        "its default \"Detect From WAV\" import setting, so no .import edit is needed for looping. "
        "Godot 4.7's default WAV import compresses to Quite OK Audio; set `compress/mode=0` in the "
        ".import of any file that must stay PCM (the strike is the candidate).",
        "",
        "| File | Seconds | Channels | Loop | Level | For | How it was synthesised |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for e in SOUNDS:
        lines.append(f"| `{e.name}.wav` | {e.seconds:g} | {e.channels} | {'yes' if e.loop else 'no'} | {level_text(e.level)} | {e.purpose} | {e.how} |")
    lines += ["", "Buses: voices, ambience, effects, rumble, strike (created by `scripts/core/sound.gd`). "
              "Nothing in this folder ever plays under recitation.", ""]
    with open(os.path.join(OUT_DIR, "README.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def check() -> int:
    readme_path = os.path.join(OUT_DIR, "README.md")
    readme = open(readme_path, encoding="utf-8").read() if os.path.exists(readme_path) else ""
    header = f"{'file':26s} {'ch':>2s} {'secs':>6s} {'loop':4s} {'peak':>6s} {'rms':>6s} {'seam dB/step':>13s}  status"
    print(header)
    print("-" * len(header))
    failures = 0
    for e in SOUNDS:
        problems: list[str] = []
        if not os.path.exists(e.path):
            print(f"{e.name + '.wav':26s} MISSING")
            failures += 1
            continue
        info = read_wav(e.path)
        x = info["samples"]
        frames = x.shape[0] - (1 if e.loop else 0)
        dur = frames / SR
        if info["rate"] != SR:
            problems.append(f"rate {info['rate']}")
        if info["bits"] != 16:
            problems.append(f"bits {info['bits']}")
        if info["channels"] != e.channels:
            problems.append(f"channels {info['channels']}")
        if abs(dur - e.seconds) > 0.05 * e.seconds:
            problems.append(f"duration {dur:.2f}")
        pk = to_db(peak(x))
        rm = to_db(rms(x))
        if pk > -0.5:
            problems.append("peak over -0.5")
        target = e.level[1]
        measured = pk if e.level[0] == "peak" else rm
        if abs(measured - target) > 1.0:
            problems.append(f"level {measured:.1f} vs {target:g}")
        seam = ""
        if e.loop:
            lp = info["loop"]
            if lp is None or lp[0] != 0 or lp[1] != 0 or lp[2] != frames:
                problems.append(f"smpl {lp}")
            if np.any(x[frames] != x[0]):
                problems.append("last frame is not a copy of the first")
            w = seconds(0.005)
            tail = x[frames - w:frames]
            head = x[1:1 + w]
            d_db = abs(to_db(rms(tail)) - to_db(rms(head)))
            steps = np.abs(np.diff(x[:frames], axis=0))
            ref = float(np.percentile(steps, 99.9)) + 1e-9
            seam_step = max(float(np.max(np.abs(x[0] - x[frames - 1]))), float(np.max(np.abs(x[1] - x[0]))))
            ratio = seam_step / ref
            if d_db > 6.0 or ratio > 1.5:
                problems.append(f"seam {d_db:.1f} dB, step x{ratio:.2f}")
            seam = f"{d_db:4.1f} / {ratio:4.2f}"
        if f"`{e.name}.wav`" not in readme:
            problems.append("not in README")
        status = "ok" if not problems else "FAIL: " + "; ".join(problems)
        failures += bool(problems)
        print(f"{e.name + '.wav':26s} {info['channels']:>2d} {dur:6.2f} {'loop' if e.loop else '    '} {pk:6.1f} {rm:6.1f} {seam:>13s}  {status}")
    print("-" * len(header))
    print(f"audio check: {len(SOUNDS) - failures} ok, {failures} failed")
    return 1 if failures else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="reload every file and assert the contract")
    ap.add_argument("--only", nargs="*", help="generate only these names")
    args = ap.parse_args()
    if args.check:
        return check()
    build(args.only)
    return 0


if __name__ == "__main__":
    sys.exit(main())
