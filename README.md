# SUMUD

A 2D narrative adventure about one family in Gaza, told over ten days. A game about staying.

Made by shahanxd. Built in Godot 4.7.2. Start with `docs/HANDOFF.md`.

## Layout

- `game/` the Godot project (open `game/project.godot`); tests and bots in `game/tests/`
- `tools/` `check.sh` (run before every commit), `play.bat` and `play.ps1` (play on Windows), `setup_linux.sh`, `audio.py` (placeholder sound), `tatreez.py`
- `docs/` everything else: `HANDOFF.md` is the entry point
- `bin/` the Godot binaries (not committed, see below)

## Setup on Windows

1. Download `Godot_v4.7.2-stable_win64.exe.zip` from the official Godot releases (https://github.com/godotengine/godot/releases/tag/4.7.2-stable) and unzip both `.exe` files into `bin/`.
2. Play Day 1: double-click `tools\play.bat`, or in PowerShell `.\tools\play.ps1`. The script imports the project first (a fresh checkout has no `.godot/` folder, so the engine has to index the classes and convert the fonts once; running the binary directly without that step fails with "Could not find type Beat").
3. Flags: `tools\play.bat --own-pace` (no timer on the strike), `--photosensitive` (softer flash), `--no-grade` (turn the print pass off).
4. Controls: A/D move, Space jump, hold S to crawl, E grab or drop and talk or sit, Q launch or reel in the kite, W/S let out or reel, Tab switch character where allowed.

Tests on Windows: `bash tools/check.sh` from Git Bash, or `bin\Godot_v4.7.2-stable_win64_console.exe --headless --path game --import --quit` once and then the individual `res://tests/*.tscn` scenes with `-- --bot`.
