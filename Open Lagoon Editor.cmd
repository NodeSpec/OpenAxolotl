@echo off
setlocal
if not defined GODOT_BIN set "GODOT_BIN=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_BIN%" (
    echo Godot was not found. Set GODOT_BIN to your Godot 4.7.2 executable.
    pause
    exit /b 1
)
if not exist "%~dp0review" mkdir "%~dp0review"
echo Checking project imports before opening the editor...
"%GODOT_BIN%" --headless --path "%~dp0." --import --log-file "%~dp0review\editor-import.log"
if errorlevel 1 (
    echo Import failed. See review\editor-import.log. The editor was not started.
    pause
    exit /b 1
)
echo Opening the Forward+ editor with Direct3D 12...
"%GODOT_BIN%" --editor --path "%~dp0." --rendering-method forward_plus --rendering-driver d3d12 --single-window --windowed --resolution 1280x720 --screen 0 --position 100,100 --log-file "%~dp0review\editor-startup.log" %*
if errorlevel 1 (
    echo Editor failed. See review\editor-startup.log and Windows Application events.
    pause
    exit /b 1
)
exit /b 0
