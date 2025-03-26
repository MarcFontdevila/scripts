#!/bin/bash

# --- Configuration ---
ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"  # Replace with YOUR actual path

which "$ADB_PATH" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  osascript -e "display dialog \"Unable to find ADB command $ADB_PATH, please modify the ADB_PATH from current workflow\" buttons {\"OK\"} default button \"Android Tools\" with icon caution"
  exit 1
fi

# --- Define Folders ---
SCREENSHOT_DIR="$HOME/Screenshots"
VIDEO_DIR="$HOME/Videos"

# --- Create Folders if They Don't Exist ---
mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$VIDEO_DIR"

# --- Log File ---
LOG_FILE="$HOME/Desktop/android_tools.log"
exec > "$LOG_FILE" 2>&1  # Redirect all output to the log file
echo "--- Script started: $(date) ---"

# --- Function to display a list and get user choice ---
choose_from_list() {
  local prompt="$1"
  shift
  local options=("$@")
  local choice

  # Build the AppleScript list
  local apple_script_list='{'
  for i in "${!options[@]}"; do
    apple_script_list+='"'"${options[$i]}"'"'
    if [ "$i" -lt "$((${#options[@]} - 1))" ]; then
      apple_script_list+=','
    fi
  done
  apple_script_list+='}'

  # Execute the AppleScript to display the list
  choice=$(osascript -e "set choices to $apple_script_list" \
                       -e "choose from list choices with prompt \"$prompt\" OK button name \"Select\" cancel button name \"Cancel\"" 2>/dev/null)

  if [ "$choice" == "false" ]; then
    return 1 # User cancelled
  fi
  echo "$choice"
  return 0
}

# --- Get List of Connected Devices ---
connected_devices=$("$ADB_PATH" devices | awk 'NR>1 {print $1}' | grep -v 'device')

# --- Present Device List ---
if [ -n "$connected_devices" ]; then
  # Split the connected_devices string into an array
  IFS=$'\n' read -r -d '' -a device_array <<< "$connected_devices"
  # Remove empty elements from the array (if any)
  device_array=("${device_array[@]}")
  chosen_device=$(choose_from_list "Choose a connected device:" "${device_array[@]}")

  # Debugging: Print the raw output of choose_from_list
  echo "Raw chosen_device: [$chosen_device]"
  if [ -z "$chosen_device" ]; then
    echo "User cancelled device selection."
    exit 0
  fi

  # Debugging: Print the value of chosen_device
  echo "Chosen Device: [$chosen_device]"

    # Use the selected device
    DEVICE_SERIAL="$chosen_device"
    # Check if the device is connected via TCP/IP or USB
    if [[ "$DEVICE_SERIAL" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+$ ]]; then
      IP_ADDRESS=$(echo "$DEVICE_SERIAL" | awk -F: '{print $1}')
      PORT=$(echo "$DEVICE_SERIAL" | awk -F: '{print $2}')
      echo "Device connected via TCP/IP: IP=$IP_ADDRESS, Port=$PORT"
    else
      echo "Device connected via USB"
      IP_ADDRESS=""
      PORT=""
    fi

    # Debugging: Print the values of IP_ADDRESS, PORT, and DEVICE_SERIAL
    echo "IP_ADDRESS (Existing Device): [$IP_ADDRESS]"
    echo "PORT (Existing Device): [$PORT]"
    echo "DEVICE_SERIAL (Existing Device): [$DEVICE_SERIAL]"
else
  # --- Display Error Message ---
  osascript -e 'display dialog "No devices found. Please connect an Android device and try again." buttons {"OK"} default button "OK" with title "TNT - Android Tools" with icon caution'
  exit 1
fi

# --- Connect to the Device (if not already connected) ---
# Only attempt to connect if the device is not connected via USB
if [ -n "$IP_ADDRESS" ] && [ -n "$PORT" ]; then
  echo "Connecting to $IP_ADDRESS:$PORT..."
  "$ADB_PATH" connect "$IP_ADDRESS:$PORT"
  connect_result=$?
  if [ $connect_result -ne 0 ]; then
    echo "Failed to connect to $IP_ADDRESS:$PORT"
    osascript -e 'display dialog "Failed to connect to $IP_ADDRESS:$PORT. Check the IP address, port, and ensure adb is running on the device." buttons {"OK"} default button "OK" with title "TNT - Android Tools" with icon caution'
    exit 1
  fi
  echo "Successfully connected to $IP_ADDRESS:$PORT"
  osascript -e 'display dialog "Successfully connected to $IP_ADDRESS:$PORT" buttons {"OK"} default button "OK" with title "TNT - Android Tools" with icon note'
fi

# --- Check for adb ---
if [ ! -x "$ADB_PATH" ]; then
  osascript -e 'display dialog "Error: adb not found or not executable at '$ADB_PATH'. Please verify the path in the Automator action." buttons {"OK"} default button "OK" with title "TNT - Android Tools" with icon stop'
  exit 1
fi

# --- Present Options: Screenshot or Record ---
options=("Screenshot" "Record" "Exit")
choice=$(choose_from_list "Choose an action:" "${options[@]}")

case "$choice" in
  "Screenshot")
    echo "Taking screenshot..."
    screenshot_file="screenshot_$(date +%Y%m%d_%H%M%S).png"
    "$ADB_PATH" -s "$DEVICE_SERIAL" shell screencap -p /sdcard/"$screenshot_file"
    "$ADB_PATH" -s "$DEVICE_SERIAL" pull /sdcard/"$screenshot_file" "$SCREENSHOT_DIR"/"$screenshot_file"
    "$ADB_PATH" -s "$DEVICE_SERIAL" shell rm /sdcard/"$screenshot_file"
    echo "Screenshot saved to: $SCREENSHOT_DIR/$screenshot_file"
    open "$SCREENSHOT_DIR/$screenshot_file"
    ;;
  "Record")
    echo "Starting recording..."
    video_file="record_$(date +%Y%m%d_%H%M%S).mp4"
    "$ADB_PATH" -s "$DEVICE_SERIAL" shell screenrecord /sdcard/"$video_file" &
    RECORD_PID=$!
    sleep 5 # Increased initial sleep time

    record_options=("Stop Recording" "Cancel")
    record_choice=$(choose_from_list "Recording in progress. Choose an action:" "${record_options[@]}")

    case "$record_choice" in
      "Stop Recording")
        echo "Stopping recording..."

        # Wait for the video file to be created (up to 30 seconds)
        timeout=30
        while [ ! "$("$ADB_PATH" -s "$DEVICE_SERIAL" shell "test -f /sdcard/$video_file; echo \$?")" -eq "0" ] && [ $timeout -gt 0 ]; do
          echo "Waiting for video file to be created..."
          sleep 2
          timeout=$((timeout - 2))
        done

        if [ "$("$ADB_PATH" -s "$DEVICE_SERIAL" shell "test -f /sdcard/$video_file; echo \$?")" -eq "0" ]; then
          echo "Video file exists on the device. Proceeding with pull."
          "$ADB_PATH" -s "$DEVICE_SERIAL" pull /sdcard/"$video_file" "$VIDEO_DIR"/"$video_file"
          "$ADB_PATH" -s "$DEVICE_SERIAL" shell rm /sdcard/"$video_file"
          echo "Video saved to: $VIDEO_DIR/$video_file"
          open "$VIDEO_DIR" # Changed to open folder
        else
          echo "Error: Video file does not exist on the device after waiting! Recording may have failed."
          osascript -e 'display dialog "Error: Video recording failed on the device. Check device storage and permissions." buttons {"OK"} default button "OK" with title "TNT - Android Tools" with icon caution'
        fi
        ;;
      "Cancel")
        echo "Cancelling recording..."
        "$ADB_PATH" -s "$DEVICE_SERIAL" shell rm /sdcard/"$video_file"
        echo "Recording cancelled."
        ;;
    esac
    ;;
  "Exit")
    echo "Exiting."
    exit 0
    ;;
  *)
    echo "Invalid choice."
    exit 1
    ;;
esac

echo "Process complete."
