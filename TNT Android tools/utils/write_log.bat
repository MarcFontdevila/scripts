@echo off
cls
mode con: cols=52 lines=8
setlocal enableDelayedExpansion


::initializes adb if it's not initialized
::echo Initializing ADB (Android Debug Bridge) server...
::.\utils\adb shell getprop a


::record current date and time:
set mydate=%date:~10,4%-%date:~4,2%-%date:~7,2%
set mytime=%time:~0,2%.%time:~3,2%.%time:~6,2%
set mytimeWithColon=%time:~0,2%:%time:~3,2%.%time:~6,2%

::get device name
for /f "tokens=*" %%g in ('.\utils\adb shell getprop ro.product.manufacturer') do (set manufacturerName=%%g)
for /f "tokens=*" %%g in ('.\utils\adb shell getprop ro.product.model') do (set productName=%%g)


::UI message
echo.
powershell write-host -back darkgreen -fore white Now writing log file to desktop:
powershell write-host -fore yellow !manufacturerName! !productName! !mydate! !mytime!.log
echo.
echo WHEN FINISHED:
powershell write-host -NoNewline 'press ' 
powershell write-host -NoNewline -back blue -fore white ' CTRL-C '
powershell write-host -NoNewline ', then press '
powershell write-host -NoNewline -back blue -fore white ' n '
powershell write-host -NoNewline ', then press '
powershell write-host -NoNewline -back blue -fore white ' enter '
echo :

:: write boilerplate to disk:
echo Sixense Android VR Tools - device log > "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
echo !manufacturerName! !productName! >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
echo PC time: !mydate! !mytimeWithColon! >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
ver >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
echo. >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"

::write the preplog to disk
type "%temp%\vrdevice_preplog.tmp" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"

::write the actual log to disk
cmd /c ".\utils\%~1 >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log""








:::::::::::::AFTER THE USER PRESSES CTRL-C:
cls
echo Writing storage status to log...

::storage status boilerplate
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo ----------- POST-LOG STORAGE STATUS -----------" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
::write filesystem info
cmd /c "echo Internal Storage:" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c ".\utils\adb shell df -h /sdcard" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log""
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log""
cmd /c "echo External Storage:" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c ".\utils\adb shell df -h /sdcard2" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log""

::internal filetree contents boilerplate
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo ----------- POST-LOG FILE TREE PART 1: INTERNAL STORAGE -----------" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo Issuing command:" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo adb shell ls -Rhl --color /sdcard/Android/data/!appStoragePath!" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
::write internal filetree contents
cmd /c ".\utils\adb shell ls -Rhl --color /sdcard/Android/data/%~2 >nul 2>&1 >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log""

::sd card filetree contents boilerplate
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo ----------- POST-LOG FILE TREE PART 2: EXTERNAL STORAGE  -----------" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo Issuing command:" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo adb shell ls -Rhl --color /sdcard2/Android/data/%~2" >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"
::write sdcard filetree contents
cmd /c ".\utils\adb shell ls -Rhl --color /sdcard2/Android/data/%~2 >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"" >nul 2>&1 
cmd /c "echo." >> "!USERPROFILE!\Desktop\!manufacturerName! !productName! !mydate! !mytime!.log"


cls
echo Writing storage status to log... done.

echo Log file saved to desktop:
powershell write-host -fore yellow !manufacturerName! !productName! !mydate! !mytime!.log
echo.
powershell write-host -fore green Log complete. Close this window to exit.
echo.
::pause >nul 2>&1

