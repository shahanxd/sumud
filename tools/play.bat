@echo off
rem Imports the project once and runs Day 1. Double-click, or:  tools\play.bat --own-pace
set ROOT=%~dp0..
if not exist "%ROOT%\bin\Godot_v4.7.2-stable_win64.exe" (
	echo Put Godot_v4.7.2-stable_win64.exe and its _console.exe in %ROOT%\bin\ ^(https://github.com/godotengine/godot/releases/tag/4.7.2-stable^)
	pause
	exit /b 1
)
if exist "%ROOT%\bin\Godot_v4.7.2-stable_win64_console.exe" (
	"%ROOT%\bin\Godot_v4.7.2-stable_win64_console.exe" --headless --path "%ROOT%\game" --import --quit >nul 2>&1
) else (
	"%ROOT%\bin\Godot_v4.7.2-stable_win64.exe" --headless --path "%ROOT%\game" --import --quit >nul 2>&1
)
"%ROOT%\bin\Godot_v4.7.2-stable_win64.exe" --path "%ROOT%\game" -- %*
