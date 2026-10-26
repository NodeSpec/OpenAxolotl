@echo off
setlocal
if not defined GODOT_BIN set "GODOT_BIN=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_BIN%" (
    echo Set GODOT_BIN to your Godot executable or run tools/hero_review.gd from Godot.
    pause
    exit /b 1
)
pushd "%~dp0"
"%GODOT_BIN%" --path . --audio-driver Dummy --fixed-fps 30 --write-movie review/hero-motion.avi --log-file review/hero-review.log --script tools/hero_review.gd
set "RESULT=%ERRORLEVEL%"
popd
pause
exit /b %RESULT%
