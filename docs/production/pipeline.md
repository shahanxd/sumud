# Production pipeline

How SUMUD goes from the first playable (v0.2 in the founder's words) to the game the founder has in mind. Read with `docs/production/lock.md` (what must be decided) and `docs/HANDOFF.md` (where everything is).

## The stages

| Stage | What it proves | Output | Gate | Dates |
| --- | --- | --- | --- | --- |
| 1. Concept | The idea, the rules, the research | Design document, research 01 to 23 | Founder | Done |
| 2. First playable | The systems work end to end | Day 1 sampler, bots, `tools/check.sh` | Founder plays it | Done (29 September 2026) |
| 3. Pre-production lock | Every decision that cannot change later is made | `lock.md` all P0 rows LOCKED | Founder signs | Done (1 October 2026, in chat; F-05, F-07, E-06, G-02 remain open by the founder's choice) |
| 4. Day 1 | One day complete, at the bar | Day 1 playable start to finish, every beat of the beat sheet, generated cast and props, ElevenLabs sound | The world-class tests below, iterated until they pass | First pass complete 1 October 2026 (eight beats, 222-check flow); the bar is not yet met (see the polish list in `HANDOFF.md`) |
| 5. **Day 3** (now) | The siege and the strike work (the hardest tone) | Day 3 complete | Tests; founder's own scholar review | By 7 October 2026; script and scaffold in, beats in progress on 1 October |
| 6. Production | The rest | Days 2, 4 to 10, in order of risk: 7, 10, 8, 5, 2, 4, 6, 9 | Each day passes its definition of done | October to November 2026 |
| 7. Alpha | Whole game playable | All ten days | Full playthrough by 5 strangers | Mid November 2026 |
| 8. Beta | Content complete | Everything final; localisation in; accessibility list done | Readers, the founder's scholar review, testers | Late November 2026 |
| 9. Launch | | Steam (Windows, Linux) | | December 2026 (founder, 1 October: "full game by december"); Steam's Coming Soon page needs at least two weeks before release, so K-04 by mid November |

**The founder set these dates on 1 October 2026** ("we speed up, day 1 today, day 3 this week, full game by december"), replacing the 30 September plan (lock by 13 October, slice by December, launch late 2027). The quality bar below did not move. Where they collide, the order is: every day exists and plays end to end first, then the bar is reached by iterating on finished days, hardest days first. The readers (E-06, deferred) are the one gate that cannot be iterated past: no public build before they have read it, so they must be recruited by early November. Any agent that sees the bar slipping says so in `HANDOFF.md` rather than quietly lowering it.

## The world-class bar, as tests

"World class" is judged, not described. Every slice and every day must pass:

1. **The stranger test.** Three people who have not heard of the game play it on the founder's laptop with no help. Nobody gets lost for more than 30 seconds (the readability rules); at least two say unprompted that they want to keep playing.
2. **The store-page test.** Any frame grabbed at random could be a store screenshot.
3. **The feel test.** The founder plays with a controller and a keyboard and does not call any movement "weird". The feel targets in `docs/design/feel-and-readability.md` are met.
4. **The people test.** Every character on screen moves like a person (performed, not puppeted); every scene has someone react to the player.
5. **The sound test.** Nothing sounds synthetic except the drone and the rumble; the mix is balanced on laptop speakers and headphones.
6. **The readers' test.** The two Palestinian readers sign off; their notes are binding.
7. **The halal test.** The scholar has signed off the audio rules, the voices, and the wedding; `tools/check.sh` passes its audio audit.
8. **The tech test.** 60 frames a second at 1080p on the founder's laptop; no crash in a full playthrough; `tools/check.sh` passes.

## Roles

| Role | Who | Does |
| --- | --- | --- |
| Founder, director | shahanxd | Decides; plays every build; films and records; recruits; pays; signs the lock and each gate |
| Agent (engineering, design, first drafts) | An AI coding agent in this repository | Code, tools, level building, bots, docs, the English guidance script, the Claude Doc sync; generates art, textures, frames and sound with image and audio models within F-09 and puts them in the game; the founder approves every asset in-engine |
| Artist | None (founder, 1 October: "no artist, i can judge, but you have to handle all") | The agent generates and the founder judges; the brief stays on file |
| Performers | Family and friends, with consent | Rotoscope performances (if method B), barks |
| The friend | The founder's friend, a song performer (named later) | The songs only |
| Palestinian writer | To recruit | The Arabic of every line |
| Readers | Two Palestinians, paid, credited | Binding review of story, names, culture, the Arabic |
| Scholar | The founder, for now (E-05) | Halal rules, voices, the wedding, the scripture cards |
| Reciter | A licensed human qari | Quran audio, or text only |
| Testers | Strangers, then Steam playtest | The stranger test |

## The lock: week by week (superseded 1 October: the founder answered everything in one sitting; kept for the record)

| Week | Tasks | Owner | Output |
| --- | --- | --- | --- |
| 1 (30 Sep to 6 Oct) | Read `lock.md` and answer every PROPOSED row; post the artist, reader and performer calls (`docs/outreach.md`); record the friend's first session; film Layla's walk, run, jump and carry on a phone (a girl of about twelve with a parent, or any small performer in costume) | Founder | Answers; footage; first recordings |
| 1 | Write `tools/roto.py` (classical keying) and the `SpriteFrames` import tool; improve the code rig as method A; build the animation test scene | Agent | The test scene, rendered |
| 1 to 2 | Coyote time, jump buffer, variable jump, ledge grab, camera leading and the debug tuning overlay in the first playable | Agent | A build the founder tunes |
| 2 (7 to 13 Oct) | The animation test: the founder watches A, B (and C) on the laptop and picks | Founder | F-03 locked |
| 2 | Style frames in-engine (or the artist's, if one has joined); the founder picks; three strangers look | Agent or artist, founder | F-05, F-06, F-07 |
| 2 | Scholar and readers contacted with the Day 1 script and the characters | Founder | Dates for their reviews |
| End of 2 | Founder signs the lock | Founder | `decisions.md` row |

If a P0 row cannot be locked by 13 October (usually the readers or the scholar), the slice starts on everything else and that row's work comes last in the slice.

## The vertical slice (Day 1): what gets built

1. The day as one continuous walk: home, roof, street, corniche, beach (`docs/story/world.md`), driven by a data file.
2. The characters by the chosen method: Layla's full list, then Sami, Teta, the family, the neighbours, the crowd.
3. The scene list in `docs/story/day1-script.md`, each with a want, an obstacle, a turn, a payoff and something optional.
4. The recorded sound course for Day 1 (`docs/audio/direction.md`).
5. The world fixes (ground, lights, specific places) from `docs/art/direction.md`.
6. Transitions by the adhan; the chapter card; the notebook.
7. Bots for every required route; `tools/check.sh` green.
8. The Arabic from the writer, reviewed by the readers.

## Definition of done, per scene

- Plays start to finish with no help (the stranger test on that scene).
- Every required route walked by a bot with real physics; no soft locks.
- Final or approved-placeholder art and sound with `docs/rights.md` rows.
- Every line keyed in `game/data/lines.csv` in English and Arabic, reviewed.
- Rendered at 1920x1010 from `main.tscn` and looked at by the agent before handing to the founder.
- The founder has played it in a Windows build.

## How assets flow

1. The need is written (the animation list, the takes list, the prop list).
2. Generated (image or audio model) or made by a person (filmed, recorded, drawn) with consent and rights.
3. Placed in `game/assets/...` by the agent with a `rights.md` row naming the source, model and prompt (lock F-09).
4. Reviewed in-engine, in context, never in isolation (the pose sheet, the scene render).
5. The founder approves; the readers review anything cultural.

## Cadence and feedback

- The agent pushes a playable build to `main` whenever a scene changes, with `tools/check.sh` green and a note of what to try.
- The founder plays with `tools/play.bat` and replies with screenshots and plain words; the agent writes each session into `docs/playtests/` and a triage table.
- Every decision goes into `docs/decisions.md` the day it is made.
- Weekly: a short note in `docs/HANDOFF.md` of where things stand.

## Budget lines (amounts are the founder's)

Readers (paid); the Palestinian writer; the artist (test piece, then batches); the scholar's time if paid; the reciter's licence; performers' thanks; a recorder or a good phone microphone; Steamworks fee; translation to Urdu and Hindi; a charity share (Decision 5). LaunchGood if money is needed (the design document).

## Risks

| Risk | Effect | Answer |
| --- | --- | --- |
| No readers found | No public build | Post the call in week 1; slow down rather than ship without them |
| No artist found | People look like a programmer drew them | Method B (rotoscope) needs no artist to reach "people move like people"; the founder or a friend cleans frames |
| Scholar disagrees with a voice or the wedding | Rework of audio or Day 10 | Ask before recording, not after |
| The founder's time | Everything slows | The agent carries everything that is not the founder's; the gates move, the bar does not |
| Rotoscope footage of minors | Consent, privacy | Parent present and consenting; footage deleted after keying; no faces used |
| Scope | Ten days at slice quality is a lot | The short days stay short; cut optional look-ats before cutting quality |
| Agent change | Context lost | The repository is the source of truth; `docs/HANDOFF.md` is the entry point |

## Backlog (numbered, in order)

1. Founder answers `lock.md`.
2. Feel pass in the first playable (coyote, buffer, variable jump, ledge grab, camera, tuning overlay).
3. `tools/roto.py` and the SpriteFrames import tool.
4. The animation test scene and render.
5. Style frames in-engine.
6. Day structure in code: one day scene of connected spaces from a data file (lock I-04).
7. Day 1 route: home, roof, street, corniche, beach as one walk.
8. Day 1 scenes 0 to 9 from the script with keyed lines.
9. Adhan transitions; sound leads the picture.
10. Recorded audio in; synthesised foley out.
11. World fixes (ground shader, lights, specific places).
12. Bots per scene; stranger test; gate 4.
13. Scripture cards: a Quran face for every card (the hadith font is a body font today), with a `test_core` check; a check that `lines.csv` never contains the forbidden colloquial word (lock E-07).
