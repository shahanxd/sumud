# Handoff: start here

Where SUMUD stands on 30 September 2026, and how to pick it up in a new session or as a new agent. The repository is the source of truth; nothing needed to continue lives only in a chat.

## Where we are

**Stage: pre-production lock** (30 September to 13 October 2026). The first playable (a Day 1 sampler) is done and the founder has played it on Windows. Their verdict: "if my dream is v2.0, this is v0.2" — characters wooden, scarf and eyes weird, walk and jump weird, story dead, gameplay dry, cuts sudden, sounds weird. They asked to lock everything that cannot change before real production, and said yes to moving the launch date for quality. Nothing AI-generated is used for assets, even as placeholders. The plan: lock, then Day 1 as a vertical slice at shipping quality, then Day 3, then production (`docs/production/pipeline.md`).

**What is waiting on the founder:** answering the PROPOSED and OPEN rows of `docs/production/lock.md`, posting the calls in `docs/outreach.md` (artist, readers, performers), recording the friend, filming the animation test footage.

**What the next agent does (backlog in `pipeline.md`, in order):** the feel pass in the first playable; `tools/roto.py` and the SpriteFrames import tool; the animation test scene; in-engine style frames; then the Day 1 slice once the lock is signed. Work that is the founder's (decisions, recruiting, recording, filming) is never done for them.

## Reading order

1. `docs/production/lock.md` — every decision, its status and owner.
2. `docs/production/pipeline.md` — stages, the world-class tests, roles, lock weeks, backlog, risks.
3. `docs/playtests/2026-09-29-founder.md` — what the founder saw and said; lessons for every build.
4. `docs/story/beat-sheet.md`, `characters.md`, `world.md`, `day1-script.md` — the story as it will be built.
5. `docs/art/direction.md`, `docs/art/artist-brief.md`, `docs/audio/direction.md`, `docs/design/feel-and-readability.md` — how it will look, sound and play.
6. `docs/tech/codebase.md` — how to run, test, render and change the code.
7. `docs/gdd.md` — the design document (snapshot of the Claude Doc); `docs/decisions.md` — every decision by date; `docs/research/` — research and verification (13 to 18 are the fact check: nothing may contradict them); `docs/rights.md` — every asset's source and licence; `docs/outreach.md` — calls to post.

## The founder

shahanxd (GitHub). A practising Muslim; everything must be halal. Small budget: pays readers and the Steam fee; the artist's and reciter's terms are theirs to set; a friend may sing. Writes informally, wants the blunt truth and maximum effort, often says "you decide" to a recommendation, and asked for self-proofreading before anything is delivered. Plays builds on an ASUS VivoBook (Intel Iris Xe, Windows, Vulkan Forward+, the game window 1920x1010): the minimum machine. Creator credit: shahanxd.

## The design document

A Claude Doc: https://claude.ai/code/artifact/edb009e1-ac2b-462a-8860-f031366c2ec2 (doc id `edb009e1-ac2b-462a-8860-f031366c2ec2`, tab file `97c63c3c-32af`, body node `dc81e545-7518`). `docs/gdd.md` matches rev 82 (30 September 2026). Edit it with the docs connector, never by publishing HTML; mirror each change into `docs/gdd.md` (the markdown export escapes brackets and backticks, so apply the same edits to the snapshot rather than pasting the export). If the connector is not available to you, edit `docs/gdd.md` and say in `decisions.md` that the Claude Doc is behind. Where the new docs change the design document (the beat sheet's fixes, the slice order), the new docs win once the founder locks them.

Scripture: sunnah.com is blocked from the cloud container, so Sahih al-Bukhari 1284 and Sunan Ibn Majah 1896 carry only their first verification. Before their cards ship, open https://sunnah.com/bukhari:1284 and https://sunnah.com/ibnmajah:1896 in a browser and match the text, numbers and grade.

## Rules (never broken)

- **Halal.** No instruments, ever, and nothing imitating one. The duff only at the wedding, on the women's side. Quran only as a full stop: play paused, every bus silent, skip at ayah boundaries; audio only from a licensed human reciter, otherwise text. Women's dancing never shown; no romance on screen.
- **No AI assets.** No AI-generated art, texture, audio, voice, Quran or music ships, enters the repository, appears in marketing, or is used as a style target (lock F-01).
- **No combat.** The perpetrator is "they": present, faceless, never a character or target. Never write "al-yahud".
- **Sami's death** (Day 7) is aftermath only, never preventable, never a fail state, never caused by a player choice. Children's deaths may be shown as aftermath.
- **Facts** are checked against `docs/research/13` to `18` before they go into the doc or the game. No invented real people on signs or in lines.
- **Made with, not for.** The Palestinian readers' notes are binding; no public build before they have read it.
- **Every session ends** with `bash tools/check.sh` green and a commit pushed to `main` (no pull requests unless asked). Commit as the founder: `git -c user.name=shahanxd -c user.email=<the founder's email> commit`. No model identifiers in commit messages, code or docs, beyond any attribution trailer the session requires.
- **Before handing a build over:** render through `main.tscn` at 1920x1010 and look at it; make sure bots walk every route; test a fresh clone with `tools/play.bat` in mind; tell the founder the route to the best minute (`docs/playtests/2026-09-29-founder.md`, Lessons).

## Switching agents

- Read this file and the reading order; run `bash tools/setup_linux.sh` then `bash tools/check.sh`; `git log --oneline -20` shows recent work.
- The container reaches GitHub and package registries only (no sunnah.com, quran.com, Freesound, Kenney). Renders need `xvfb-run` and the compatibility renderer (`docs/tech/codebase.md`).
- Update this file at the end of each session: the stage, what waits on the founder, what the next agent does. Record decisions in `docs/decisions.md` and lock status in `lock.md` the day they change.

## Status of the first playable (29 September 2026)

Day 1 sampler, one continuous playable through `main.tscn`: beach (Sami's call, the kite fetches the spool from the kiosk roof), street (the water run, the pit, the two-handed plank), home (switch to Baba, the stairs, the roof sit with Teta at dusk, a card, the strike, the beam, the candle), night street (windows, candle traversal, the oven), notebook page. `tools/check.sh` runs 11 suites (smoke, core, audio, five beat bots, notebook, the 102-check full-day flow, chapter card). The world (skies, sea, grade, skyline, facades, the home interior) is at the bar per `docs/research/23-art-critique-1.md`; the people (`figure.gd`), the sound (synthesised by `tools/audio.py`) and the scene structure are what the lock replaces. The unapplied items of the art critique (ground, lights, specific places) are in `docs/art/direction.md`, The world.

Open small confirmations carried from 29 September (all in `lock.md`): Sami as cousin (C-05), Teta's biography (C-06), the Arabic fonts Amiri and Noto Naskh Arabic under the OFL in `game/assets/fonts/`, Decisions 5, 13 and 14, the Steam fee, Layla's scarf (drawn cream in the prototype, `scarf_color` in `game/scenes/player.tscn`; F-06), the signs "مخبز أبو أحمد" and "كشك الشاطئ" (D-04).
