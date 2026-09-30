# Audio direction

Status: the **halal rules and the voice-only score are LOCKED** (`docs/gdd.md`, Audio; `docs/decisions.md`). **How each sound is made is PROPOSED for the lock.** The founder's note from playtest 1: "sounds feel weird". Cause: every sound in the first playable was synthesised from noise by `tools/audio.py`.

## The rules (locked, summarised)

- No instruments, ever, and nothing that imitates one. The duff only at the wedding, on the women's side.
- The score is human voices and the world: the friend's voice (a cappella lines, hums, held vowels layered into pads that must audibly be a voice), the adhan, the count, voices of the street.
- Quran is a full stop: gameplay paused, every bus silent, text on screen with its reference, skip only at an ayah boundary; audio only from a human reciter under a written licence, otherwise text only. Never AI.
- No AI-generated audio, voices, Quran or music ships or enters the repository.
- A real, close strike once per strike day (Days 3 and 7), then silence, ringing and dust. No sound under recitation.
- The zanana: absent on Day 1, a first faint hum on Day 2, the bed of every siege day, gone on the final beach.

## The course: what makes each sound

| Kind | Made by | Status today | For the slice |
| --- | --- | --- | --- |
| Voice score (sit spots, the roof, the ending) | The friend, recorded | Placeholder breath pad (`roof_breath_loop.wav`) | **Record.** The takes list below |
| The adhan (every phase turn) | A human muezzin or the friend, recorded with permission | None | **Record** fajr, dhuhr, asr, maghrib, isha |
| The count to thirty | Many voices: family, friends, children with consent, layered | None | **Record** (Day 1 and Day 10 use it) |
| Character voices (barks, laughter, calls, efforts) | Arabic speakers, ideally Palestinian, recorded | None | **Record** a small set per character (below); dialogue itself stays subtitled |
| Foley (steps, cloth, paper, jerrycan, bread, doors, kites, knots) | Recorded by the founder with a phone or recorder in a quiet room | Synthesised | **Record**, replacing the synthesised files one for one |
| Ambience (sea, wind, beach crowd, street, market, harbour) | Field recordings with provenance we can show (CC0 or our own), downloaded or recorded on the founder's machine (the cloud container cannot reach Freesound) | Synthesised sea and wind | **Replace** with field recordings; keep synthesis only to follow the wind field |
| The drone, the rumble | Synthesised, because they follow a 0-to-1 intensity every frame | Synthesised | Keep; tune |
| The strike | A recorded CC0 or licensed explosion (Sonniss, Freesound CC0), designed and layered | Synthesised | Replace before Day 3 is built |
| Quran and hadith cards | A human reciter under a written licence, or silence with text | Text only | Text only in the slice |

Synthesis stays only where a sound must follow a parameter in real time. Everything else is recorded by people, which is also the honest answer to "no generative AI".

## Recording plan

**The friend's session (first, in lock week 1 or 2).** A quiet room, a phone on a folded towel 30 cm away, no reverb. Takes: the main theme hummed three times at slow, medium and fast tempo; held vowels (a, o, u, e) on eight pitches, five seconds each; soft breaths; a cappella lines if the friend sings in Arabic (otherwise wordless); zaghareet if appropriate; claps and foot stamps for the dabke. Before recording: the founder confirms with the scholar who may be heard and where (a woman's singing voice before a mixed audience is the highest halal risk in the plan; the design document's Teta's songs rule).

**Layla's sung lines, if any.** Only a young girl before puberty sings, with a parent's consent, or Teta speaks the lyric as poetry over a vocal drone (Decision 4). The scholar signs off.

**Character barks (Day 1 set).** Layla: laugh, "yalla", "wallahi", effort on climb and jump, "Teta!", breath while running. Sami: laugh, "ya bint 'ammi", a cheer, "my kite!". Teta: a laugh, a tut, "ya Allah", "bismillah". Baba: a grunt of effort, a low laugh. Mama: "Layla!" from far away, "yalla". Karim: a yawn, "why is everyone shouting". The crowd: a cheer, the count. Recorded by Arabic speakers; Gazan accents ideally, reviewed by the readers.

**Foley (founder, one afternoon).** Sandals on sand and on concrete (walk, run, land), bare feet on a roof, a plastic bag kite in wind (a fan works), string on a reel, a knot pulled tight, bread torn, a tray set down, a door and a latch, a sewing tin, paper and a notebook page, cloth and a scarf, a plastic jerrycan empty and full (slosh, set down), a gas ring, a fridge starting, a ceiling fan, keys on a cord, a cat's feet if one is around. Phone on a tripod or a folded towel, 20 to 40 cm away, five takes each.

## Mix

Buses stay as built: voices, ambience, effects, rumble, strike (`game/scripts/core/sound.gd`). Loudness target about -16 LUFS integrated for the whole mix on the founder's laptop speakers and headphones, dialogue-free scenes quieter. The strike and rumble have their own sliders. Every audio telegraph (birds, rumble, hum, loudhailer) has a caption.

## Rights

Every file gets a row in `docs/rights.md` with source, licence, date and who approved it before it is merged. Recording consent forms are kept by the founder.
