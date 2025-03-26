@echo off
cls
setlocal enableDelayedExpansion
echo.
::powershell write-host -back darkgray -fore white TNT - Android Tools

::record current date and time:
set mydate=%date:~10,4%-%date:~4,2%-%date:~7,2%
set mytime=%time:~0,2%.%time:~3,2%.%time:~6,2%




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



::get device name
for /f "tokens=*" %%g in ('.\utils\adb shell getprop ro.product.manufacturer') do (set manufacturerName=%%g)
for /f "tokens=*" %%g in ('.\utils\adb shell getprop ro.product.model') do (set productName=%%g)

:: create destination folder (if it does not exist)
md "!USERPROFILE!\Desktop\VR_capture\" >nul 2>&1

::obtain device resolution
for /f "tokens=3" %%A in ('.\utils\adb shell wm size') do echo %%A > %temp%\sr_headsetRes.tmp
for /f "tokens=1 delims=x" %%B in (%temp%\sr_headsetRes.tmp) do set "xRes=%%B"
for /f "tokens=2 delims=x" %%C in (%temp%\sr_headsetRes.tmp) do set "yRes=%%C"

::used for stereoscopic full
set /a xRes = !xRes!
set /a yRes = !yRes!

::used for x-resolution in monoscopic full (y resolution is unchanged in mono full)
set /a xResHalf = (!xRes! / 2)

::used for resolution and offset in monoscopic zoom
set /a xResZoom = (!xRes! / 2) - (!xRes! / 11)
set /a yResZoom = (!yRes! / 2) - (!yRes! / 12)
set /a xResZoomOffset = (!xRes! / 16) + (!xRes! / 24)
set /a yResZoomOffset = (!yRes! / 4) + (!yRes! / 24)


::used for resolution and offset in monoscopic zoom (match original)
set /a xResZoom = (!xRes! / 2) - (!xRes! / 12)
set /a yResZoom = (!yRes! / 2)
set /a xResZoomOffset = (!xRes! / 16)
set /a yResZoomOffset = (!yRes! / 4) - (!yRes! / 40)



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
echo.
powershell write-host -back darkred -fore white Now recording phone video.  Please do NOT close this window.
powershell write-host -back darkred -fore white To stop recording`, close the video window instead.
echo.
:: Note: '--max-size' limits both the width and height to that value. The other dimension is then computed so that the device aspect ratio is preserved.--max-size 1600 --bit-rate 15M
.\utils\scrcpy\scrcpy --record "!USERPROFILE!\Desktop\VR_capture\!manufacturerName! !productName! !mydate! !mytime!.mp4" > nul
%SystemRoot%\explorer.exe "!USERPROFILE!\Desktop\VR_capture\"
goto EOF



:TWO
::Monoscopic:
echo.
powershell write-host -back darkred -fore white Now recording phone video.  Please do NOT close this window.
powershell write-host -back darkred -fore white To stop recording`, close the video window instead.
echo.
.\utils\scrcpy\scrcpy --max-size 1200 --crop !xResHalf!:!yRes!:0:0 --bit-rate 15M --record "!USERPROFILE!\Desktop\VR_capture\!manufacturerName! !productName! !mydate! !mytime!.mp4" > nul
%SystemRoot%\explorer.exe "!USERPROFILE!\Desktop\VR_capture\"
goto EOF




:THREE
::Monoscopic (zoomed):
cls
powershell write-host -back red -fore white Now recording. **Please do not close this window**
powershell write-host -back darkgray -fore white To stop recording`, close the video window instead.
echo If you close this window first, the video will not save.
echo.
::.\utils\scrcpy\scrcpy --max-size 1200 --crop 1200:800:180:360 --bit-rate 15M > nul
.\utils\scrcpy\scrcpy --max-size 1200 --crop !xResZoom!:!yResZoom!:!xResZoomOffset!:!yResZoomOffset! --bit-rate 15M --record "!USERPROFILE!\Desktop\VR_capture\!manufacturerName! !productName! !mydate! !mytime!.mp4" > nul
%SystemRoot%\explorer.exe "!USERPROFILE!\Desktop\VR_capture\"
goto EOF

