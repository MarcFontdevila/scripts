@echo off
cls
echo.
setlocal enableDelayedExpansion  
powershell write-host -back darkgray -fore white TR Reloaded - Android Tools

:: This batch will uninstall any app on the android device with this substring in its app name:
set "appName=SilverSurfer"


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



::deletes these files if they were left behind on a previous run where the user closed the window
del "%temp%\silversurfer_packagelist.tmp" >nul 2>&1
del "%temp%\silversurfer_packagelist_withoutpackageprefix.tmp" >nul 2>&1



::skip to the end if no silver surfer packages are installed
.\utils\adb shell pm list packages | find "!appName!" > %temp%\silversurfer_packagelist.tmp
set /p myvar= < %temp%\silversurfer_packagelist.tmp
if "!myvar!" == "" (
	powershell write-host -back darkgray -fore white !appName! packages not found.
	goto ending
)



::iterates through the the list of silver surver packages and removes the substring prefix "package:"
::and writes these results to a new file.
set packageCount=0
for /F "usebackq tokens=*" %%A in ("%temp%\silversurfer_packagelist.tmp") do (
	set "myVar=%%A"
	set myVarWithoutPackage=!myVar:package^:=!
	echo !myVarWithoutPackage! >> %temp%\silversurfer_packagelist_withoutpackageprefix.tmp
	set /A packageCount+=1
)



::shows the user the list of files to be deleted and prompts for confirmation
powershell write-host -back darkgray -fore white The following packages will be uninstalled, and their app caches will be cleared:
echo.
type %temp%\silversurfer_packagelist_withoutpackageprefix.tmp
echo.
echo Press any key to continue, or close this window to cancel.
pause > nul
echo.



::iterates through the new package list and uninstalls them one by one:
if !packageCount! EQU 1 (powershell write-host -back darkgray -fore white Uninstalling !packageCount! package:)
if !packageCount! GTR 1 (powershell write-host -back darkgray -fore white Uninstalling !packageCount! packages:)

for /F "usebackq tokens=*" %%B in ("%temp%\silversurfer_packagelist_withoutpackageprefix.tmp") do (
	.\utils\adb uninstall %%B
)




del "%temp%\silversurfer_packagelist.tmp" >nul 2>&1
del "%temp%\silversurfer_packagelist_withoutpackageprefix.tmp" >nul 2>&1

:ending
echo.
timeout 5