# Fetches Godot 4.7.2 on first run, imports the project once (class index, fonts, audio) and runs Day 1.
# Usage from the repo root, PowerShell:  .\tools\play.ps1   (add flags: --own-pace --photosensitive --no-grade)
$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root "bin"
$godot = Join-Path $bin "Godot_v4.7.2-stable_win64.exe"
$console = Join-Path $bin "Godot_v4.7.2-stable_win64_console.exe"
$url = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip"
if (-not (Test-Path $godot)) {
	Write-Host "Downloading Godot 4.7.2 for Windows, about 60 MB, once..."
	New-Item -ItemType Directory -Force -Path $bin | Out-Null
	$zip = Join-Path $bin "godot_win64.zip"
	Invoke-WebRequest -Uri $url -OutFile $zip
	Expand-Archive -Path $zip -DestinationPath $bin -Force
	Remove-Item $zip
}
if (-not (Test-Path $godot)) {
	Write-Host "The download did not work. Get Godot_v4.7.2-stable_win64.exe.zip from https://github.com/godotengine/godot/releases/tag/4.7.2-stable and unzip both .exe files into $bin"
	exit 1
}
Write-Host "Importing the project, a minute on the first run..."
$importer = if (Test-Path $console) { $console } else { $godot }
& $importer --headless --path (Join-Path $root "game") --import --quit | Out-Null
& $godot --path (Join-Path $root "game") -- @args
