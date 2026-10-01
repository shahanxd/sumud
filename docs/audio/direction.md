# Audio direction

Status: the **halal rules and the voice-only score are LOCKED** (`docs/gdd.md`, Audio; `docs/decisions.md`). **How each sound is made is PROPOSED for the lock.** The founder's note from playtest 1: "sounds feel weird". Cause: every sound in the first playable was synthesised from noise by `tools/audio.py`.

## The rules (locked, summarised)

- No instruments, ever, and nothing that imitates one. The duff only at the wedding, on the women's side.
- The score is human voices and the world: the friend's voice (a cappella lines, hums, held vowels layered into pads that must audibly be a voice), the adhan, the count, voices of the street.
- Quran is a full stop: gameplay paused, every bus silent, text on screen with its reference, skip only at an ayah boundary; audio only from a human reciter under a written licence, otherwise text only. Never AI.
- No AI Quran, ever. No AI music or anything that imitates an instrument. Generated sound effects and ambience are allowed from 1 October 2026 (lock F-01, F-09) and the route is **ElevenLabs on the founder's account** (G-01, locked 1 October). Each scripture moment gets an empty audio slot (`game/assets/audio/quran/<moment>.ogg`, text card until the file exists) that the founder fills by hand with a licensed human recording. The friend (a song performer, named later) sings only the songs; a young girl with consent sings Layla's lines (G-02, G-04); the founder does the scholar review (E-05).
- A real, close strike on Day 3, then silence, ringing and dust. Day 7's strike is distant: a heavy rumble and dust over the road, no close impact. No sound under recitation.
- Any spoken ayah (Teta's whisper on Day 3, the words at the gate on Day 7, the nikah on Day 10) is a full stop like a card: input paused, every bus silent including the drone and the rumble, the complete ayah, then play resumes.
- The zanana: absent on Day 1, a first faint hum on Day 2, the bed of every siege day, gone on the final beach.

## The course: what makes each sound

| Kind | Made by | Status today | For the slice |
| --- | --- | --- | --- |
| Voice score (sit spots, the roof, the ending) | The friend, recorded | Placeholder breath pad (`roof_breath_loop.wav`) | **Record.** The takes list below |
| The adhan (every phase turn) | A human muezzin or the friend, recorded with permission | None | **Record** fajr, dhuhr, asr, maghrib, isha |
| The count to thirty | Many voices: family, friends, children with consent, layered | None | **Record** (Day 1 and Day 10 use it) |
| Character voices (barks, laughter, calls, efforts) | Arabic speakers, ideally Palestinian, recorded | None | **Record** a small set per character (below); dialogue itself stays subtitled |
| Foley (steps, cloth, paper, jerrycan, bread, doors, kites, knots) | Generated with ElevenLabs sound effects (the founder's account; Weave needs a paid plan) or recorded by the founder; whichever sounds truer in the game | Synthesised | **Generate first**, replacing the synthesised files one for one; record what the model gets wrong |
| Ambience (sea, wind, beach crowd, street, market, harbour) | Generated loops (audio model) or field recordings with provenance (CC0 or our own) | Synthesised sea and wind | **Replace** with generated or field loops; keep synthesis only to follow the wind field |
| The drone, the rumble | Synthesised, because they follow a 0-to-1 intensity every frame | Synthesised | Keep; tune |
| The strike | A generated or CC0 explosion, designed and layered | Synthesised | Replace before Day 3 is built |
| Quran and hadith cards | A human reciter under a written licence, or silence with text | Text only | Text only in the slice |

Synthesis stays only where a sound must follow a parameter in real time. Everything else is generated or recorded, reviewed in the game, and listed in `docs/rights.md` with the model named.

## Recording plan

**The friend's session (first, in lock week 1 or 2).** A quiet room, a phone on a folded towel 30 cm away, no reverb. Takes: the main theme hummed three times at slow, medium and fast tempo; held vowels (a, o, u, e) on eight pitches, five seconds each; soft breaths; a cappella lines if the friend sings in Arabic (otherwise wordless); zaghareet if appropriate; foot stamps and voices for the dabke (claps only if the scholar approves; Decision 3). Before recording: the founder confirms with the scholar who may be heard and where (a woman's singing voice before a mixed audience is the highest halal risk in the plan; the design document's Teta's songs rule).

**Layla's sung lines, if any.** Only a young girl before puberty sings, with a parent's consent, or Teta speaks the lyric as poetry over a vocal drone (Decision 4). The scholar signs off.

**Character barks (Day 1 set).** Layla: laugh, "yalla", "wallahi", effort on climb and jump, "Teta!", breath while running. Sami: laugh, "ya bint 'ammi", a cheer, "my kite!". Teta: a laugh, a tut, "ya Allah", "bismillah". Baba: a grunt of effort, a low laugh. Mama: "Layla!" from far away, "yalla". Karim: a yawn, "why is everyone shouting". The crowd: a cheer, the count. Recorded by Arabic speakers; Gazan accents ideally, reviewed by the readers.

**Foley (founder, one afternoon).** Sandals on sand and on concrete (walk, run, land), bare feet on a roof, a plastic bag kite in wind (a fan works), string on a reel, a knot pulled tight, bread torn, a tray set down, a door and a latch, a sewing tin, paper and a notebook page, cloth and a scarf, a plastic jerrycan empty and full (slosh, set down), a gas ring, a fridge starting, a ceiling fan, keys on a cord, a cat's feet if one is around. Phone on a tripod or a folded towel, 20 to 40 cm away, five takes each.

## Mix

Buses stay as built: voices, ambience, effects, rumble, strike (`game/scripts/core/sound.gd`). Loudness target about -16 LUFS integrated for the whole mix on the founder's laptop speakers and headphones, dialogue-free scenes quieter. The strike and rumble have their own sliders. Every audio telegraph (birds, rumble, hum, loudhailer) has a caption.

## Rights

Every file gets a row in `docs/rights.md` with source, licence, date and who approved it before it is merged. Recording consent forms are kept by the founder.
