@echo off
cls
setlocal enableDelayedExpansion
echo.  
powershell write-host -back darkgray -fore white Sixense - Android VR Tools

::initializes adb if it's not initialized
..\adb shell getprop a >nul 2>&1
echo.


IF NOT exist "!USERPROFILE!\Desktop\Screenshots\" (md "!USERPROFILE!\Desktop\Screenshots\")


powershell write-host -back darkgray -fore white Copying screenshots...
echo.
..\adb pull /sdcard/oculus/Screenshots/ !USERPROFILE!\Desktop\

echo.
powershell write-host -back darkgray -fore white Screenshots copied to: 
powershell write-host -back darkgray -fore white !USERPROFILE!\Desktop\Screenshots\

::open destination folder in explorer
%SystemRoot%\explorer.exe "!USERPROFILE!\Desktop\Screenshots\"



echo.
