#!/usr/bin/env python3
"""Generate SUMUD's world sounds with ElevenLabs sound effects and write them to the audio
contract (48 kHz, 16-bit PCM, the README's levels, smpl loop chunks), so `tools/audio.py
--check` and `game/tests/test_audio` keep passing.

    ELEVENLABS_API_KEY=... .venv/bin/python tools/eleven.py            # every generated sound
    .venv/bin/python tools/eleven.py footstep_sand kite_flap            # some of them
    .venv/bin/python tools/eleven.py --dry                              # print the plan and cost

Rules (lock F-09, G-01): never Quran, never music, nothing that imitates an instrument, no
voices for characters. Only world sound is generated here. The drone, the rumble and the
ringing stay synthesised (they follow a parameter in real time); `roof_breath_loop` stays
the placeholder for the friend's recording.

Raw responses are cached under `--cache` (default: `$SUMUD_AUDIO_CACHE` or `.cache/eleven`
beside the repo) keyed by a hash of the prompt, so re-running does not spend credits. Each
generated second costs 40 characters of the account's quota; `--dry` sums it.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass

import numpy as np
from scipy.signal import resample_poly

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audio as A  # noqa: E402  (the synthesiser: SR, write_wav, read_wav, levels)

API = "https://api.elevenlabs.io/v1/sound-generation?output_format=pcm_44100"
MODEL = "eleven_text_to_sound_v2"
GEN_SR = 44100
MIN_TAKE = 0.5
MAX_TAKE = 22.0
CHARS_PER_SECOND = 40
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MANIFEST = os.path.join(A.OUT_DIR, "generated.json")

NEGATIVE = " No music, no instruments, no voices, no speech."


@dataclass
class Gen:
    name: str            # output name, or the family name for variants (footstep_sand)
    prompt: str
    take: float          # seconds asked from the model per take
    seconds: float       # output length per file
    channels: int
    loop: bool
    level: tuple[str, float]
    variants: int = 1    # >1: slice one take into N files name_1..name_N at onsets
    influence: float = 0.45
    fade_out: float = 0.0  # one-shots: raised-cosine fade over the last part, seconds
    trim_db: float = 40.0  # one-shots start where the take first rises within this of its peak
    align_peak: bool = False  # one-shots: start 20 ms before the loudest sample instead

    def files(self) -> list[str]:
        if self.variants > 1:
            return [f"{self.name}_{i}" for i in range(1, self.variants + 1)]
        return [self.name]

    def takes(self) -> int:
        return 2 if (self.loop and self.channels == 2) else 1

    def cost_chars(self) -> int:
        return int(round(self.take * self.takes() * CHARS_PER_SECOND))


CATALOGUE: list[Gen] = [
    Gen("strike_bang",
        "One single enormous explosion very close by: an airstrike hitting a concrete apartment "
        "building. A sharp shock crack, then collapsing concrete, glass shattering and falling, "
        "rubble and grit raining down, dust pouring, a long decay into dust and silence. "
        "Realistic, recorded outdoors on a street." + NEGATIVE,
        6.0, 6.0, 2, False, ("peak", -1.0), influence=0.5, fade_out=0.6, align_peak=True),
    Gen("birds_leave",
        "A flock of pigeons and sparrows bursting into flight from a flat rooftop all at once, "
        "many wings clapping and flapping, then fading away into the distance. Realistic, "
        "outdoors, quiet city air." + NEGATIVE,
        4.0, 4.0, 2, False, ("peak", -6.0), fade_out=0.8, trim_db=18.0),
    Gen("wind_loop",
        "Steady coastal wind on an open beach, gusting gently, low pressure and soft hiss, "
        "seamless loop, no sea waves, no birds, realistic field recording." + NEGATIVE,
        MAX_TAKE, 20.0, 2, True, ("rms", -26.0), influence=0.4),
    Gen("sea_loop",
        "The Mediterranean sea on a sandy beach: calm medium waves rolling in, breaking softly "
        "and hissing back over the sand, with a distant surf bed, seamless loop, realistic "
        "field recording, no wind noise on the microphone, no birds." + NEGATIVE,
        MAX_TAKE, 20.0, 2, True, ("rms", -24.0), influence=0.4),
    Gen("candle_out",
        "A small candle flame blown out by a short puff of breath, very close, then a faint "
        "hiss of the wick. Quiet room." + NEGATIVE,
        1.0, 0.6, 1, False, ("peak", -18.0), fade_out=0.15),
    Gen("footstep_sand",
        "Four separate slow footsteps of sandals on dry soft beach sand, evenly spaced about "
        "half a second apart, very close and dry, no reverb, nothing else." + NEGATIVE,
        3.0, 0.25, 1, False, ("peak", -14.0), variants=4, influence=0.6, fade_out=0.08),
    Gen("footstep_concrete",
        "Four separate footsteps of sandals on a hard concrete pavement, evenly spaced about "
        "half a second apart, very close and dry, a little grit, no reverb, nothing else." + NEGATIVE,
        3.0, 0.25, 1, False, ("peak", -12.0), variants=4, influence=0.6, fade_out=0.08),
    Gen("cloth_rustle",
        "A short rustle of cotton clothing as a person crouches down, very close, quiet, dry "
        "room, nothing else." + NEGATIVE,
        1.0, 0.5, 1, False, ("peak", -18.0), fade_out=0.15),
    Gen("paper_page",
        "A single page of a small paper notebook being turned by hand, close, a quiet room, "
        "nothing else." + NEGATIVE,
        1.0, 0.8, 1, False, ("peak", -14.0), fade_out=0.2),
    Gen("stitch",
        "Three quick separate stitches of a needle pulling embroidery thread through stretched "
        "cloth, tiny and very close, evenly spaced about half a second apart, nothing else." + NEGATIVE,
        2.0, 0.15, 1, False, ("peak", -20.0), variants=3, influence=0.6, fade_out=0.05),
    Gen("door_wood",
        "An old wooden apartment door: the latch clicks and the door is pushed open with a short "
        "creak, close, a small concrete hallway, nothing else." + NEGATIVE,
        1.5, 0.8, 1, False, ("peak", -10.0), fade_out=0.2),
    Gen("grab",
        "A hand grabbing the handle of an empty plastic jerrycan: one short plastic tock and a "
        "little hollow ring, very close, nothing else." + NEGATIVE,
        1.0, 0.2, 1, False, ("peak", -14.0), influence=0.6, fade_out=0.06),
    Gen("drop_heavy",
        "A full twenty litre plastic water container set down heavily on concrete: a deep thump, "
        "a plastic slap and water sloshing inside, close, nothing else." + NEGATIVE,
        1.0, 0.5, 1, False, ("peak", -6.0), influence=0.55, fade_out=0.12),
    Gen("kite_flap",
        "A homemade plastic bag kite fluttering and crackling fast in a steady wind, close, "
        "outdoors, nothing else." + NEGATIVE,
        2.0, 1.5, 1, False, ("peak", -16.0), fade_out=0.3),
]


# --------------------------------------------------------------------------------------
# The API
# --------------------------------------------------------------------------------------

def cache_dir(arg: str | None) -> str:
    d = arg or os.environ.get("SUMUD_AUDIO_CACHE") or os.path.join(REPO, ".cache", "eleven")
    os.makedirs(d, exist_ok=True)
    return d


def take_key(g: Gen, take: int) -> str:
    h = hashlib.sha1(f"{MODEL}|{g.prompt}|{g.take}|{g.influence}|{g.loop}|{take}".encode()).hexdigest()[:12]
    return f"{g.name}_{take}_{h}.pcm"


def fetch(g: Gen, take: int, cache: str, key: str | None) -> np.ndarray:
    path = os.path.join(cache, take_key(g, take))
    if not os.path.exists(path):
        if not key:
            raise SystemExit("ELEVENLABS_API_KEY is not set and no cached take for " + g.name)
        body = {"text": g.prompt, "duration_seconds": float(min(MAX_TAKE, max(MIN_TAKE, g.take))),
                "prompt_influence": g.influence, "model_id": MODEL}
        if g.loop:
            body["loop"] = True
        raw = _post(body, key)
        if raw is None and g.loop:
            body.pop("loop")
            raw = _post(body, key)
        if raw is None:
            raise SystemExit("ElevenLabs refused " + g.name)
        with open(path, "wb") as fh:
            fh.write(raw)
        print(f"  fetched {g.name} take {take}: {len(raw) / 2 / GEN_SR:.1f} s")
    pcm = np.frombuffer(open(path, "rb").read(), dtype="<i2").astype(np.float64) / 32768.0
    return resample_poly(pcm, A.SR, GEN_SR)


def _post(body: dict, key: str) -> bytes | None:
    req = urllib.request.Request(API, data=json.dumps(body).encode(), method="POST",
                                 headers={"xi-api-key": key, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors="replace")[:300]
        print(f"  HTTP {e.code}: {msg}", file=sys.stderr)
        if e.code in (400, 422):
            return None
        raise


# --------------------------------------------------------------------------------------
# Shaping
# --------------------------------------------------------------------------------------

def trim_start(x: np.ndarray, db_below_peak: float = 40.0, pre: float = 0.008, align_peak: bool = False) -> np.ndarray:
    """Drops the silence the model leaves before a one-shot."""
    if align_peak:
        idx = int(np.argmax(np.abs(x)))
        return x[max(0, idx - A.seconds(0.02)):]
    thr = A.peak(x) * A.db(-db_below_peak)
    idx = np.argmax(np.abs(x) > thr)
    return x[max(0, int(idx) - A.seconds(pre)):]


def crest_db(x: np.ndarray) -> float:
    return A.to_db(A.peak(x)) - A.to_db(A.rms(x))


def vary(x: np.ndarray, ratio: float) -> np.ndarray:
    """A slightly slower or faster copy of a clip (a few percent), for variants when the
    take did not hold enough clean onsets."""
    n = max(8, int(round(x.shape[0] * ratio)))
    return np.interp(np.linspace(0.0, x.shape[0] - 1, n), np.arange(x.shape[0]), x)


def cut(x: np.ndarray, secs: float, fade_out: float) -> np.ndarray:
    n = A.seconds(secs)
    y = np.zeros(n)
    m = min(n, x.shape[0])
    y[:m] = x[:m]
    if fade_out > 0:
        f = min(n, A.seconds(fade_out))
        ramp = 0.5 * (1.0 + np.cos(np.linspace(0.0, np.pi, f)))
        y[n - f:] *= ramp
    return A.fade(y, 2.0, 2.0)


def onsets(x: np.ndarray, count: int, min_gap: float) -> list[int]:
    """The `count` strongest onsets at least `min_gap` apart, in time order."""
    w = A.seconds(0.004)
    env = np.sqrt(np.convolve(x * x, np.ones(w) / w, mode="same"))
    rise = np.maximum(env - np.roll(env, A.seconds(0.03)), 0.0)
    rise[: A.seconds(0.03)] = 0.0
    picks: list[int] = []
    gap = A.seconds(min_gap)
    order = np.argsort(-rise)
    for i in order:
        if rise[i] <= 0.0:
            break
        if all(abs(int(i) - p) >= gap for p in picks):
            picks.append(int(i))
            if len(picks) == count:
                break
    picks.sort()
    if len(picks) < count:  # fall back to an even split of the take
        step = x.shape[0] // count
        picks = [k * step for k in range(count)]
    return picks


def make_loop(x: np.ndarray, secs: float, xfade: float) -> np.ndarray:
    """Takes `secs` from the start and crossfades the material that follows into the head,
    so the file loops seamlessly (equal-power ramps, fine for noise-like ambience)."""
    n = A.seconds(secs)
    f = A.seconds(xfade)
    if x.shape[0] < n + f:
        f = max(A.seconds(0.2), x.shape[0] - n)
    core = x[:n].copy()
    tail = x[n:n + f]
    up = np.sin(np.linspace(0.0, np.pi / 2, f)) ** 2
    core[:f] = core[:f] * up + tail * (1.0 - up)
    return core


def widen(mono: np.ndarray, delay_ms: float = 9.0, amount: float = 0.35, after: float = 0.0) -> np.ndarray:
    """Pseudo-stereo for a mono one-shot: the right channel blends in a short delay. With
    `after`, the first part stays identical in both channels (a strike's front)."""
    d = A.seconds(delay_ms / 1000.0)
    delayed = np.concatenate([np.zeros(d), mono[:-d]]) if d < mono.shape[0] else mono
    blend = np.full(mono.shape[0], amount)
    if after > 0:
        k = A.seconds(after)
        blend[:k] = 0.0
        ramp = min(k, A.seconds(0.15))
        blend[k:k + ramp] = np.linspace(0.0, amount, ramp)
    right = mono * (1.0 - blend) + delayed * blend
    return A.stereo(mono, right)


def level(x: np.ndarray, lv: tuple[str, float]) -> np.ndarray:
    return A.normalise_peak(x, lv[1]) if lv[0] == "peak" else A.normalise_rms(x, lv[1])


def build(g: Gen, cache: str, key: str | None, rng: np.random.Generator) -> list[str]:
    outs: list[str] = []
    if g.loop:
        xfade = 2.0
        takes = [fetch(g, t, cache, key) for t in range(g.takes())]
        loops = [make_loop(t, g.seconds, xfade) for t in takes]
        if g.channels == 2:
            a, b = loops[0], loops[1]
            y = A.stereo(0.8 * a + 0.2 * b, 0.2 * a + 0.8 * b)
        else:
            y = loops[0]
        y = level(y, g.level)
        A.write_wav(os.path.join(A.OUT_DIR, g.name + ".wav"), y, True, rng)
        outs.append(g.name)
        return outs
    x = fetch(g, 0, cache, key)
    if g.variants > 1:
        starts = onsets(x, g.variants, min_gap=max(0.3, g.seconds * 1.2))
        clips = [cut(trim_start(x[max(0, s - A.seconds(0.02)):], g.trim_db), g.seconds, g.fade_out) for s in starts]
        # A slice that caught silence (a flat crest once normalised) is replaced by a
        # varied copy of the cleanest slice.
        good = [c for c in clips if crest_db(c) >= 8.0]
        if not good:
            good = [max(clips, key=crest_db)]
        best = max(good, key=crest_db)
        ratios = [1.0, 0.96, 1.04, 0.92, 1.08]
        for i, c in enumerate(clips, 1):
            if crest_db(c) < 8.0:
                c = cut(vary(best, ratios[i % len(ratios)]), g.seconds, g.fade_out)
            c = level(c, g.level)
            A.write_wav(os.path.join(A.OUT_DIR, f"{g.name}_{i}.wav"), c, False, rng)
            outs.append(f"{g.name}_{i}")
        return outs
    y = cut(trim_start(x, g.trim_db, align_peak=g.align_peak), g.seconds, g.fade_out)
    if g.channels == 2:
        y = widen(y, after=0.25 if g.name == "strike_bang" else 0.0)
    y = level(y, g.level)
    A.write_wav(os.path.join(A.OUT_DIR, g.name + ".wav"), y, False, rng)
    outs.append(g.name)
    return outs


# --------------------------------------------------------------------------------------
# Manifest and README
# --------------------------------------------------------------------------------------

def update_manifest(done: dict[str, Gen], date: str) -> None:
    m = json.load(open(MANIFEST)) if os.path.exists(MANIFEST) else {}
    for name, g in done.items():
        m[name] = {"model": MODEL, "provider": "ElevenLabs sound effects", "date": date,
                   "prompt": g.prompt, "take_seconds": g.take, "prompt_influence": g.influence,
                   "loop": g.loop, "variants_of": g.name if g.variants > 1 else None}
    json.dump(dict(sorted(m.items())), open(MANIFEST, "w"), indent=1, ensure_ascii=False)


def update_readme(done: dict[str, Gen]) -> None:
    path = os.path.join(A.OUT_DIR, "README.md")
    if not os.path.exists(path):
        return
    lines = open(path, encoding="utf-8").read().split("\n")
    for i, l in enumerate(lines):
        for name, g in done.items():
            if l.startswith(f"| `{name}.wav` |"):
                cells = l.split(" | ")
                cells[-1] = (f"ElevenLabs sound effects ({MODEL}), shaped by `tools/eleven.py` "
                             f"(prompt in `generated.json`) |")
                lines[i] = " | ".join(cells)
    open(path, "w", encoding="utf-8").write("\n".join(lines))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("names", nargs="*", help="catalogue names (families for variants); default all")
    ap.add_argument("--dry", action="store_true", help="print the plan and the credit cost only")
    ap.add_argument("--cache", help="directory for raw takes")
    ap.add_argument("--date", default="2026-10-01")
    args = ap.parse_args()
    todo = [g for g in CATALOGUE if not args.names or g.name in args.names]
    unknown = set(args.names) - {g.name for g in CATALOGUE}
    if unknown:
        raise SystemExit("unknown: " + ", ".join(sorted(unknown)))
    total = sum(g.cost_chars() for g in todo)
    for g in todo:
        print(f"{g.name:20s} {g.takes()} take(s) x {g.take:4.1f} s -> {', '.join(g.files())}  ({g.cost_chars()} chars)")
    print(f"total: {total} characters ({total / CHARS_PER_SECOND:.0f} s)")
    if args.dry:
        return 0
    key = os.environ.get("ELEVENLABS_API_KEY")
    cache = cache_dir(args.cache)
    rng = np.random.default_rng(11)
    done: dict[str, Gen] = {}
    for g in todo:
        print("==", g.name)
        for f in build(g, cache, key, rng):
            done[f] = g
    update_manifest(done, args.date)
    update_readme(done)
    print(f"wrote {len(done)} files to {A.OUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
