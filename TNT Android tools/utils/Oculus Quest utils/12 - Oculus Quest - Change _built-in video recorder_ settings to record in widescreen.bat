@echo off
cls
setlocal enableDelayedExpansion
echo.  
powershell write-host -back darkgray -fore white Sixense - Android VR Tools

echo.
echo This batch changes some of the Oculus rendering settings under the hood.
echo The purpose is to make the built-in Oculus video recorder output in a widescreen format.
echo This can negatively affect performance in graphics-heavy apps, but it shouldn't be too bad.
echo Restart your Quest to return to default settings.

::initializes adb if it's not initialized
..\adb shell getprop a >nul 2>&1
echo.
echo Sending confuguration change.

:: 720p
::set captureWidth=1280
::set captureHeight=720

:: 1080p
set captureWidth=1920
set captureHeight=1080


..\adb shell setprop debug.oculus.capture.width !captureWidth!
..\adb shell setprop debug.oculus.textureWidth !captureWidth!
..\adb shell setprop debug.oculus.capture.height !captureHeight!
..\adb shell setprop debug.oculus.textureHeight !captureHeight!

..\adb shell setprop debug.oculus.capture.bitrate 10000000
..\adb shell setprop debug.oculus.foveation.level 0
..\adb shell setprop debug.oculus.capture.fps 30


echo.
echo Complete.  Press any key to exit.
pause > nul