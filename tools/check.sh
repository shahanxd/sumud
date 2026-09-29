#!/usr/bin/env bash
# Runs before every commit: re-import, headless smoke test, beach bot, chapter card test.
# Exit code is non-zero if anything fails. Usage from the repo root:  bash tools/check.sh
set -u
cd "$(dirname "$0")/.."
GODOT=./bin/Godot_v4.7.2-stable_win64_console.exe
if [ ! -x "$GODOT" ]; then
	GODOT=$(command -v godot || true)
fi
if [ -z "$GODOT" ]; then
	echo "check: no Godot binary found (expected bin/Godot_v4.7.2-stable_win64_console.exe)"; exit 2
fi
fail=0
"$GODOT" --headless --path game --import --quit >/dev/null 2>&1
echo "== smoke =="
"$GODOT" --headless --path game -s res://tests/smoke.gd 2>&1 | grep -E "smoke:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== beach bot =="
"$GODOT" --headless --path game res://tests/bot_beach.tscn 2>&1 | grep -E "FAIL|bot:|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
echo "== chapter card =="
timeout 60 "$GODOT" --headless --path game res://tests/shot_card.tscn 2>&1 | grep -E "card finished|ERROR|SCRIPT" || true
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
if [ "$fail" -eq 0 ]; then echo "check: all green"; else echo "check: FAILED"; fi
exit $fail
