@echo off
rem Fetches Godot 4.7.2 on first run, imports the project once and runs Day 1.
rem Double-click, or:  tools\play.bat --own-pace
set ROOT=%~dp0..
set URL=https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip
if not exist "%ROOT%\bin\Godot_v4.7.2-stable_win64.exe" (
	echo Downloading Godot 4.7.2 for Windows, about 60 MB, once...
	if not exist "%ROOT%\bin" mkdir "%ROOT%\bin"
	curl.exe -L -o "%ROOT%\bin\godot_win64.zip" "%URL%"
	tar -xf "%ROOT%\bin\godot_win64.zip" -C "%ROOT%\bin"
	del "%ROOT%\bin\godot_win64.zip"
)
if not exist "%ROOT%\bin\Godot_v4.7.2-stable_win64.exe" (
	echo The download did not work. Get Godot_v4.7.2-stable_win64.exe.zip from
	echo https://github.com/godotengine/godot/releases/tag/4.7.2-stable
	echo and unzip both .exe files into %ROOT%\bin\
	pause
	exit /b 1
)
echo Importing the project, a minute on the first run...
if exist "%ROOT%\bin\Godot_v4.7.2-stable_win64_console.exe" (
	"%ROOT%\bin\Godot_v4.7.2-stable_win64_console.exe" --headless --path "%ROOT%\game" --import --quit >nul 2>&1
) else (
	"%ROOT%\bin\Godot_v4.7.2-stable_win64.exe" --headless --path "%ROOT%\game" --import --quit >nul 2>&1
)
"%ROOT%\bin\Godot_v4.7.2-stable_win64.exe" --path "%ROOT%\game" -- %*
