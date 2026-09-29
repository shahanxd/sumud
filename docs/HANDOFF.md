# Handoff: where SUMUD stands on 29 September 2026 (evening)

Read this first when picking the project up in a new session.

## The founder

shahanxd (GitHub). Indian, a practising Muslim; everything in the game must be halal. No art or audio budget; a friend may sing; will pay the Steam fee. Writes informally, wants the blunt truth and maximum effort, delegates judgement ("you decide") when given a recommendation, and asked for self-proofreading before anything is delivered. Creator credit: shahanxd. On 29 September the founder said: the final design document comes first, the game second.

## Where things live

- **Design document (living, commentable):** https://claude.ai/code/artifact/edb009e1-ac2b-462a-8860-f031366c2ec2 — a Claude Doc, now titled v0.2. Doc id `edb009e1-ac2b-462a-8860-f031366c2ec2`, tab file id `97c63c3c-32af`, body node id `dc81e545-7518`. Edit it with the docs tools, never by publishing HTML. `docs/gdd.md` is a faithful markdown snapshot (doc rev 48).
- **Research, verification and critiques:** `docs/research/`, numbered. 00 is the original v0.1 doc plus the founder's full feedback. 01 to 08 research lenses, 09 to 12 critiques, 13 to 18 independent verification passes, 19 and 20 the edit lists that folded critique 11 and the corrections into v0.2. Nothing in the doc may contradict 13 to 18.
- **Decisions log:** `docs/decisions.md`. **Rights ledger:** `docs/rights.md`. **Outreach drafts** (readers, testers): `docs/outreach.md`.

## The founder's answers of 29 September (locked)

Limbo as the art base, with more colour carried by light; Godot; the cast as designed; ten days; English and Arabic at launch; player kites in the ending; title SUMUD for now; one death and Karim's choice; no combat; the perpetrator is "they", faceless but present (soldiers, gunboats, drones may be shown indirectly), and the game must feel defiant, not cowardly; children's deaths may be shown; absolutely halal, so no instruments, Quran or hadith quietly at related moments, halal nasheed instead of music; real explosion sound is fine; mobile one day, Steam first; surprise moments and cinematics only where they work; The Kite Runner as a liked reference, not a template; prototype this week, final game in two to three months; charity "yes, 100%" (meaning to be clarified); the repo is on GitHub and the work continues in the cloud.

## The design document is finished (v0.2, rev 48)

Done on 29 September, in the cloud session:

1. **Scripture moments** filled: 22 items (14 verses, 8 hadith) in day order with the clause shown, the verified English, the reference link and the grade, five rules that the Audio section did not already state, and the alternates held in reserve. Every Arabic and English string was extracted from `research/03-scripture.md` by script and checked as a verbatim substring; nothing was retyped. sunnah.com is blocked from the cloud container, so **Sahih al-Bukhari 1284 and Sunan Ibn Majah 1896 still carry only their first verification**: open https://sunnah.com/bukhari:1284 and https://sunnah.com/ibnmajah:1896 in a browser and match the two shown lines, the reference numbers and the grade line before their cards ship. The doc says so in the section.
2. **Critique 11 (culture and faith)** folded in: no player choice decides who dies; the wall of names is retired for the martyr's poster; Karim's choice is a scholarship or staying, not a boat; Teta was born after the Nakba and keeps her mother's key; Sami is Layla's cousin next door (a relation, not a cast change, for the readers to confirm); gossip and cards are gone; the football on the Bakr beach is a stated choice with the readers' veto; funeral customs partly applied and the rest sent to the readers; the "Gazan, not South Asian" checklist; Bismillah on the notebook pages; Teta's bedtime recitation; character switching as the only way to see the segregated wedding whole; routes to paid readers; consent rules for real children's names; Decisions 13 (Dhul Hijjah, recommended no) and 14 (whose wedding, recommended Sami's sister) added. Disagreements are recorded in the doc's new section "What the critiques changed".
3. **Critique 12 (market)** folded in: "Why this will sell, honestly" with the comparables and a 200 to 1,500 review base case; the charity paragraph with the War Child wording, the tax facts for an Indian payee, the UK and US cause-marketing rules, the two candidate charities, a quarterly post and the launch-week pledge; kite moderation rules; authorship ("made with, not for"); a review-bombing line; "Reaching people with no following" (store page now, wishlist benchmarks, itch.io bundles, LaunchGood, Steam Playtest, the press list, the teacher's guide); Apple and Google rules under Platforms; the Coming Soon page moved to Week 4 and the Steam fee to this week. Disagreed with: keeping child deaths off screen (the founder decided otherwise), and the ney (an instrument).
4. **Verification corrections** applied: Liyla's dates (18, 20 and 22 May 2016), the BBC's 2025 guidance on "yahud", Maher Zain's album, Layla's headscarf age wording, the December 2025 shelling (the shelter beside the tent), the Valiant Hearts sale price. The UN Commission of Inquiry figures were not in the doc, so nothing to correct; Darul Ifta Birmingham and the Standing Committee are not cited in the doc.
5. **Proofread**: contradictions fixed (the strike clock, the eight inputs, "the first four systems" overclaim, the wedding photo, Israel named "once"), the Tech and Production sections brought up to date, the Decisions items on fonts, Steamworks and charity rewritten.

A final two-agent check (facts and rules on every changed sentence; a fresh-eyes proofread) was started at the end of the session; its findings, if any, go into the doc before the next handoff.

## Pending founder confirmations

- Sami as Layla's cousin next door (relation only) and Teta's biography (her mother's key), both flagged for the readers.
- The two Arabic fonts (Amiri 1.001, Noto Naskh Arabic 2.019, OFL) fetched into `game/assets/fonts/`; say so to remove them.
- Decisions 5 (charity wording and organisation), 13 and 14, plus the earlier 1 to 12.
- The Steam Direct fee and Steamworks onboarding this week.

## The codebase today

- `game/` Godot 4.7.2 project, Forward+ renderer, 2D MSAA. 2D HDR is off until the look-lock week sets up glow.
- **Spine (committed):** `scripts/core/day_runner.gd` (autoload `Day`: chains Beat scenes with fades and the chapter card, merges each beat's result into a shared context, `--bot` mode), `scripts/core/beat.gd` (`Beat` base class), `scripts/core/notebook.gd` (autoload `Notebook`: Layla's entries to JSON, acts that become kites), `scripts/core/look.gd` and `data/palette.json` (the per-day, per-phase colour budget; sky, sea, skyline haze and ambient light), `scripts/core/fx.gd` (fade, strike flash, white-out, letterbox), `scripts/core/say.gd` and `data/lines.csv` (dialogue in Arabic over English by key), `scripts/npc.gd` (silhouette neighbour with a talk radius).
- **Beach beat (committed):** `scenes/beach.tscn` is the first Beat: Sami asks, Layla flies the kite onto the stall roof, the kite snags the string (kite.gd hooks light carryables with its body or tail), reels it down, she carries it to Sami, the notebook remembers it. Bot: `tests/bot_beach_beat.gd` (10 checks) beside the older 16-check `tests/bot_driver.gd`.
- **Street beat (on disk, not committed, not yet green):** `scenes/street.tscn`, `scripts/beats/street_beat.gd`, `scripts/plank.gd` and `scenes/plank.tscn` (a two-handed plank that snaps into a bridge flush with the road), `tests/bot_street.*`, plus the street lines in `data/lines.csv`, `carryable.gd` signals and a `check.sh` entry. The last bot run failed only because the bakery facade had a collision shape; that was removed and the bot has not been rerun since. Rerun `bash tools/check.sh`, fix, commit.
- Fonts: `game/assets/fonts/amiri/` and `game/assets/fonts/noto_naskh_arabic/` with OFL.txt; listed in `docs/rights.md`.
- `tools/check.sh` runs: the real main scene with `--smoke`, `tests/test_core.tscn` (14 checks on the spine), the 16-check beach bot, the beach beat bot, the street bot, the chapter card test. `tools/setup_linux.sh` fetches the Linux Godot binary and the Python venv.
- Godot imports `data/lines.csv` as translation resources (`lines.*.translation`); either commit those or set the CSV's import to keep the file.

## Next: Week 1 prototype (29 September to 5 October)

One continuous 8 to 12 minute playable, not a feature list. In order:

1. Beach: done (the kite fetches one item from a roof).
2. Street: one route puzzle where the jerrycan removes the jump (on disk, finish and commit).
3. Home hub: Layla and Baba switch, one beam-and-gap puzzle (stretch).
4. Roof at dusk: a sit spot, one Teta line in Arabic and English, a code-built vocal pad placeholder.
5. First strike: birds leave, one real bang, white-out, one generous take-cover moment with an own-pace fallback. Kenney and Freesound are not reachable from the cloud container (only GitHub is), so synthesise the bang for the prototype and swap in a recorded CC0 sample on the founder's machine.
6. Street at night: lit and dark windows from a data table, candle traversal where darkness is impassable.
7. A notebook entry written to JSON and the tatreez end card.
8. One hero shot of the beach at dusk with grain, dither and a proper sky.
9. The bot plays it end to end (`Day.start(1)` in `--bot` mode with each beat's bot); a Windows export for the founder (export templates are 1.3 GB from GitHub; or the founder exports on Windows).

Gate: one stranger plays ten minutes with no instructions, understands carrying, names a moment that landed, no crash.

## Rules to keep

- Every session ends with a build that runs and a commit. Run `bash tools/check.sh` before committing.
- No instruments, ever. Voices, duff at the wedding only, world sound. No Quran under gameplay, music or effects; skip only at ayah boundaries. No AI-generated audio, voices, Quran or art ships.
- The perpetrator is never a character or a target. No combat mechanics.
- Sami's death is aftermath only, never preventable, never a fail state, never caused by a player choice.
- Check facts against the verification files before writing them into the doc or the game.
- The cloud container's network reaches GitHub and the package registries only; sunnah.com, quran.com, Kenney and Freesound are blocked. Verify scripture in a browser.
