# Handoff: where SUMUD stands on 29 September 2026 (night)

Read this first when picking the project up in a new session.

## The founder

shahanxd (GitHub). Indian, a practising Muslim; everything in the game must be halal. No art or audio budget; a friend may sing; will pay the Steam fee. Writes informally, wants the blunt truth and maximum effort, delegates judgement ("you decide") when given a recommendation, and asked for self-proofreading before anything is delivered. Creator credit: shahanxd. On 29 September the founder said, in order: the final design document comes first; then "this is a world class game, so we need world class assets and everything; build the small prototype first."

## Where things live

- **Design document (living, commentable):** https://claude.ai/code/artifact/edb009e1-ac2b-462a-8860-f031366c2ec2 — a Claude Doc, v0.2, rev 79. Doc id `edb009e1-ac2b-462a-8860-f031366c2ec2`, tab file id `97c63c3c-32af`, body node id `dc81e545-7518`. Edit it with the docs tools, never by publishing HTML. `docs/gdd.md` is a faithful markdown snapshot of rev 79.
- **Research, verification and critiques:** `docs/research/`, numbered. 00 the original v0.1 doc and the founder's feedback; 01 to 08 research lenses; 09 to 12 critiques of the design; 13 to 18 independent verification passes; 19 to 22 the edit lists and final checks that made v0.2; **23 the first art critique of the prototype renders**, with what was applied marked DONE. Nothing in the doc may contradict 13 to 18.
- **Decisions log:** `docs/decisions.md`. **Rights ledger:** `docs/rights.md`. **Outreach drafts:** `docs/outreach.md`.

## The founder's answers of 29 September (locked)

Limbo as the art base, with more colour carried by light; Godot; the cast as designed; ten days; English and Arabic at launch; player kites in the ending; title SUMUD for now; one death and Karim's choice; no combat; the perpetrator is "they", faceless but present; the game must feel defiant, not cowardly; children's deaths may be shown; absolutely halal (no instruments, Quran or hadith quietly at related moments, halal nasheed instead of music); a real explosion sound is fine; mobile one day, Steam first; surprise moments and cinematics only where they work; The Kite Runner as a liked reference, not a template; prototype this week, final game in two to three months; charity "yes, 100%" (meaning to be clarified).

## The design document is finished (v0.2, rev 79)

Scripture moments filled (22 items, every string extracted from `research/03` by script and checked as a verbatim substring); critiques 11 (culture and faith) and 12 (market) folded in; verification corrections applied; proofread; a final two-agent check applied 29 of 31 items. sunnah.com is blocked from the cloud container, so **Sahih al-Bukhari 1284 and Sunan Ibn Majah 1896 still carry only their first verification**: open https://sunnah.com/bukhari:1284 and https://sunnah.com/ibnmajah:1896 in a browser and match the shown lines, the reference numbers and the grade line before their cards ship. The section says so.

## Pending founder confirmations

- Sami as Layla's cousin next door (relation only) and Teta's biography (her mother's key), both flagged for the readers.
- The two Arabic fonts (Amiri 1.001, Noto Naskh Arabic 2.019, OFL) in `game/assets/fonts/`; say so to remove them.
- Decisions 5 (charity wording and organisation), 13 and 14, plus the earlier 1 to 12.
- The Steam Direct fee and Steamworks onboarding this week.
- Layla's headscarf is now drawn cream (her one accent, the doc's white scarf); confirm or change `scarf_color` in `game/scenes/player.tscn`.
- Signs in the world: the street bakery reads "مخبز أبو أحمد" (Abu Ahmad's bakery, a named character) and the beach kiosk "كشك الشاطئ" (the beach kiosk). Change them if the readers object.

## The prototype today (Day 1, one continuous playable, all green)

`bash tools/check.sh` runs: the main scene with `--smoke`; `tests/test_core` (14 checks on the spine); `tests/test_audio` (48 checks on buses, files, loops, duck); the 16-check legacy beach bot; the beach beat bot (10); the street bot (18); the home bot (24); the night bot (15); the notebook bot (4); the **full Day 1 flow** (`Day.start(1)` in bot mode, 79 checks, writes a notebook JSON); the chapter card. Green at the last commit of the session.

**Spine (autoloads, in order):** `Wind` (a noise wind field, `sample(pos)`), `Look` (the palette: `data/palette.json` per day and phase drives sky, sea, ambient, ground, skyline haze and the print pass), `Grade` (screen-space print pass: grain, vignette, tint, dither; `--no-grade`), `Notebook` (Layla's entries to JSON, acts that become kites), `Fx` (fade, strike flash, white-out, letterbox), `Settings` (`--own-pace`, `--photosensitive`), `Cards` (scripture cards as full stops, text from `data/scripture.csv`, ducks every sound bus), `Say` (Arabic over English from `data/lines.csv`), `Sound` (five buses: voices, ambience, effects, rumble, strike; play, play_at, loop, stop_loop, duck, unduck, step), `Day` (chains the five Beat scenes with fades and the chapter card).

**Beats (each a scene with a `Beat` root and a bot):** beach (Sami asks; the kite fetches the string spool from the kiosk roof), street (the water run, the pit, the two-handed plank), home (Layla and Baba switch, the roof sit with Teta at dusk, the card, the birds, the strike, the beam, the candle), night street (lit and dark windows from `data/street_windows.json`, candle traversal, relighting a neighbour's window, the oven), notebook page (Bismillah, the entries, the tatreez end card).

**Look (this session):** `shaders/sky.gdshader` (gradient, one sun or moon riding the world horizon, haze band, point stars, dither), `shaders/sea.gdshader` + `scripts/sea.gd` (bounds from the polygon; sky reflected by depth; sun-tinted, sideways-stretched glitter denser under the sun; broken swell rows; foam), `shaders/grade.gdshader`, `scripts/skyline.gd` (per-building polygons, tanks, minarets, towers, thins into open sea for the beach's far coast, no vertical parallax), `scripts/facades.gd` (the street's near plane: plastered shop-houses with shutters, awnings, balconies, laundry, tanks, solar panels, rebar, the bakery's lit oven mouth and sign, a pavement), `scripts/wind_dust.gd`, `scripts/camera_rig.gd` (`ground_zoom` 1.3, kite pull-out, tells the sky where the horizon falls), the furnished home cross-section (majlis, table, shelf, gas bottle, tatreez frame, wardrobe, rolled mattresses, ceiling bulb light, stepped flights, roof mat, laundry line, plant tin, dish, rebar), the beach props (hasaka on its keel with mast and gunwale, slatted crates, a breeze-block wall with a crawl gap, the kiosk with hatch, awning and sign), `scripts/carryable.gd` items drawn by label (loaves, jerrycan, drum, spool, candle) with a contact shadow.

**Characters:** `scripts/figure.gd` is one procedural rig for everyone (bones drawn each frame: planted walk, breathing, crawl, sit, carry poses, the kite arm, a jump tuck, hands, a headscarf whose tail rides the wind, short and long dresses, an elder's stoop and cane, warm eyes, a contact shadow; `build`, `headscarf`, `scarf_color`, `dress`, `cane`, `shoulder`, `depth_lift`). `Player` and `Npc` drive it. `tests/shot_figures.tscn` renders a pose sheet.

**Audio:** `tools/audio.py` synthesises the 26 WAVs in `game/assets/audio/` from noise and resonances with fixed seeds (no recording, download or AI; no instruments); `game/assets/audio/README.md` says what each is for; `roof_breath_loop.wav` is a PLACEHOLDER for the friend's vocal pad and must be replaced before any build leaves the machine. Wired: footsteps on sand or concrete at each foot plant (`Player.surface`), grab and drop (heavy thud for heavy loads), the candle going out, the kite's flap while flying, ambience loops per beat (sea and wind on the beach, faint wind elsewhere) stopped by `Day` at each transition, the roof pad fading in when Layla sits with Teta, the strike (birds leave, every loop cut, the bang on the strike bus, ringing under the white-out, wind back after seven seconds), the door, cloth on sitting and switching, the notebook's pages and the stitches of the chapter and end cards. `Cards` silences every bus for a scripture card and unducks after. `Sound.last_played` and `play_count` exist for tests.

**Render for review (Linux, no GPU):** `xvfb-run -a -s "-screen 0 1920x1080x24" bin/Godot_v4.7.2-stable_linux.x86_64 --rendering-method gl_compatibility --rendering-driver opengl3 --path game res://tests/shot_scene.tscn -- --scene=res://scenes/beach.tscn --phase=dusk --kite --no-hud --out=/tmp/hero.png --frames=170` (also `--pos=x,y`, `--shots=a.png@60,b.png@200`). The pose sheet: `res://tests/shot_figures.tscn -- --out=/tmp/sheet.png`.

**Export:** `game/export_presets.cfg` holds a Windows Desktop preset (`../build/windows/sumud.exe`, embedded pck). Export templates are 1.3 GB from GitHub; the founder exports on Windows with `bin/Godot_v4.7.2-stable_win64_console.exe --headless --path game --export-release "Windows Desktop"`. Ask before any GitHub release.

## Next (in order)

Week 1's gate is unchanged: one stranger plays ten minutes with no instructions, understands carrying, names a moment that landed, no crash. The playable exists; what remains is the bar the founder set. `docs/research/23-art-critique-1.md` is the list; the unapplied items, ranked:

1. Kill the flat ground everywhere: a ground shader (noise-roughened top edge, value gradient, a wet band and foam line on the beach sharing the sea's TIME, hash speckle, footprints behind the player) and a foreground occluder plane on the beach (a net on poles, rope, a beached bow, grass).
2. Make lights light: `shadow_enabled` with `LightOccluder2D` on floors, flights and figures; PointLight2D spill per lit window (home, night street); lift the night street's facade albedo from 0.06 to about 0.2 and let the ambient make the dark; smoke motes over the oven.
3. Night street facades: use `Facades` (or its recipe) in `night_street_beat.gd _build`, a dense default grid of dark windows generated from each house with the lit and act windows placed among them, neighbours on doorsteps with phone-torch lights, a moon gradient on the road, the plank as a slab with end grain over a pit with depth.
4. Beach specificity: the coast to one side only with a breakwater arm and a harbour light, masts of moored hasakas, a midground plane at scroll 0.6 (corniche rail, palms with fronds on the wind, a tented shade), a painted band and a net on the boat, crates as ribbed baskets; a proper minaret profile in `skyline.gd`.
5. Characters, not one rig: Baba's cap, Abu Ahmad's apron line and belly, Mama's hijab drape, a background-coloured halo under the near limbs, a second hand node for props.
6. Windows as light sources everywhere (grille, pane gradient, HDR pane with a WorldEnvironment glow, spill).
7. The print grade's ink: a 1 to 1.5 px low-frequency UV wobble and blue noise in `grade.gdshader` (started: the wobble is in).
8. Dialogue: non-breaking spaces in "أبو أحمد" and "Abu Ahmad's" in `lines.csv`, a stitch line along the box's top edge, keep the box off the player.
9. A second fresh-eyes critique on the new renders, then the stranger test.

After that: Day 3 (the second tentpole) per the doc's Structure table; the Windows export on the founder's machine; the Steam page assets from the hero shots.

## Rules to keep

- Every session ends with a build that passes `bash tools/check.sh` and a commit. Commit messages carry no model identifiers.
- No instruments, ever. Voices, duff at the wedding only, world sound. No Quran under gameplay, music or effects; a card silences every bus; skip only at ayah boundaries. No AI-generated audio, voices, Quran or art ships. Synthesised pads must not imitate instruments.
- The perpetrator is never a character or a target. No combat mechanics.
- Sami's death is aftermath only, never preventable, never a fail state, never caused by a player choice. Children's deaths may be shown as aftermath.
- Day 1 has no drone hum and no rumble; the zanana arrives faintly on Day 2.
- Check facts against the verification files before writing them into the doc or the game. Do not invent named people on signs or in lines.
- The cloud container's network reaches GitHub and the package registries only; sunnah.com, quran.com, Kenney and Freesound are blocked. Verify scripture in a browser. Renders need `xvfb-run` and the GL compatibility renderer; there is no Vulkan surface.
- Godot 4.7 notes: the project treats inferred-Variant declarations as errors (type every variable from a Dictionary, `call()` or an Array literal); no lambdas that capture nodes; `*.csv.import` files are committed with `importer="keep"`; WAV loops carry their own `smpl` chunk; `Parallax2D` layers keep `scroll_scale.y = 1.0` so they stay on the horizon.
