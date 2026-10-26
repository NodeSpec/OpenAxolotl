@echo off
setlocal
if not defined GODOT_BIN set "GODOT_BIN=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_BIN%" (
    echo Godot was not found. Import project.godot in Godot 4.7.2 or set GODOT_BIN to your Godot executable.
    pause
    exit /b 1
)
"%GODOT_BIN%" --path "%~dp0." --rendering-method forward_plus --rendering-driver d3d12 --windowed --resolution 1280x720 %*
exit /b %ERRORLEVEL%
