#!/usr/bin/env bash
# Runs before every commit: re-import, smoke, core, audio, the sampler bots (Day 3 and 4
# scenes), the Day 1 beat bots, the full Day 1 flow, sprites, the chapter card.
# Exit code is non-zero if anything fails. Usage from the repo root:  bash tools/check.sh
set -u
cd "$(dirname "$0")/.."
GODOT=""
for candidate in ./bin/Godot_v4.7.2-stable_win64_console.exe ./bin/Godot_v4.7.2-stable_linux.x86_64; do
	if [ -x "$candidate" ]; then GODOT=$candidate; break; fi
done
if [ -z "$GODOT" ]; then
	GODOT=$(command -v godot || true)
fi
if [ -z "$GODOT" ]; then
	echo "check: no Godot binary found (expected bin/Godot_v4.7.2-stable_win64_console.exe)"; exit 2
fi
fail=0
"$GODOT" --headless --path game --import --quit >/dev/null 2>&1
echo "== smoke =="
# The real main scene with its autoloads, one frame, then exit 0.
timeout 60 "$GODOT" --headless --path game -- --smoke 2>&1 | grep -E "SUMUD|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== core =="
"$GODOT" --headless --path game res://tests/test_core.tscn -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|core:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== audio =="
timeout 120 "$GODOT" --headless --path game res://tests/test_audio.tscn -- --bot 2>&1 | grep -E "FAIL|audio:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== beach bot =="
"$GODOT" --headless --path game res://tests/bot_beach.tscn 2>&1 | grep -E "FAIL|bot:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== beach beat bot =="
timeout 120 "$GODOT" --headless --path game res://tests/bot_beach_beat.tscn -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|beach beat:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== street bot =="
timeout 180 "$GODOT" --headless --path game res://tests/bot_street.tscn -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|street:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== home bot =="
timeout 240 "$GODOT" --headless --path game res://tests/bot_home.tscn -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|home:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== night bot =="
timeout 180 "$GODOT" --headless --path game res://tests/bot_night.tscn -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|night:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== notebook bot =="
timeout 120 "$GODOT" --headless --path game res://tests/bot_notebook.tscn -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|notebook:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== day 1 beats =="
for b in d1_home_fajr d1_street_morning d1_beach d1_kite_run d1_home_asr d1_roof_maghrib d1_roof_isha d3_roofs_fajr d3_dress d3_strike d3_minaret d3_bakery d3_dark_street d3_roof_night; do
	if [ -f "game/tests/bot_$b.tscn" ]; then
		timeout 200 "$GODOT" --headless --path game "res://tests/bot_$b.tscn" -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|$b:|ERROR|SCRIPT" || true
		[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
	else
		echo "  (no bot_$b yet)"
	fi
done
echo "== full day flow =="
timeout 900 "$GODOT" --headless --path game res://tests/bot_flow.tscn -- --bot --day=1 --notebook=user://test_flow_notebook.json 2>&1 | grep -E "FAIL|flow:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
if [ -f game/scenes/d3_strike.tscn ]; then
echo "== day 3 flow =="
timeout 900 "$GODOT" --headless --path game res://tests/bot_flow.tscn -- --bot --day=3 --notebook=user://test_flow_notebook3.json 2>&1 | grep -E "FAIL|flow:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
fi
echo "== sprites =="
timeout 60 "$GODOT" --headless --path game res://tests/test_sprites.tscn 2>&1 | grep -E "FAIL|sprites:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== chapter card =="
timeout 60 "$GODOT" --headless --path game res://tests/shot_card.tscn 2>&1 | grep -E "card finished|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
if [ "$fail" -eq 0 ]; then echo "check: all green"; else echo "check: FAILED"; fi
exit $fail
