# Pre-production lock register

Everything that cannot change once production starts, in one list. Production starts when every **P0** row is LOCKED. Anything not on this list may change during production (the list at the end).

**Statuses.** LOCKED: decided by the founder, recorded in `docs/decisions.md`. PROPOSED: a recommendation waiting for the founder's yes or no. OPEN: a question that needs someone (the founder, the readers, the scholar, a test). **Priority.** P0 blocks the vertical slice; P1 blocks production of Days 2 to 10; P2 blocks launch.

**What LOCKED means here.** Rows marked LOCKED are the founder's answers of 29 September (listed in `docs/HANDOFF.md` history and the design document's Decisions section, "your answers of 29 September are locked") or rows recorded in `docs/decisions.md`. Everything the design document says that the founder has not answered directly is PROPOSED until signed.

**1 October 2026, evening: the founder answered every row in chat** ("lock all", "p1 and p2 lock", with the changes written into the rows). Every P0 row is LOCKED except F-05 (eyes, to be picked on a style frame), F-07 (style frames, the founder picks), E-06 (readers, deferred) and G-02 (the friend, named later). Production has started.

**How the founder locks a row.** Say "lock" (or change it) in chat or in a doc comment; the agent writes the row to `docs/decisions.md` with the date and changes its status here. "Go with your picks" locks every PROPOSED row as written.

## A. Vision and scope

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| A-01 | What the game is | A 2D side-scrolling narrative adventure about one family on one street in Gaza City over ten days; no combat | LOCKED | P0 | Founder | gdd Vision |
| A-02 | Title | SUMUD for now; check Steam and press for collisions (including the 2025 Global Sumud Flotilla) before the store page | LOCKED (working) | P2 | Founder | decisions |
| A-03 | Length | Ten days: tentpoles 1, 3, 7, 10 at 15 to 20 minutes, six short days at 5 to 10; about two hours | LOCKED | P0 | Founder | decisions |
| A-04 | Quality bar | "World class": held to the tests in `docs/production/pipeline.md` (the store-page test, the stranger test, the feel test, the readers' sign-off) | LOCKED (1 Oct, founder) | P0 | Founder | pipeline |
| A-05 | References | Limbo and Inside (look), Life is Strange (quiet moments, lived-in rooms, choices that echo), Silksong (hand-made motion and feel), The Kite Runner (a child's city at kite height; not its betrayal plot), Thimbleweed Park (switching, humour), This War of Mine (daily rhythm) | LOCKED (1 Oct, founder) | P0 | Founder | art/direction |
| A-06 | Vertical slice | Day 1 at shipping quality, then Day 3, then the full game (founder: "day 1 then day 3 then full game"); Day 1 is also the Next Fest demo | LOCKED (1 Oct, founder) | P0 | Founder | pipeline |

## B. Story

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| B-01 | Premise and ending | One family, ten days, a kite festival to a courtyard wedding; the ending flies Sami's kite after kites are declared drones; not a rescue | LOCKED | P0 | Founder | gdd Story |
| B-02 | The through-line | Teta's question on Day 1, "who is braver, the kite or the hand that holds the string?", asked while Layla holds a kite still; answered on Day 10 by holding, not by stating it ("Teta. I'm holding.") | LOCKED (1 Oct, founder) | P0 | Founder, writer | story/beat-sheet |
| B-03 | The promise | Day 1 knot: whoever won the contest flies at the wedding, and Sami builds the kite either way; the knot tied into Sami's kite on Day 10 | LOCKED (1 Oct, founder) | P0 | Founder | beat-sheet |
| B-04 | The count | Day 1's count to thirty repeated on Day 10 in human voices | LOCKED (1 Oct, founder) | P1 | Founder | beat-sheet |
| B-05 | The one death | Sami, Day 7, off-screen, aftermath only, never preventable, never a fail state, never caused by a choice | LOCKED | P0 | Founder | gdd |
| B-06 | Whose wedding | Nour, Sami's older sister; groom Fadi, Abu Fadi's son; Abu Sami gives the blessing (Decision 14) | LOCKED (1 Oct, founder) | P1 | Founder, readers | characters |
| B-07 | Family relations | Teta is Baba's mother; Sami's father is Baba's younger brother next door | LOCKED (1 Oct, founder) | P0 | Founder, readers | characters |
| B-08 | Karim's choice | A scholarship abroad or staying to dig out the bakery; neither a rescue | LOCKED | P1 | Founder | gdd |
| B-09 | Evacuation geography | School down the coast; a checkpoint on the coastal road; ceasefire on Day 8; the young men walk back to dig | LOCKED (1 Oct, founder) | P1 | Founder, readers | story/world |
| B-10 | Fixes to the design document | The nine fixes at the top of the beat sheet (Layla's small kite, Abu Khalil's adhan, the imam, choices not tied to recitation, and the rest) | LOCKED (1 Oct, founder) | P1 | Founder | beat-sheet |
| B-11 | Day 1 script | `docs/story/day1-script.md` as the basis for the Arabic | LOCKED (1 Oct, founder) | P0 | Founder, writer, readers | day1-script |
| B-12 | Dhul Hijjah frame | No (Decision 13) | LOCKED (1 Oct, founder) | P1 | Founder | gdd Decisions |
| B-13 | Readers' sign-off on Days 7 and 8 | Before those days are built | OPEN | P1 | Readers | outreach |

## C. Cast

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| C-01 | The family | Layla 12, Teta Nawal 71, Baba Yousef 44, Mama Rania 40, Karim 17 | LOCKED | P0 | Founder | gdd Cast |
| C-02 | Family name | Awad placeholder until the readers choose | OPEN | P1 | Readers | gdd |
| C-03 | Neighbours | Eight households (`docs/story/characters.md`) | LOCKED (1 Oct, founder) | P1 | Founder, readers | characters |
| C-04 | Names | All working names confirmed by the readers | OPEN | P1 | Readers | characters |
| C-05 | Sami as cousin next door | Relation only | LOCKED (1 Oct, founder) | P0 | Founder, readers | decisions |
| C-06 | Teta's biography | Born after the Nakba; her mother's key; the village chosen by the readers or unnamed | LOCKED (1 Oct, founder) | P1 | Founder, readers | characters |

## D. World

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| D-01 | Five spaces, three states | Beach, street, home and roof, school courtyard, harbour; before, siege, after | LOCKED |
| D-05 | The coastal road | A connecting walk on Day 7, not a sixth space | LOCKED (1 Oct, founder) | P1 | Founder | story/world |
| D-02 | Camera and screen direction | Screen right is where the day goes; background turns only at boundaries | LOCKED (1 Oct, founder) | P0 | Agent | story/world |
| D-03 | A day is one continuous walk | Fades only at the day's edges; time moves on the adhan | LOCKED (1 Oct, founder) | P0 | Agent | design/feel |
| D-04 | Signs in the world | "مخبز أبو أحمد", "كشك الشاطئ" | OPEN | P2 | Readers | decisions |

## E. Faith and culture

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| E-01 | Halal rules | No instruments; duff only at the wedding on the women's side; Quran as a full stop; no AI Quran and no AI music | LOCKED | P0 | Founder | gdd |
| E-02 | School lens | Hanafi (Decision 3) | LOCKED (1 Oct, founder) | P1 | Founder | gdd Decisions |
| E-03 | Scripture moments | The design document's 22 items; two hadith re-checked in a browser before their cards ship | LOCKED (1 Oct, founder) | P1 | Founder | gdd |
| E-04 | Who recites | A local hafiz for tests, a Palestinian qari for launch, under a written licence; text only until then (Decision 8) | LOCKED (1 Oct, founder) | P2 | Founder | gdd |
| E-05 | Named scholar | The founder does the scholar review themselves (audio rules, the singing voices, the wedding storyboard, the scripture cards) before each day ships; a named scholar may be credited later | LOCKED (1 Oct, founder) | P0 | Founder | gdd |
| E-06 | Readers | Two Palestinian readers, paid, credited, binding; recruited later at the founder's call. The rule stands: no public build before they have read it, so they are needed before the December launch | OPEN (deferred by the founder, 1 Oct: "not now, later") | P0 for any public build | Founder | outreach |
| E-07 | "They" | Faceless but present; the colloquial word for "the Jews" never written (the design document, Tone and ethics); Israel named once in the title card and in the Sources | LOCKED | P0 | Founder | gdd |

## F. Art

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| F-01 | AI generation | Allowed for art, textures, props, animation frames, sound effects, ambience and reference, under F-09 (founder, 1 October 2026) | LOCKED (1 Oct) | P0 | Founder | decisions |
| F-09 | Limits on AI generation | Never for Quran (text, or a licensed human reciter); never music or anything that imitates an instrument (E-01); never prompted on, trained on or traced from footage, photographs or likenesses of real Gazans or real victims; every generated asset is reviewed in-engine by the founder, culturally by the readers, and gets a `docs/rights.md` row naming the model; disclosed on Steam's AI content survey and on the store page as "some art and sound were made with generative AI tools and reviewed by people"; voices for characters only after the scholar's view on synthetic voices (G-02 to G-04) | LOCKED (1 Oct, founder) | P0 | Founder, readers, scholar | art/direction |
| F-02 | Art base | Silhouettes with colour carried by light | LOCKED | P0 | Founder | decisions |
| F-03 | Character method | Generated silhouette frames (image model, Canva route) for every character; the founder played the 1 October build and said "keep". The bone rig stays only as the fallback for anyone without frames | LOCKED (1 Oct, founder) | P0 | Founder | art/direction |
| F-04 | An artist | No artist. The founder judges every asset in-engine; the agent produces all art through generation (Canva) and code. The artist brief stays on file in case that changes | LOCKED (1 Oct, founder) | P0 | Founder | art/artist-brief |
| F-05 | Faces and eyes | Founder: "maybe, take inspiration from Limbo". Test Limbo-style eyes (two small pale lights, no colour, only on the player and only in dark scenes) against no eye-lights on the next style frame; the founder picks on the frame | PROPOSED (revised 1 Oct) | P0 | Founder (style frames) | art/direction |
| F-06 | Layla's headscarf | Dusty blue: the one colour accent on Layla (`scarf_color` in `game/scenes/player.tscn` for the bone rig; the generated frames carry it as a tint on the scarf region, to be regenerated with the colour in the prompt). Custom by the readers when they exist | LOCKED (1 Oct, founder) | P0 | Founder, readers | art/direction |
| F-07 | Style frames | Beach at the count, roof at maghrib, the dark street; generated from the art direction; thumbnails until the full file can be exported | OPEN (first drafts 1 Oct; the founder picks) | P0 | Agent, founder | art/style-frames |
| F-08 | World | Code-built layout and light kept; surfaces, hero props and dressing from generated textures and silhouettes | LOCKED (1 Oct, founder) | P1 | Agent | art/direction |

## G. Audio

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| G-01 | Sound course | ElevenLabs (the founder's account) for foley, ambience and the strike; the drone and rumble synthesised; the friend, the adhan and the count recorded. Quran: never generated; the game leaves an audio slot per scripture moment that the founder fills by hand with a licensed human recording (text only until then) | LOCKED (1 Oct, founder) | P0 | Founder | audio/direction |
| G-02 | The friend | The founder's friend, a song performer, sings only the songs (the wedding songs, the voice score); never Layla's lines (G-04). Name, voice and where it is allowed come from the founder and their own scholar review | OPEN (founder names them later) | P0 | Founder | audio/direction |
| G-03 | Dialogue | Subtitled, Arabic over English; short recorded barks in Arabic; full voice acting after launch | LOCKED (1 Oct, founder) | P0 | Founder | audio/direction |
| G-04 | Who sings Layla's lines | A young girl, with consent, sings Layla's lines (founder, 1 Oct). The friend sings only the songs (G-02) | LOCKED (1 Oct, founder) | P1 | Founder, scholar | audio/direction |
| G-05 | The strike | Real recorded explosion, once per strike day | LOCKED | P1 | Founder | decisions |

## H. Gameplay

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| H-01 | Verbs and inputs | Eight inputs; no new verbs after the lock | LOCKED (1 Oct, founder) | P0 | Founder | design/feel |
| H-02 | Carry rules | As built, with per-character classes (a full jerrycan is two-handed for children) | LOCKED (1 Oct, founder) | P0 | Agent | design/feel |
| H-03 | Feel targets | Coyote time, jump buffer, variable jump, landings, ledge grab, camera leading | LOCKED (1 Oct, founder) | P0 | Agent, founder tunes | design/feel |
| H-04 | Readability rules | The world points, not the HUD; no objective text after the first minute | LOCKED (1 Oct, founder) | P0 | Agent | design/feel |
| H-05 | Choices | Marks not branches; the callbacks table; one or two answer choices a day, never timed | LOCKED (1 Oct, founder) | P1 | Founder | beat-sheet |
| H-06 | Timed moments | At most one a day (two on Day 3), none on Days 1, 7, 10; "own pace" for all | LOCKED (1 Oct, founder) | P1 | Founder | gdd |

## I. Tech

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| I-01 | Engine | Godot 4.7.2, GDScript; no engine upgrade during production without a test branch | LOCKED | P0 | Founder | decisions |
| I-02 | Renderer and minimum machine | Forward+; the founder's laptop (Intel Iris Xe) at 1080p60 is the minimum | LOCKED (1 Oct, founder) | P0 | Agent | art/direction |
| I-03 | Character tech | `AnimatedSprite2D` frames with per-frame hand points (follows F-03, generated frames) | LOCKED (1 Oct, founder) | P0 | Agent | art/direction |
| I-04 | Day structure in code | One day scene made of connected spaces, driven by a data file per day | LOCKED (1 Oct, founder) | P0 | Agent | tech/codebase |
| I-05 | Saves | JSON per slot with the notebook; Steam cloud later | LOCKED (1 Oct, founder) | P1 | Founder | gdd |
| I-06 | Platforms | Windows and Linux (Steam Deck) at launch; macOS when a Mac tester exists; mobile later, Android first | LOCKED (1 Oct, founder) | P2 | Founder | gdd |

## J. Localisation and accessibility

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| J-01 | Languages | English and Arabic at launch; Urdu and Hindi within a month | LOCKED | P1 | Founder | decisions |
| J-02 | Arabic writing | A Palestinian writer writes the Arabic from the English guidance; the readers review | LOCKED (1 Oct, founder) | P0 | Founder | day1-script |
| J-03 | Arabic and Latin fonts | Amiri 1.001 and Noto Naskh Arabic 2.019 (OFL) in the prototype (research 13 says Amiri 1.000; later tags exist); scripture cards use a Quran face (KFGQPC or Amiri Quran), never the body fonts; final pairing chosen on the style frames | LOCKED (1 Oct, founder) | P1 | Founder | decisions |
| J-04 | Accessibility | The design document's list as launch requirements | LOCKED (1 Oct, founder) | P2 | Founder | gdd |

## K. Business and production

| ID | Decision | Answer | Status | P | Owner | Where |
| --- | --- | --- | --- | --- | --- | --- |
| K-01 | Schedule | Founder, 1 October: "we speed up": Day 1 complete today (1 Oct), Day 3 this week (by 7 Oct), the full game by December 2026. Replaces the 30 September dates (lock by 13 Oct, slice by December, launch late 2027). The quality bar A-04 is unchanged, so the bar is reached by iterating on finished days, not by holding days back; the readers (E-06) and the Steam page (K-04) are the schedule risks | LOCKED (1 Oct, founder) | P0 | Founder | pipeline |
| K-02 | Budget | As proposed: readers paid; ElevenLabs on the founder's account; the reciter's terms set by the founder; LaunchGood if money is needed. No ceiling given | LOCKED (1 Oct, founder) | P0 | Founder | pipeline |
| K-03 | Charity | The War Child wording, a named charity with consent (Decision 5) | LOCKED (1 Oct, founder) | P2 | Founder | gdd |
| K-04 | Steamworks | Pay the fee and onboard; Coming Soon page from the slice's frames; AI content survey filled in (F-09) | OPEN | P1 | Founder | gdd |
| K-05 | Rating | PEGI 16 target, ESRB T; content warning written | LOCKED (1 Oct, founder) | P2 | Founder | gdd |
| K-06 | Source of truth | The repository (`docs/`) is canonical for any agent; the Claude Doc is the founder's reading copy, kept in sync | LOCKED (1 Oct, founder) | P0 | Founder | HANDOFF |

## What may still change during production

Level layouts and puzzle details; the wording of every line (through the writer and readers); palette values; camera framing; sound levels and the mix; animation timing; which optional look-ats exist; the number of kites in the sky; UI layout; the order of work.
