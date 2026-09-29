# SUMUD — Game Design Document v0.1 (as written 2026-09-29, before founder feedback)

## Vision

SUMUD (Arabic for steadfastness) is a 2D narrative adventure about one family in Gaza living through a siege, told through the eyes of a 12-year-old girl who flies kites. It is a game about staying: keeping the lights on, feeding the neighbours, marrying off a cousin, teaching a class in a stairwell, and flying a kite over a sea you are not allowed to sail. There is no combat. The enemy is never a character. The player's job is to keep a neighbourhood alive and human, one day at a time.

**The pitch in one line:** Inside meets This War of Mine, with the heart of Life is Strange, set in Gaza.

**The feeling we are chasing.** The quiet rooftop moment in Life is Strange where the music swells and you just sit. The warmth of Thimbleweed Park, where a place feels lived-in and every character has a joke. The dread and beauty of Limbo and Inside, where the world is a silhouette and light is precious. We want players to close the game and feel two things at once: grief, and an overwhelming sense that these people are not victims but the strongest people they have ever met.

**Why this will sell.** The market rewards short, dense, unforgettable narrative games with a distinct look (Inside, Gris, Valiant Hearts, Papers Please, Florence, Unpacking). None of them have been about Gaza. The audience for this story is global and already mobilised. A game that treats the subject with craft rather than slogans will be covered by every outlet, streamed by every narrative-game creator, and shared as an act of solidarity. The design goal is that it gets covered because it is a great game, and stays in people's libraries because of what it says.

| Reference | What we borrow | What we leave |
| --- | --- | --- |
| Inside / Limbo | Silhouette art, light as a resource, physics puzzles, wordless dread | Horror, death loops, gore |
| This War of Mine | Daily rhythm, scarcity, choices about who to help | Top-down management, scavenging as the whole game |
| Life is Strange | Quiet moments, licensed-feeling music, choice callbacks | Time rewind, teen melodrama |
| Thimbleweed Park | Character switching, humour, a town full of people who know you | Pixel art, verb-menu interface |
| Valiant Hearts | Civilian view of war, historical vignettes, no villain character | Cartoon style, collectible-heavy pacing |
| Gris | Colour as emotional state, wordless story beats | Abstract setting |

## Design pillars

Every feature, scene and line of dialogue must serve at least one pillar and contradict none. If it fails this test it is cut.

1. **Steadfastness is a verb.** The player never fights. They carry, repair, share, teach, cook, wait, and fly. Every mechanic is an act of care or persistence. Progress is measured in what is kept alive, not what is destroyed.
2. **The enemy has no face.** Bombardment, the blockade and power cuts are weather. They arrive from off-screen and shape the world, but no soldier, faction or politician is ever a character. This keeps the camera on the people and makes the game impossible to dismiss as a pamphlet.
3. **Joy is not optional.** Every day contains laughter, food, music, football, gossip or a wedding. If a playtester says the game is only sad, the day is redesigned. Gaza's humour is the loudest thing in the room.
4. **One family, one neighbourhood, one sea.** The whole game happens in a few streets, a rooftop, a school, a clinic and the beach. Small space, deep detail. Players should know every neighbour by name by the end of Day 3.
5. **Choices leave marks, not branches.** No good or bad endings. Choices change who is at the table on the last day, what the neighbourhood looks like, and which songs the grandmother sings. Everything the player does is remembered, nothing is judged.

## Tone and ethics

This is a game about a real, ongoing catastrophe with real dead. The rules below exist so the game honours that and so it survives press, platform review and community scrutiny.

- **Specific, not generic.** The game is set in Gaza and says so. Places are real (Gaza City, the beach, Rafah, Khan Younis, Jabalia). Food is real (maqluba, musakhan, sumaqiyya, knafeh). The dialect is Gazan Arabic. Genericising it into an unnamed country would be cowardice and the community would see through it.
- **Fictional people, true situations.** No character is a real person. Every situation is drawn from documented, sourced testimony: power schedules, water queues, tent schools, kite festivals, the sea as a place of joy and a border. A sources tab will list what each day's events are based on.
- **Violence is heard, felt and remembered, never shown.** Explosions are sound, light and dust. Injuries are bandages and limps. Death is an empty chair and a name on the wall. This is both an ethical stance and what makes Inside and Valiant Hearts hit harder than gorier games.
- **No slogans in dialogue.** Characters talk about bread, school, football, cousins, the wedding, the boat. The politics is in what happens to them, not in what they say to the camera.
- **Children are protected in the fiction.** The protagonist is a child and sees things through a child's frame. She is never in gratuitous danger, and the game never uses a child's death as a twist.
- **Sensitivity readers before any public build.** At least two Palestinian readers, ideally from Gaza or with family there, review the script and the day designs. Their notes are binding on cultural and linguistic points.
- **Hope is earned.** The ending is not a rescue. The ending is that they are still there, and the player understands why that is a victory.

## Story

One family, the Haddad household, in a street of Gaza City near the sea, over ten days that begin with a kite festival and a wedding and end with the same wedding held in a school courtyard among the rubble. The through-line is a question the grandmother asks on Day 1 and the player answers on Day 10: what does it mean to stay?

**Setting.** A single street, its rooftops, the bakery, the clinic, the UN school, a fishing harbour and the beach. Time is fictional but the conditions are documented: rolling blackouts, water trucks, the three-nautical-mile fishing limit, tent schools, kite festivals on the beach. The year is never stated.

**Cast.** Each family member is playable in specific days and has one physical verb and one social verb. Neighbours are not playable but remember everything.

| Character | Age | Who they are | Physical verb | Social verb |
| --- | --- | --- | --- | --- |
| Layla (protagonist) | 12 | Kite flyer, fast, funny, notices everything | Crawl through gaps, climb, fly the kite | Children follow her |
| Teta Nawal | 71 | Grandmother, keeps the 1948 house key, sings | Cannot climb, walks slowly, carries stories | Every adult opens their door to her |
| Baba Yousef | 44 | Fisherman whose boat may not pass three miles | Lift and carry heavy, push, swim | Fishermen and the harbour |
| Mama Rania | 40 | Teacher who runs a school in the stairwell | Read, repair, organise | Mothers and the clinic |
| Karim | 17 | Brother, footballer, angry, wants to leave | Run fast, jump far, fix electronics | Young men of the street |
| Abu Ahmad | 58 | Baker, the street's oven and its heart | not playable | Bread decides who eats |
| Um Samir | 35 | Nurse at the clinic | not playable | Bandages, generator fuel |
| Sami | 12 | Layla's rival kite flyer and best friend | not playable | Kite duels, secrets |

**Structure.** Ten days in three acts. Each day is one chapter of 25 to 35 minutes with a daylight budget, a night scene and a rooftop moment. The mechanic column is what the day teaches or turns.

| Day | Act | What happens | Mechanic focus | Joy beat |
| --- | --- | --- | --- | --- |
| 1 | Before | Kite festival on the beach; Layla vs Sami; wedding is in nine days | Move, climb, kite basics | Winning a kite duel, knafeh |
| 2 | Before | Wedding shopping, Karim's football match, Teta's stories on the roof | Carry system, character switching | Football on the beach at sunset |
| 3 | Siege | The first night of strikes; power dies; the street organises | Light and power, night traversal | Abu Ahmad bakes for everyone by candlelight |
| 4 | Siege | Water truck arrives at the wrong end of the street | Carry heavy, community queue puzzle | Kids racing empty jerrycans |
| 5 | Siege | School closes; Mama opens the stairwell school | Kite delivers messages across the street | First lesson, a song |
| 6 | Siege | Baba takes the boat out; the limit | Swim, rope and net puzzles | The catch, shared at one table |
| 7 | Siege | Evacuation order; the family walks to the UN school | Choose what to carry, one trip | Teta refuses to leave without the key |
| 8 | Sumud | The school courtyard becomes a neighbourhood; Karim's choice | Repair the generator, lights return | Karim fixes the speaker, music |
| 9 | Sumud | Bread for the wedding; the street rebuilds a kite | Everything together | The dress, the dabke practice |
| 10 | Sumud | The wedding in the courtyard; the beach; the sky | Kite, the final flight | The sky full of kites |

**Choices that leave marks.** Who gets the last generator battery (the clinic or the school). Whether Karim leaves on a boat or stays. Which neighbour you carry on Day 7 when you can carry one. Whether Layla gives her kite away on Day 9. None of these are graded. Each changes who sits at the wedding, which names are on the wall, and what Teta sings.

**Ending.** The wedding happens. The family walks to the beach at dusk. Layla flies the last kite, and every kite the player helped build or save across the game rises with it, one per remembered act of care. Teta says the line from Day 1. They are still there. Credits over the sea.

**Prologue and title card.** The game opens on the sea, with a kite, before any tension, and the title card appears only after the first strike on Day 3. Players should have fallen in love with the street before it is threatened.

## Core mechanics

The game is a side-scrolling adventure with physics puzzles, built on five systems that all feed one loop: decide what to carry, cross the street, help someone, bring light home, sit on the roof. Nothing here needs combat, enemies, or AI pathfinding, which keeps the build within reach of one engineer.

[day loop diagram: Morning (choose what to carry) → The street (cross it, find the way, the kite) → A neighbour (carry, fix, share, switch) → Night (decide who gets light) → The roof (sit, listen, music) → Notebook (the day is written and saved) → next day]

The loop repeats ten times with the same six steps; what changes is how much light and bread there is, and who is still on the street.

**1. Carry (the spine).** The player has two hands and a bag. Everything that matters is carried: bread, a jerrycan, a car battery, a kite, a radio, a child, a wounded neighbour, the grandmother's key. Weight changes movement. Light items leave the player free. Heavy items remove the jump and slow climbing. Two-handed loads (a person, a full water drum) remove climbing altogether, so the route has to change. Choosing the load is choosing the day's plan, and choosing who to carry on Day 7 is the game's hardest decision, made with the hands, not a menu.

**2. The kite (Layla's signature verb).** Wind is a real, visible field in every outdoor level, shown by dust, plastic bags and washing lines. Layla launches the kite, pays out string and steers it through the wind. The kite scouts (the camera follows it over walls), carries light items across gaps and up to roofs (a message, matches, a key), tugs switches and hooks, and signals neighbours with its colour. On Day 1 it fights: kite duels with glass-coated string are a real Gaza pastime and make a great minigame. The kite can be lost, and losing it matters.

**3. Light and power.** Electricity arrives on a schedule that shrinks each day, then stops. Batteries, fuel and a rooftop solar panel are the scarce currency. Darkness is not lethal but it is impassable: a candle, a phone light or a lamp opens the way. Each night the player decides which rooms and which neighbours get power. The street at night, with its lit and dark windows, is the game's only status display. There is no morale bar. You look up and see who has light.

**4. The street (community memory).** Around twenty named neighbours live on the street with needs that change daily: bread, water, medicine, a charger, company, a game of cards. There is no quest log. Helping is noticed, and the help comes back later without being announced: the family you carried water to is the one who saves a seat at the wedding. Every act is written in Layla's notebook, which doubles as the journal and the save summary.

**5. Character switching.** At the home hub and at fixed points, the player switches between whoever is available that day, in the style of Thimbleweed Park. Puzzles are designed around combinations: Layla crawls into the collapsed bakery to reach the flour, Baba lifts the beam, Teta persuades the owner to share the oven. No character is ever a worse version of another; each opens doors the others cannot.

**Time.** Days advance by what the player does, not by a clock. Morning, noon, dusk and night are phases that turn when the day's beats are done, so there is no timer stress, but the sun visibly moves and some things exist only at night.

**Puzzles.** Inside-style physical puzzles: ropes, pulleys, carts, water levels, rubble, planks, nets and the boat. All solvable with the carry rules and the kite, with two or three per day, rising in size. No inventory combining, no pixel hunting.

**Danger.** Strikes are telegraphed by sound and by birds leaving the rooftops. The player finds cover. Failure is a white screen of dust and a return to the last checkpoint, a few seconds back. No death animation, ever, for any character controlled by the player.

**Quiet moments.** Sit spots on the roof, the beach and the stairwell. Sitting starts the music and a slow conversation. Optional, unrewarded, and the thing people will remember.

**Controls.** Keyboard and every major controller, fully remappable. Move, jump, interact, grab and release, kite, switch character, notebook. Eight inputs total, so the game is learnable in Day 1 without a tutorial screen.

## Art direction: Shadow and Thread

The look is layered silhouettes lit by scarce, warm light, with Palestinian embroidery as the language of the interface, and kites as the only fully coloured objects in the world. It is chosen because it reads as a deliberate, premium style (Limbo, Inside, Badland) and because every element of it can be generated from code and shaders, with no painted frames and no 3D models.

**Why not the Silksong look.** Hollow Knight's style is hand-drawn frame animation, which needs an illustrator and an animator for years. Silhouette-and-light gets its beauty from lighting, fog and composition, all of which are shader and geometry work. The premium feel comes from how the light behaves, not from how many pixels were painted.

**World.** Five to seven parallax layers of silhouetted buildings, minarets, water tanks, washing lines and rubble, generated from vector polygons with noise-roughened edges so nothing looks like a rectangle. Volumetric light shafts, drifting dust, smoke, sea haze and rain are particle and shader effects. Windows are small light sources that also serve as the community display at night. Palette shifts by day and by phase: dawn gold, noon white, dusk rose, night indigo, and on siege days a desaturated grey with one accent. Colour is emotional state, as in Gris.

**Characters.** Silhouettes with a single readable trait each: Layla's ponytail and kite string, Teta's cane and long thobe, Baba's cap and shoulders, Rania's bag of books, Karim's ball. Two small warm eye-lights make faces readable and expressive in silhouette. Animation is procedural skeletal rigs with inverse kinematics coded in the engine, which gives weight to carrying: the body genuinely leans and slows under a jerrycan.

**Thread.** Menus, chapter cards, the notebook, loading screens and the wedding dress use tatreez, the Palestinian cross-stitch, which is grid-based and therefore perfectly procedural. Each chapter card stitches itself in while the level loads. The classic red on black and cream sets the interface palette. Kites are flat, saturated and patterned, and they are the only things in the world that carry pure colour into the shadows.

**Hand-made feel from shaders.** Paper grain over everything, ink bleed on silhouette edges, a soft vignette, slight film wobble on cutscenes. These four passes turn clean geometry into something that looks drawn.

**Camera and format.** Side view with depth, 16:9 at 1920 by 1080 native, scaling to 4K, letterboxed only for cinematic beats. Ultrawide supported.

**Production of assets.** Every asset is a script: building generators, kite pattern generators, tatreez pattern generators, character rigs, particle presets. Assets are versioned as code, regenerated on demand, and can be replaced by hand-made art later without touching the game if an artist joins.

## Audio

Music is the emotional engine of Life is Strange and it will be here too. Everything below is producible in code or from public-domain and CC0 material, with one optional line item for a human singer.

**Music.** An original score built on Arabic maqam scales (Hijaz, Bayati, Nahawand, Rast) played by oud, qanun, ney, riq and darbuka, with piano and strings for the quiet moments. One main theme in Hijaz recurs across all ten days in different arrangements. The score is adaptive: layers fade in and out for day, night, threat and rest, so the roof at dusk and the street under strikes share a melody and feel like one place. Composition is done in code as MIDI with maqam microtones, rendered through a soundfont, then mixed with synth pads. Traditional Palestinian folk songs (Dal'ona, Zareef al-Tool, Wein a Ramallah) are public-domain melodies and will be arranged for Teta's rooftop scenes and the wedding dabke.

**Teta's voice.** The lullaby and the wedding song want a real human voice. This is the one asset worth a small budget, recorded by a Palestinian singer. If no budget exists, the melodies are played on ney and the lyrics appear as subtitles.

**Sound design.** Wind, sea, dust and rumble are synthesised so they respond to the wind field and the light state. Bread ovens, cats, market chatter, football and prayer calls come from CC0 field recordings, each checked and credited. Strikes are felt through low rumble, a light change and silence, never a hero explosion sound.

**Voice acting.** None at launch. Dialogue is subtitled, with Arabic on screen and English below, so the Arabic is heard in the player's head in the right dialect. Full Arabic voice acting is a post-launch goal funded by the community if sales allow.

**Mix.** Separate buses for music, ambience, effects, and a dedicated bus for the rumble so players with sound sensitivity can lower it independently.

## Tech

The recommendation is Godot 4 with GDScript, because it is a real shipping 2D engine whose scenes are plain text I can write, whose builds go to Steam and consoles, and which runs headless for automated tests. The alternative is a web stack, which iterates faster but ships worse.

| Option | Strengths | Weaknesses | Verdict |
| --- | --- | --- | --- |
| Godot 4 (GDScript) | Free and open source, 2D lights and shaders built in, scenes as text, headless test runs, exports to Windows, macOS, Linux and web, Steam through GodotSteam, console ports through partners | Needs a 150 MB portable download on this machine; slower iteration than a browser tab | Recommended |
| Web (TypeScript, PixiJS, Electron for Steam) | Fastest iteration, previews inside this app, nothing to install | Controller and Steam support built by hand, heavy Electron builds, weak console path | Fallback for throwaway prototypes only |
| Unity or Unreal | Industry standard console pipelines | Editor-driven workflows need a human at the desk, licensing terms | Not suited to a code-only pipeline |

[pipeline diagram: Generators (Python scripts: buildings, kites, tatreez, rigs, music) → Assets as code (PNG, SVG, OGG, JSON; regenerated on demand; swappable for hand art) → Godot 4 project (GDScript, text scenes, shaders, 2D lights, Steam via GodotSteam) → Builds (Windows, macOS, Linux; web demo on itch; consoles via a partner); Checks on every commit (headless tests, bot playthroughs, nightly builds) feeds the Godot project]

Generators write every asset, the engine assembles and lights them, and a checks step plays every day to completion on each commit so a broken puzzle is caught the same hour.

**Repository layout.** `game/` is the Godot project. `tools/` holds the Python generators for buildings, kites, tatreez, character rigs, music and sound. `assets/` holds their committed output so the project opens without running anything. `docs/` mirrors this document as markdown. `tests/` holds unit tests and the bot playthroughs.

**Saves and journal.** One JSON file per slot containing the day, the phase, and every notebook entry, which is also the list of every remembered act. Cloud saves through Steam.

**Localisation.** All text in a keyed CSV. Godot 4 shapes Arabic and right-to-left text natively through its ICU text server, and the fonts are Amiri and Noto Naskh Arabic under the SIL Open Font License. English uses a humanist sans with a matching hand-drawn display face for chapter cards.

**Testing.** Unit tests for the carry rules, the wind field and the power schedule. A scripted bot plays each day from start to finish on every commit, and screenshots of fixed moments are diffed nightly so a lighting regression is visible as a picture.

**This machine.** Node 20, Python 3.10 and git are already installed. Godot is not; it is a single portable executable with no installer and no administrator rights required.

## Production plan

We build a 40-minute vertical slice of Day 1 and Day 3 first, and nothing else is built until that slice is approved, because those two days contain every pillar, both moods, and every system. If the slice does not make a stranger feel something, the rest of the game would not either, and it is cheaper to learn that early.

[roadmap diagram: Pre-production (this doc, style bible) → gate: answers in, pillars locked → Vertical slice (Days 1 and 3, 40 min playable) → gate: two days playable, look approved → Production (Days 2, 4 to 10, all systems) → gate: ten days playable end to end → Polish and demo (Arabic, access, demo, Next Fest) → gate: readers signed off, Steam page live → Launch (Steam first, consoles after)]

Each gate is a decision you make by playing the build, not by reading a report.

**What the vertical slice contains.** The beach and the kite festival, the kite duel with Sami, the walk home through the street, the home hub with character switching, the rooftop at dusk, then the first night: the strike, the blackout, candle traversal, the bakery puzzle with three characters, and the street at night with its lit windows. Main theme in two arrangements. Chapter cards in tatreez. Full controller support. Everything after that is more of the same at higher quality.

**Honest scope.** The table is what I produce alone and what needs a human, so nothing is discovered late.

| Work | Produced by me | Needs a human |
| --- | --- | --- |
| Design, writing, script, level design | Yes | Two Palestinian sensitivity readers, binding on culture and dialect |
| All code, engine work, shaders, tests | Yes | |
| World, character and interface art | Yes, generated | Optional artist later, assets are swappable |
| Music and sound | Yes, composed and rendered in code | One singer for Teta's two songs, optional |
| Arabic and English text | Yes | Native Gazan dialect review |
| Steam page, trailer, press kit | Drafted and cut by me | Steam account, payment of the fee, legal entity |
| Console ports | Build prepared | A porting partner with dev kits |
| Community and social | Drafted by me | Posting under your name |

**Working rhythm.** Every session ends with a build that runs. Every day of the game is a milestone with its own playtest checklist. Playtesting starts at the slice with five strangers who have not read this document, and their first ten minutes are recorded and reviewed.

## Go-to-market

Steam first, a free demo of Day 1 in a Steam Next Fest, and one marketing idea that is also a feature: players design a kite on the web and it flies in the final sky of everyone's game.

**Platforms and price.** Steam on Windows, macOS and Linux at launch, with the demo also on itch.io. Consoles through a porting partner in the year after launch, Switch first because its audience buys narrative games. Mobile is deliberately last: a Gaza game was pulled from Apple's App Store games category in 2016 (Liyla and the Shadows of War, to be verified and studied as prior art along with its successor Dreams on a Pillow), and we do not want that fight before launch. Suggested price 17.99 USD, between Gris and Inside, with a launch discount and no microtransactions of any kind.

**The kite campaign.** Kites are procedural patterns, so a small web page lets anyone design a kite, name it, and dedicate it. Every dedicated kite is packed into the game and rises in the Day 10 sky. This gives every supporter a reason to share, gives the press a story, and gives the ending a scale no studio could hand-animate. The page launches with the Steam page so wishlists and kites grow together.

**Community.** A Discord from the first public build, weekly development posts showing generators at work (a street growing, a tatreez card stitching itself), and playtest slots given to community members. Streamers of narrative games get the demo a week early.

**Charity.** A fixed share of net revenue to a named medical charity working in Gaza, stated on the store page and audited publicly once a year. This is both right and a reason for people to buy at full price.

**Localisation.** English and Arabic at launch. Then French, Spanish, German, Turkish, Indonesian, Malay and Urdu, which cover the largest solidarity audiences and the biggest Steam markets.

**Accessibility.** Remappable inputs, no timed button sequences, subtitle size and background options, a separate volume for rumble, a toggle for screen shake, a photosensitivity mode that removes the flash from strikes, and kites distinguished by pattern as well as colour for colour-blind players. These are launch requirements, not stretch goals.

**Rating.** Targeting PEGI 12 and ESRB Teen: implied violence, no blood, one off-screen death, themes of war.

**Press angle.** Not a game about a war. A game about a street that refuses to stop being a street. Every preview build opens on the kite festival so the first screenshot anyone takes is joy.

---

# Founder feedback received 2026-09-29 (answers and new requirements)

- "nimbo" = Limbo. Silhouette base confirmed.
- Perpetrator: faceless but NOT completely faceless. Characters can refer to "they". Soldiers may be shown in some way; the country or perpetrator may be shown indirectly if not directly. Founder's words: "we don't be cowards, we also do go straight in and fight them" (interpretation open: confrontation in the fiction, not necessarily combat mechanics).
- Death of children CAN be shown; it is the reality.
- Art: happy with Shadow and Thread but asks whether there can be MORE COLOUR; wants an honest answer on whether we should.
- Absolutely halal: NO haram instruments. Quran or hadith may quietly appear when a related event occurs. Instead of music: halal music (nasheed) or Quran with a relevant verse. Would like references to famous audio such as Dr Israr Ahmed lectures or famous reciters' well-known clips.
- Strikes: real explosion-type sound is probably OK; founder feels we were stripping too much to be soft, but leaves the decision to us.
- Song: founder suggests Google's generative music tool and ElevenLabs for voices; asks whether that is good and what we should do.
- Mobile one day; Steam for now.
- Versatility: it is a chill game but should surprise the player, e.g. a timed button press or similar, plus cinematics, only where it genuinely works, not for its own sake.
- Extra reference: The Kite Runner (the book), liked, but the game must not become a Kite Runner game.
- Engine: Godot approved. Cast: as written. Length: ten days. Readers: founder is Indian, has no Palestinian readers yet, may find someone. Singer: a friend, no hiring. Steam fee: fine.
- Timeline: WORKING PROTOTYPE THIS WEEK; final game in 2 to 3 months (i.e. by roughly end of December 2026).
- Languages: English and Arabic at launch. Charity: "yes, 100%" (ambiguous: either emphatic yes, or 100 percent of revenue). Player kites in the ending: yes. Title: SUMUD for now. One off-screen death and Karim's choice: yes.
- Repository: https://github.com/shahanxd/sumud created by founder; work stays local, commit regularly. Creator credit: shahanxd.
