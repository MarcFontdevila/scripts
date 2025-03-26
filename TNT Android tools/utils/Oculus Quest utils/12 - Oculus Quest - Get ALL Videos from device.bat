@echo off
cls
setlocal enableDelayedExpansion
echo.  
powershell write-host -back darkgray -fore white Sixense - Android VR Tools

::initializes adb if it's not initialized
..\adb shell getprop a >nul 2>&1
echo.


IF NOT exist "!USERPROFILE!\Desktop\VideoShots\" (md "!USERPROFILE!\Desktop\VideoShots\")


powershell write-host -back darkgray -fore white Copying videos...
echo.
..\adb pull /sdcard/oculus/VideoShots/ !USERPROFILE!\Desktop\

echo.
powershell write-host -back darkgray -fore white Videos copied to: 
powershell write-host -back darkgray -fore white !USERPROFILE!\Desktop\VideoShots\

::open destination folder in explorer
%SystemRoot%\explorer.exe "!USERPROFILE!\Desktop\VideoShots\"



echo.
