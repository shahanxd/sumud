# Codebase guide

For an engineer or agent picking up SUMUD. The code is the first playable (the Day 1 sampler); much of it survives into production, some is replaced (marked below).

## Run it

- **Linux (the cloud container):** `bash tools/setup_linux.sh` fetches the Godot 4.7.2 binary into `bin/` if missing. `bash tools/check.sh` imports, then runs every test; it must print `check: all green` before any commit.
- **Windows (the founder):** `tools\play.bat` or `tools\play.ps1`. They import first (a fresh clone has no `.godot/`; skipping the import gives "Could not find type Beat"), then run. Flags: `--own-pace`, `--photosensitive`, `--no-grade`.
- **Render a frame (Linux, no GPU):** `xvfb-run -a -s "-screen 0 1920x1080x24" bin/Godot_v4.7.2-stable_linux.x86_64 --rendering-method gl_compatibility --rendering-driver opengl3 --path game res://tests/shot_scene.tscn -- --scene=res://scenes/beach.tscn --phase=dusk --kite --no-hud --out=/tmp/x.png --frames=170` (also `--pos=x,y`, `--shots=a.png@60,b.png@200`). `res://tests/shot_main.tscn` renders the real start of the game through `main.tscn` at the founder's window size (1920x1010); **look at that before handing any build over**. `res://tests/shot_figures.tscn -- --out=/tmp/sheet.png` renders the character pose sheet.

## Layout

```
game/                  Godot project (open game/project.godot)
  scenes/              main, beach, street, home, night_street, notebook_page, chapter_card, player, kite, props
  scripts/             gameplay: player, npc, figure (rig), kite, wind, camera_rig, carryable, plank, beam,
                       sea, skyline, facades, wind_dust, chapter_card, main
  scripts/core/        autoloads and the beat system (see below)
  scripts/beats/       one script per beat scene
  scripts/ui/          scripture_card.gd (the Cards autoload)
  shaders/             sky, sea, grade
  data/                lines.csv (keyed dialogue), scripture.csv, palette.json, street_windows.json
  assets/              audio (synthesised placeholders), fonts (Amiri, Noto Naskh Arabic, OFL), tatreez
  tests/               unit tests, bots, render scenes
tools/                 check.sh, play.bat/.ps1, setup_linux.sh, audio.py (placeholder sound synth), tatreez.py
docs/                  see docs/HANDOFF.md
bin/                   Godot binaries (not committed)
```

## The spine: autoloads, in load order

| Autoload | File | Does |
| --- | --- | --- |
| Wind | scripts/wind.gd | Noise wind field; `sample(pos)` |
| Look | core/look.gd | Palette per day and phase from `data/palette.json`: sky, sea, ambient, ground, haze |
| Grade | core/grade.gd | Screen-space print pass (grain, vignette, tint, dither, wobble); `--no-grade` |
| Sound | core/sound.gd | Five buses (voices, ambience, effects, rumble, strike); `play`, `play_at`, `loop`, `stop_loop`, `duck`, `unduck`, `step` |
| Notebook | core/notebook.gd | Layla's entries and marks to JSON; acts that become kites |
| Fx | core/fx.gd | Fade, strike flash, white-out, letterbox |
| Settings | core/settings.gd | `--own-pace`, `--photosensitive` |
| Cards | ui/scripture_card.gd | Scripture cards as full stops: pauses play, silences every bus, text from `scripture.csv`. Known gap: its hadith font is Amiri Regular, a body font; the design document requires a Quran face (KFGQPC or Amiri Quran) for every card. Fix with a `test_core` check before any card ships |
| Say | core/say.gd | Arabic over English lines from `lines.csv` by key |
| Day | core/day_runner.gd | Chains a day's beat scenes with fades and the chapter card |

## Beats

A beat is a scene whose root extends `Beat` (`core/beat.gd`), which emits `finished` when its goal is met. `Day` loads the beats of a day in order (`DAYS` in `core/day_runner.gd`; a listed scene that does not exist yet is skipped with a warning). **Day 1 (since 1 October) follows `docs/story/day1-script.md`**: `d1_home_fajr` (Scenes 0 and 1), `d1_street_morning` (2), `d1_beach` (3 to 5), `d1_kite_run` (6), `d1_home_asr` (7), `d1_roof_maghrib` (8), `d1_roof_isha` (9), `notebook_page`. Each `d1_*.tscn` is an **inherited scene** of one of the three spaces (`home.tscn`, `street.tscn`, `beach.tscn`) with its own beat script under `scripts/beats/` and its own bot `tests/bot_d1_*`; that is how one space carries several phases of the day until lock I-04's single continuous day scene exists. The sampler's beats stay as Day 3 (`home.tscn` strike, `night_street.tscn`) and Day 4 (`street.tscn` water run) placeholders. Shared helpers: `Beat.hold_action(action, seconds, near, on_progress)` (hold to tie, stitch, free; 0.25 s in bot mode), `Beat.adhan(day, phase, seconds)` (the phase turn where a recorded adhan will drop in), `Say.choose(keys)` (an answer choice: up/down and interact; `Say.bot_choice` picks in bot mode; `Say.last_choice` for tests). Context marks that cross beats: `d1_contest_winner`, `d1_tail_tied`, `d1_promise`, `d1_fix_answer`, `d1_amina_laundry`, `d1_thread_taken`, `d1_kite_patched`, `d1_held_still`; Day 3: `candle` / `d3_struck`, `d3_bread_for_street`, `d3_bread_order`. **Day 3** follows `docs/story/day3-script.md` the same way (`d3_*` scenes inheriting `home.tscn` and `night_street.tscn`; `neighbour_roof.tscn` is the shared roof across the gap; the night beats extend `night_street_beat.gd` for darkness, drafts and windows). `tests/bot_flow.gd` takes `--day=1` or `--day=3` and holds one expectation table per day; `tools/check.sh` runs every `bot_d1_*` and `bot_d3_*` that exists, then both flows. Scripture keys for cards come only from `data/scripture.csv`, whose rows are copied by script from the verified table in `docs/gdd.md`.

## Characters

`scripts/figure.gd` draws every person as bones each frame. `scripts/sprite_figure.gd` (`SpriteFigure extends Figure`) replaces the drawing with an `AnimatedSprite2D` when `assets/characters/<name>/frames.tres` exists (built by `game/tools/build_frames.gd` from strips that `tools/roto.py` makes out of generated or filmed frames), moves the `Hand` node to the per-frame point in `hands.json`, drives walk/run/crawl from the owner's `phase` so feet stay planted, and falls back to bones otherwise. Switch a character by pointing their scene's Visual node at `sprite_figure.gd` and setting `character`. Animation names: idle, walk, run, jump, crawl, sit, with `_kite`, `_carry`, `_heavy`, `_twohand` variants looked up first.

`scripts/player.gd` holds movement (run 320, jump -640 with a 0.45 release cut, ground accel 4000 and decel 5400, air 1400, coyote 0.1 s, buffer 0.1 s, skid), carry classes, crawl, switching, impact-scaled landing (`landed` signal, `land_squash`) and the F3 tuning overlay (never under bot mode or `--smoke`); `camera_rig.gd` holds the camera (`ground_zoom` 1.3, smoothed look-ahead 140, 120 px edge clamp, kite pull-out). `scripts/sprite_figure.gd` is the frame-driven replacement for `figure.gd` (see Characters). Feel targets are in `docs/design/feel-and-readability.md`.

## Tests

`tools/check.sh` runs, in order: smoke (main scene one frame), `test_core`, `test_audio` (includes the halal audit of files and buses), `bot_beach`, `bot_beach_beat`, `bot_street`, `bot_home`, `bot_night`, `bot_notebook`, `bot_flow` (the whole of Day 1 through `Day.start(1)`), `test_sprites` (SpriteFigure against Layla's frames or the bone fallback), `shot_card`. Bots live in `game/tests/`, share `bot.gd` and `bot_driver.gd`, press real inputs and walk with real physics. **Teleport only to set up a test, never to cross a gap the player must cross** (playtest 1: the stairs passed a teleporting bot and nobody could climb them).

## Conventions

- Typed GDScript. The project treats inferred-Variant declarations as errors: type every variable that comes from a Dictionary, `call()` or an Array literal.
- No lambdas that capture nodes (they outlive the node and crash on free).
- Dialogue and every visible string go in `data/lines.csv` by key (`d1.<scene>.<speaker>.<nn>` for the production script), Arabic and English.
- `*.csv.import` files for `lines.csv` and `scripture.csv` are committed with `importer="keep"` so Godot does not turn them into translations. The `scripture.*.translation` files in `game/data/` are stale leftovers from before that; they are unused and can be deleted with a check run.
- WAV loops carry their own `smpl` chunk (`tools/audio.py` writes it).
- `Parallax2D` layers keep `scroll_scale.y = 1.0` so they stay on the horizon.
- Every asset gets a `docs/rights.md` row before it is merged. Nothing AI-generated enters the repository (lock F-01).
- Commits: `bash tools/check.sh` green; no model identifiers in messages or files.

## Gotchas learned the hard way

- `main.tscn` must hold only `Main` and the title layer. A stale `Camera2D` and full-screen `ColorRect`s there once froze the camera and covered the sky; `test_core` now asserts it and `camera_rig.gd` calls `make_current()`.
- Stairs in `home.tscn` zigzag with one-way wells in the floors above; a flight's foot must be reachable on foot. `bot_home` walks the route.
- `bot_driver` must stop its loops and wait a frame before `quit()`, or Godot reports leaked resources at exit.
- The cloud container reaches GitHub and package registries only. Renders need `xvfb-run` and the compatibility renderer; the founder's machine runs Forward+ on Vulkan, so check lights and shaders there too.
- Export templates are 1.3 GB; the founder exports on Windows (`bin\Godot_v4.7.2-stable_win64_console.exe --headless --path game --export-release "Windows Desktop"`). Ask before any GitHub release.
