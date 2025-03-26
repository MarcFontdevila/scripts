@echo off
cls
echo.  
setlocal enableDelayedExpansion
powershell write-host -back darkgray -fore white Sixense - Android VR Tools


::initializes adb and displays various error messages if the adb connection fails
echo Initializing ADB (Android Debug Bridge) server...
adb shell getprop a > "%temp%\getprop.tmp" 2>&1
if errorlevel 1 (goto connectionError) else (goto noError)
:connectionError
echo.
::sets variable 'errorCode' to the first line of the errorcode:
set /p errorCode=< "%temp%\getprop.tmp"
::removes anything after ';' in the errorcode:
for /f "tokens=1 delims=;" %%g in ("!errorCode!") do (set errorCode=%%g)
::determines what to do based on the errorcode:
if "!errorCode!"=="* daemon not running" (goto tryAgain)
if "!errorCode!"=="error: more than one device/emulator" (
	powershell write-host -back blue -fore white Note: more than one device/emulator connected:
	adb devices
	goto noError)
powershell write-host -back red -fore white !errorCode!
echo.
if "!errorCode!"=="error: device unauthorized." (
	powershell write-host -fore darkyellow Ensure the headset is in development mode with `'USB debugging`' enabled`,
	powershell write-host -fore darkyellow and then look in the headset and confirm the USB debugging message.)
if "!errorCode!"=="error: no devices/emulators found" (
	powershell write-host -fore darkyellow Please ensure headset is powered on and connected by USB or wireless ADB.)
echo.
pause
:tryAgain
adb shell getprop a > "%temp%\getprop.tmp" 2>&1
if errorlevel 1 (goto connectionError) else (goto noError)
:noError
echo.




echo Type (or right-click to paste) an ADB command.  Examples:
echo.
powershell write-host -fore darkyellow adb devices
echo Shows a list of attached android devices
echo.
powershell write-host -fore darkyellow '"adb shell pm list packages | findstr Sixense"'
echo Shows installed apps with 'Sixense' in the name