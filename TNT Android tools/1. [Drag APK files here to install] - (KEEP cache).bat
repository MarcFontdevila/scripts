@echo off
cls
echo.
setlocal enableDelayedExpansion
powershell write-host -back darkgray -fore white TNT - Android Tools

pushd %~dp0
:: pushd creates a temporary drive letter and maps it to a network path provided, then CD (change directory) to that drive.
:: This is necessary because batch files CANNOT use network paths, i.e. \\192.168.8.115\ etc
:: Basically this will allow files dragged from network locations to not fail.
:: Note that %~dp0 is just a reference to whatever path the batch file was launched from.


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
	powershell write-host -fore darkyellow Ensure the android device is in development mode with `'USB debugging`' enabled`,
	powershell write-host -fore darkyellow and then look in the android device and confirm the USB debugging message.)
if "!errorCode!"=="error: more than one device/emulator" (
	.\utils\adb devices
	powershell write-host -fore darkyellow If you are connected wirelessly`, disconnect the USB cable and press any key.
	echo.
	powershell write-host -fore darkyellow If you are connected wirelessly and no devices are attached by USB cable`,
	powershell write-host -fore darkyellow open tool `#12` and enter `'adb disconnect`'`.
	powershell write-host -fore darkyellow Then connect the android device by USB and try tool `#2 to connect wirelessly again.)
if "!errorCode!"=="error: no devices/emulators found" (
	powershell write-host -fore darkyellow Please ensure the android device is powered on and connected by USB or wireless ADB.)
echo.
pause
:tryAgain
.\utils\adb shell getprop a > "%temp%\getprop.tmp" 2>&1
if errorlevel 1 (goto connectionError) else (goto noError)
:noError
echo.



::Checks to see if at least 1 argument was passed.  If not, it asks the user to drag and drop a file.
::"%~1" is the path of the first dragged-and-dropped item, if present.
if "%~1" == "" (powershell write-host -back darkgray -fore white Please drag an APK file onto this program to install it to your device.)


:: determine number of arguments
set argCount=0
for %%x in (%*) do (
   set /A argCount+=1
)


::Reports number of arguments detected:
if !argCount! EQU 1 (powershell write-host -back darkgray -fore white Installing !argCount! file:)
if !argCount! GTR 1 (powershell write-host -back darkgray -fore white Installing !argCount! files:)
echo.


:: installs build for each argument
set packageCount=1
for /L %%a IN (1,1,!argCount!) do (
	call powershell write-host -back darkgray -fore white !packageCount! of !argCount!:
	call echo %%1
	call .\utils\adb install -r %%1
	echo.
	set /A packageCount+=1
	shift
)




:: removes temporary drive letter
popd



echo Press any key to exit.
pause > nul