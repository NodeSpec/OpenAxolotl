@echo off
setlocal
if not defined GODOT_BIN set "GODOT_BIN=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_BIN%" (
    echo Set GODOT_BIN to your Godot executable or run tools/lagoon_preview.gd from Godot.
    pause
    exit /b 1
)
"%GODOT_BIN%" --path "%~dp0." --audio-driver Dummy --resolution 1600x900 --script tools/lagoon_preview.gd
pause
