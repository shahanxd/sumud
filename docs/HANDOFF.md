# Handoff: where SUMUD stands on 29 September 2026

Read this first when picking the project up in a new session.

## The founder

shahanxd (GitHub). Indian, a practising Muslim; everything in the game must be halal. No art or audio budget; a friend may sing; will pay the Steam fee. Writes informally, wants the blunt truth and maximum effort, delegates judgement ("you decide") when given a recommendation, and asked for self-proofreading before anything is delivered. Creator credit: shahanxd.

## Where things live

- **Design document (living, commentable):** https://claude.ai/code/artifact/edb009e1-ac2b-462a-8860-f031366c2ec2 — a Claude Doc. Doc id `edb009e1-ac2b-462a-8860-f031366c2ec2`, tab file id `97c63c3c-32af`, body node id `dc81e545-7518`. Edit it with the docs tools, not by publishing HTML. A snapshot is in `docs/gdd.md` (rev 34).
- **Research, verification and critiques:** `docs/research/`, numbered. 00 is the original v0.1 doc plus the founder's full feedback. 01 to 08 are research lenses, 09 to 12 critiques, 13 to 18 independent verification passes. Nothing in the doc should contradict 13 to 18.
- **Decisions log:** `docs/decisions.md`. **Rights ledger:** `docs/rights.md`. **Outreach drafts** (readers, testers): `docs/outreach.md`.

## The founder's answers of 29 September (locked)

Limbo as the art base, with more colour carried by light; Godot; the cast as designed; ten days; English and Arabic at launch; player kites in the ending; title SUMUD for now; one death and Karim's choice; no combat; the perpetrator is "they", faceless but present (soldiers, gunboats, drones may be shown indirectly), and the game must feel defiant, not cowardly; children's deaths may be shown; absolutely halal, so no instruments, Quran or hadith quietly at related moments, halal nasheed instead of music; real explosion sound is fine; mobile one day, Steam first; surprise moments and cinematics only where they work; The Kite Runner as a liked reference, not a template; prototype this week, final game in two to three months; charity "yes, 100%" (meaning to be clarified); repo stays local with regular commits (the founder has now asked to continue in the cloud).

## What was done in this session

1. Researched and fact-checked everything in the first draft with seven research agents, then re-verified each finding with independent checkers (all 20 checked scripture references confirmed on quran.com and sunnah.com). Big corrections: kite fighting with glass string is not a Gaza practice (cut); the three-mile fishing limit was true only 2009 to 2012 and the sea has been closed since 2025; the family name Haddad is retired (a Qassam commander of that name was killed in Gaza City in May 2026), placeholder Awad; Gazan food corrected; no famous reciter's recording can ship; AI audio would need Steam disclosure and invites backlash; 31 December is the worst Steam date and forfeits Next Fest.
2. Rewrote the design doc to v0.2 section by section: vision, six pillars (new halal pillar; "they have no face, but they are there"), tone and ethics, story with a four-tentpole ten-day structure and Sami's arc, mechanics with concrete carry, kite, light and drone-sky rules, the honest colour answer, a voices-only audio design with Quran as a full stop, tech stack, a 13-week gated production plan with a timeline drawing, go-to-market, decisions for the founder, and sources.
3. Built the codebase (see below). Every commit passes `bash tools/check.sh`.

## What is left in the design document

1. **Fill the "Scripture moments" section.** It is still a pending block (id `m8nh6ahckeg.77617`, just before the Tech heading). Build it from `docs/research/03-scripture.md` and `18-scripture-checks.md`: a table of day, moment, reference, Arabic (clean Uthmani), Saheeh International or sunnah.com English, and grade. Follow the etiquette notes at the end of 03 (verse matches what is on screen; no verse over the unseen; no verse on fail screens or walls; show a complete clause). Items 20 (Bukhari 1284) and 22 (Ibn Majah 1896) were verified in the first pass but their second check did not run; re-open them on sunnah.com before publishing.
2. **Apply the two critiques not yet folded in:** `11-critic-culture-and-faith.md` and `12-critic-market.md`. Read both, apply what is right, and say in the doc where you disagreed.
3. **Small corrections from the verification passes** that the doc should reflect if it touches these topics: the UN Commission of Inquiry figures (about 20,179 children killed, 44,143 injured) cover 7 October 2023 to 7 October 2025 only; Liyla was rejected 18 May 2016, reversed by 20 May, live by 22 May; the 2025 BBC guidance now defaults to translating "yahud" literally; the Darul Ifta Birmingham view is duff for women only and disliked for men; the Standing Committee clapping fatwa is not about weddings.
4. **Proofread the whole doc once more** (the founder asked for this explicitly), then hand off with one line and the link.

## The codebase today

- `game/` Godot 4.7.2 project, Forward+ renderer, 2D MSAA. 2D HDR is off until the look-lock week sets up glow.
- `game/scenes/beach.tscn` beach greybox: global wind field (`scripts/wind.gd`, autoload `Wind`), player with carry rules and crawl (`scripts/player.gd`, `scripts/carryable.gd`), kite on a verlet string with a tail (`scripts/kite.gd`), code-built parallax skyline with minarets and water tanks (`scripts/skyline.gd`), sky and sea shaders, camera that frames the kite.
- `game/scenes/chapter_card.tscn` a card that embroiders a tatreez band stitch by stitch from `game/assets/tatreez/band_*.json`.
- `tools/tatreez.py` generates the tatreez bands (SVG, PNG, JSON). `tools/check.sh` runs import, smoke test, the 16-check beach bot and the chapter card test. `tools/setup_linux.sh` fetches the Linux Godot binary and the Python venv.
- Tests: `game/tests/smoke.gd`, `game/tests/bot_beach.tscn` (16 checks: run, jump, land, grab, heavy slows, heavy removes jump, drop, crawl under a wall, stand, kite launch, climb, player still while flying, steer, reel in), `game/tests/shot_beach.tscn` and `shot_card.tscn` (windowed screenshots; on a headless Linux box they need `xvfb-run` or will only run the logic).

## Next: Week 1 prototype (29 September to 5 October)

One continuous 8 to 12 minute playable, not a feature list. In order:

1. Beach: the kite fetches one item from a roof. Day 1 contest is making and flying, never cutting.
2. Street: one route puzzle where the jerrycan removes the jump so the route changes.
3. Home hub: Layla and Baba switch, one beam-and-gap puzzle (stretch).
4. Roof at dusk: a sit spot, one Teta line in Arabic and English (fonts: Amiri and Noto Naskh Arabic, SIL OFL; the founder has not yet approved the download), a code-built vocal pad placeholder.
5. First strike: birds leave, one real bang (Sonniss or Kenney CC0), white-out, one generous take-cover moment with an own-pace fallback.
6. Street at night: lit and dark windows from a data table, candle traversal where darkness is impassable.
7. A notebook entry written to JSON and the tatreez end card.
8. One hero shot of the beach at dusk with grain, dither and a proper sky.
9. The bot plays it end to end; a Windows export for the founder to hand to a stranger.

Gate: one stranger plays ten minutes with no instructions, understands carrying, names a moment that landed, no crash.

## Rules to keep

- Every session ends with a build that runs and a commit. Run `bash tools/check.sh` before committing.
- No instruments, ever. Voices, duff at the wedding only, world sound. No Quran under gameplay, music or effects; skip only at ayah boundaries. No AI-generated audio, voices, Quran or art ships.
- The perpetrator is never a character or a target. No combat mechanics.
- Sami's death is aftermath only, never preventable, never a fail state.
- Check facts against the verification files before writing them into the doc or the game.
