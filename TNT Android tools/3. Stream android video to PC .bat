@echo off
cls
setlocal enableDelayedExpansion
echo.
::powershell write-host -back darkgray -fore white  TNT - Android Tools


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
mode con: cols=68 lines=9
echo.




::obtain device resolution
for /f "tokens=3" %%A in ('.\utils\adb shell wm size') do echo %%A > %temp%\sr_headsetRes.tmp
for /f "tokens=1 delims=x" %%B in (%temp%\sr_headsetRes.tmp) do set "xRes=%%B"
for /f "tokens=2 delims=x" %%C in (%temp%\sr_headsetRes.tmp) do set "yRes=%%C"

::used for 1 - stereoscopic full
set /a xRes = !xRes!
set /a yRes = !yRes!

::used for x-resolution in 2 - monoscopic full (y resolution is unchanged in mono full)
set /a xResHalf = (!xRes! / 2)



::used for resolution and offset in 3 - monoscopic zoom (match original)
set /a xResZoom = (!xRes! / 2) - (!xRes! / 12)
set /a yResZoom = (!yRes! / 2)
set /a xResZoomOffset = (!xRes! / 16)
set /a yResZoomOffset = (!yRes! / 4) - (!yRes! / 40)



::debug output of values.  Hidden unless there's a need to alter the values.
::echo xRes = !xRes!
::echo yRes = !yRes!
::echo.
::echo xResZoom = !xResZoom!
::echo yResZoom = !yResZoom!
::echo xResZoomOffset = !xResZoomOffset!
::echo yResZoomOffset = !yResZoomOffset!



:: Menu for different options.  I'm commenting this out in tools 2.03 since we don't use anything but option 3 really.
::powershell write-host -back darkblue -fore white Please select output format:
echo 1: Stereoscopic (full)
echo 2: Monoscopic (full)
echo 3: Monoscopic (zoomed)
echo.
CHOICE /N /C:123 /M "Enter choice: "%1
CLS
IF ERRORLEVEL ==3 GOTO THREE
IF ERRORLEVEL ==2 GOTO TWO
IF ERRORLEVEL ==1 GOTO ONE
goto EOF
GOTO THREE








:ONE
::Stereoscopic (full image):
powershell write-host -back darkgreen -fore white Now streaming Stereoscopic [full] headset video to PC`.
echo Note: Frame-rate will appear better over USB than wifi connection.
echo.
:: Note: '--max-size' limits both the width and height to that value. The other dimension is then computed so that the device aspect ratio is preserved.old --max-size 1600 --bit-rate 15M > nul
.\utils\scrcpy\scrcpy 
goto EOF



:TWO
::Monoscopic:
powershell write-host -back darkgreen -fore white Now streaming Monoscopic [full] headset video to PC`.
echo Note: Frame-rate will appear better over USB than wifi connection.
echo.
.\utils\scrcpy\scrcpy --max-size 1200 --crop !xResHalf!:!yRes!:0:0 --bit-rate 15M > nul
goto EOF




:THREE
::Monoscopic (zoomed):
powershell write-host -back darkgreen -fore white Now streaming mobile video to PC`.
echo Note: Frame-rate will appear better over USB than wifi connection.
echo.
::.\utils\scrcpy\scrcpy --max-size 1200 --crop 1200:800:180:360 --bit-rate 15M > nul
.\utils\scrcpy\scrcpy --max-size 1200 --crop !xResZoom!:!yResZoom!:!xResZoomOffset!:!yResZoomOffset! --bit-rate 15M > nul
goto EOF







:noHMD
mode con: cols=84 lines=11
echo.
powershell write-host -back darkgray -fore TNT - Android Tools
echo.
powershell write-host -back red -fore white Error: zero [or multiple] devices/emulators found.
echo This batch only works with a single device connected by ADB.
echo.
echo Note: Connecting to ADB wirelessly can cause the system to see multiple devices.
echo In that case, restart the headset and try again.
echo.
powershell write-host -back black -fore green This message also appears if the HMD has not authorized this PC for USB debugging.
echo.
echo Press any key to exit.
pause > nul