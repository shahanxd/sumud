# Imports the project once (class index, fonts, audio) and runs Day 1.
# Usage from the repo root, PowerShell:  .\tools\play.ps1   (add flags: --own-pace --photosensitive --no-grade)
$root = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $root "bin\Godot_v4.7.2-stable_win64.exe"
$console = Join-Path $root "bin\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godot)) {
	Write-Host "Put Godot_v4.7.2-stable_win64.exe and its _console.exe in $root\bin\ (from https://github.com/godotengine/godot/releases/tag/4.7.2-stable)"
	exit 1
}
$importer = if (Test-Path $console) { $console } else { $godot }
& $importer --headless --path (Join-Path $root "game") --import --quit | Out-Null
& $godot --path (Join-Path $root "game") -- @args
