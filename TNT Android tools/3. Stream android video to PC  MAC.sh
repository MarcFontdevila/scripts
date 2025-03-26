#!/bin/zsh

# Clear the terminal
clear

# Initialize ADB (Android Debug Bridge)
echo "Initializing ADB (Android Debug Bridge) server..."
adb shell getprop a > /tmp/getprop.tmp 2>&1
if [[ \$? -ne 0 ]]; then
    connectionError=\$(head -n 1 /tmp/getprop.tmp)
    echo
    echo "Error: \$connectionError"
    if [[ "\$connectionError" == *"daemon not running"* ]]; then
        echo "Trying again..."
        adb start-server
        adb shell getprop a > /tmp/getprop.tmp 2>&1
        if [[ \$? -ne 0 ]]; then
            echo "Failed to connect to ADB. Exiting."
            exit 1
        fi
    elif [[ "\$connectionError" == *"device unauthorized"* ]]; then
        echo "Ensure the headset is in development mode with 'USB debugging' enabled."
        echo "Look in the headset and confirm the USB debugging message."
        exit 1
    elif [[ "\$connectionError" == *"more than one device/emulator"* ]]; then
        adb devices
        echo "If you are connected wirelessly, disconnect the USB cable and try again."
        exit 1
    elif [[ "\$connectionError" == *"no devices/emulators found"* ]]; then
        echo "Please ensure the headset is powered on and connected by USB or wireless ADB."
        exit 1
    else
        echo "Unknown error: \$connectionError"
        exit 1
    fi
fi

# Obtain device resolution
resolution=\$(adb shell wm size | awk '{print \$NF}')
xRes=\$(echo \$resolution | cut -d'x' -f1)
yRes=\$(echo \$resolution | cut -d'x' -f2)

# Calculate resolutions for different modes
xResHalf=\$((xRes / 2))
xResZoom=\$((xRes / 2 - xRes / 12))
yResZoom=\$((yRes / 2))
xResZoomOffset=\$((xRes / 16))
yResZoomOffset=\$((yRes / 4 - yRes / 40))

# Debug output (uncomment for debugging)
# echo "xRes = \$xRes"
# echo "yRes = \$yRes"
# echo "xResZoom = \$xResZoom"
# echo "yResZoom = \$yResZoom"
# echo "xResZoomOffset = \$xResZoomOffset"
# echo "yResZoomOffset = \$yResZoomOffset"

# Menu for different options
echo "Please select output format:"
echo "1: Stereoscopic (full)"
echo "2: Monoscopic (full)"
echo "3: Monoscopic (zoomed)"
echo
read "choice?Enter choice: "

case \$choice in
    1)
        # Stereoscopic (full image)
        echo "Now streaming Stereoscopic [full] headset video to PC."
        echo "Note: Frame-rate will appear better over USB than WiFi connection."
        scrcpy
        ;;
    2)
        # Monoscopic (full)
        echo "Now streaming Monoscopic [full] headset video to PC."
        echo "Note: Frame-rate will appear better over USB than WiFi connection."
        scrcpy --max-size 1200 --crop \${xResHalf}:\${yRes}:0:0 --bit-rate 15M
        ;;
    3)
        # Monoscopic (zoomed)
        echo "Now streaming Monoscopic [zoomed] headset video to PC."
        echo "Note: Frame-rate will appear better over USB than WiFi connection."
        scrcpy --max-size 1200 --crop \${xResZoom}:\${yResZoom}:\${xResZoomOffset}:\${yResZoomOffset} --bit-rate 15M
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
