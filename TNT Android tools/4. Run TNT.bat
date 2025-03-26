@echo off
cls
echo.  
setlocal enableDelayedExpansion
powershell write-host -back darkgray -fore white TR Reloaded - Android Tools

:: This batch will stop (if it's running), and then restart, any app on the device that *ends* with this string:
set "appName=TR Reloaded"


::deletes these files if they were left behind on a previous run where the user closed the window
del "%temp%\sixense_packagelist.tmp" >nul 2>&1
del "%temp%\sixense_packagelist_withoutpackageprefix.tmp" >nul 2>&1


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




::skip to the end if no applicable packages are installed
::note that findstr /e returns results only if they are at the end of the line.
::This prevents finding WorldTraveler from returning WorldTravelerStaging as a result, etc.
.\utils\adb shell pm list packages | findstr /e "!appName!" > %temp%\sixense_packagelist.tmp
set /p myvar= < %temp%\sixense_packagelist.tmp
if "!myvar!" == "" (
	powershell write-host -back darkgray -fore white !appName! not found.
	echo.
	goto ending
)


::iterates through the the list of silver surver packages and removes the substring prefix "package:"
::and writes these results to a new file.
set packageCount=0
for /F "usebackq tokens=*" %%A in ("%temp%\sixense_packagelist.tmp") do (
	set "myVar=%%A"
	set myVarWithoutPackage=!myVar:package^:=!
	echo !myVarWithoutPackage! >> %temp%\sixense_packagelist_withoutpackageprefix.tmp
	set /A packageCount+=1
)


::stops app if it's already running
for /F "usebackq tokens=*" %%B in ("%temp%\sixense_packagelist_withoutpackageprefix.tmp") do (
	powershell write-host -back darkgray -fore white Stopping %%B:
	.\utils\adb shell am force-stop %%B
	echo Command sent.
	echo.
)


::runs app
::Note, the myCommand lines are needed to remove the trailing space in the package file name
for /F "usebackq tokens=*" %%B in ("%temp%\sixense_packagelist_withoutpackageprefix.tmp") do (
	powershell write-host -back darkgray -fore white Starting %%B:
	set "myCommand=%%B"
	set myCommand=!myCommand:~0,-1!
	.\utils\adb shell am start -n !myCommand!/com.sixense.unity3ddriver.Unity3dDriver
	echo Command sent.
	echo.
)


:ending
timeout 5
