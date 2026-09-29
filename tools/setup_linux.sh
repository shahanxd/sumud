#!/usr/bin/env bash
# Fetches the Godot 4.7.2 Linux editor into bin/ (not committed) and sets up the Python venv.
# Usage from the repo root:  bash tools/setup_linux.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p bin
if [ ! -x bin/Godot_v4.7.2-stable_linux.x86_64 ]; then
	curl -L -s -o bin/godot_linux.zip \
		"https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip"
	unzip -o -q bin/godot_linux.zip -d bin
	rm -f bin/godot_linux.zip
	chmod +x bin/Godot_v4.7.2-stable_linux.x86_64
fi
bin/Godot_v4.7.2-stable_linux.x86_64 --version
if [ ! -d .venv ]; then
	python3 -m venv .venv
	.venv/bin/python -m pip install --quiet --disable-pip-version-check pillow numpy
fi
echo "setup: done"
