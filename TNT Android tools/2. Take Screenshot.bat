@echo off
cls
echo.  
setlocal enableDelayedExpansion
powershell write-host -back darkgray -fore white TNT - Android Tools

echo.
echo Preparing to take screenshot...


::initializes adb and displays various error messages if the adb connection fails
echo Initializing ADB (Android Debug Bridge) server...
.\utils\adb shell getprop a > "%temp%\getprop.tmp" 2>&1
if errorlevel 1 (goto connectionError) else (goto noError)
:connectionError
echo.
::sets variable 'errorCode' to the first line of the errorcode:
set /p errorCode=< "%temp%\getprop.tmp"
::removes anything after ';' in the errorcode:
for /f "tokens=1 delims=;" %%g in ("!errorCode!") do (set errorCode=%%g)
::determines what to do based on the errorcode:
if "!errorCode!"=="* daemon not running" (goto tryAgain)
powershell write-host -back red -fore white !errorCode!
echo.
if "!errorCode!"=="error: device unauthorized." (
	powershell write-host -fore darkyellow Ensure the headset is in development mode with `'USB debugging`' enabled`,
	powershell write-host -fore darkyellow and then look in the headset and confirm the USB debugging message.)
if "!errorCode!"=="error: more than one device/emulator" (
	.\utils\adb devices
	powershell write-host -fore darkyellow If you are connected wirelessly`, disconnect the USB cable and press any key.
	echo.
	powershell write-host -fore darkyellow If you are connected wirelessly and no devices are attached by USB cable`,
	powershell write-host -fore darkyellow open tool `#12` and enter `'adb disconnect`'`.
	powershell write-host -fore darkyellow Then connect the headset by USB and try tool `#2 to connect wirelessly again.)
if "!errorCode!"=="error: no devices/emulators found" (
	powershell write-host -fore darkyellow Please ensure headset is powered on and connected by USB or wireless ADB.)
echo.
pause
:tryAgain
.\utils\adb shell getprop a > "%temp%\getprop.tmp" 2>&1
if errorlevel 1 (goto connectionError) else (goto noError)
:noError
echo.



:: Takes screenshot
.\utils\adb shell screencap -p /sdcard/VR_screenshot.png


:: Retreives screenshot
.\utils\adb pull /sdcard/VR_screenshot.png %temp%

:: Displays screenshot
START "" "%temp%\VR_screenshot.png" 