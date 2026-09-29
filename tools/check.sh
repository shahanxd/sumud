#!/usr/bin/env bash
# Runs before every commit: re-import, headless smoke test, beach bot, chapter card test.
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
echo "== beach bot =="
"$GODOT" --headless --path game res://tests/bot_beach.tscn 2>&1 | grep -E "FAIL|bot:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== beach beat bot =="
timeout 120 "$GODOT" --headless --path game res://tests/bot_beach_beat.tscn -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|beach beat:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== street bot =="
timeout 180 "$GODOT" --headless --path game res://tests/bot_street.tscn -- --bot --notebook=user://test_notebook.json 2>&1 | grep -E "FAIL|street:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== chapter card =="
timeout 60 "$GODOT" --headless --path game res://tests/shot_card.tscn 2>&1 | grep -E "card finished|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
if [ "$fail" -eq 0 ]; then echo "check: all green"; else echo "check: FAILED"; fi
exit $fail
