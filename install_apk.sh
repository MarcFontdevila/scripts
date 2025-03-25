#!/bin/bash

# --- Configuration ---

# Set the absolute path to adb.
ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"  # Replace with YOUR actual path

which "$ADB_PATH" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  osascript -e "display dialog \"Unable to find ADB command $ADB_PATH, please modify the ADB_PATH from current workflow\" buttons {\"OK\"} default button \"OK\" with title \"TNT - Android Tools\" with icon caution"
  exit 1
fi

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
# Get the output of adb devices, skipping the first line
# Use a temporary file to avoid quoting issues
temp_file=$(mktemp)
if [ -z "$temp_file" ]; then
  echo "Error: Failed to create temporary file."
  exit 1
fi

"$ADB_PATH" devices > "$temp_file"
if [ $? -ne 0 ]; then
  echo "Error: Failed to write adb devices output to temporary file."
  rm -f "$temp_file"  # Clean up the temporary file
  exit 1
fi

adb_output=$(cat "$temp_file")
rm "$temp_file"

# Extract device serials, handling potential whitespace and empty lines
connected_devices=$(echo "$adb_output" | tail -n +2 | awk '{print $1}' | grep -v '^$' | grep -v '\*')

# Debugging output:
echo "Connected Devices (raw adb output): [$adb_output]"
echo "Connected Devices (after processing): [$connected_devices]"

# --- Present Device List or New IP Option ---
if [ -n "$connected_devices" ]; then
  # Split the connected_devices string into an array
  IFS=$'\n' read -r -d '' -a device_array <<< "$connected_devices"

  # Remove empty elements from the array (if any)
  device_array=("${device_array[@]}")

  # Add "Enter New IP" as an option
  device_array+=("Enter New IP")

  chosen_device=$(choose_from_list "Choose a connected device or enter a new IP:" "${device_array[@]}")

  # Debugging: Print the value of chosen_device
  echo "Chosen Device: [$chosen_device]"

  if [ -z "$chosen_device" ]; then
    echo "User cancelled device selection."
    exit 0
  fi

  if [ "$chosen_device" == "Enter New IP" ]; then
    # --- Prompt for IP Address and Port ---
    IP_ADDRESS=$(osascript -e 'display dialog "Enter the IP address of the Android device:" default answer "10.12.52." buttons {"Cancel", "OK"} default button "OK"' -e 'text returned of result' 2>/dev/null)

    if [ -z "$IP_ADDRESS" ]; then
      echo "User cancelled IP address input."
      exit 0
    fi

    PORT=$(osascript -e 'display dialog "Enter the port number (usually 5555):" default answer "5555" buttons {"Cancel", "OK"} default button "OK"' -e 'text returned of result' 2>/dev/null)

    if [ -z "$PORT" ]; then
      echo "User cancelled port input."
      exit 0
    fi

    DEVICE_SERIAL="$IP_ADDRESS:$PORT"

  else
    # Use the selected device
    DEVICE_SERIAL="$chosen_device"
    IP_ADDRESS=$(echo "$DEVICE_SERIAL" | awk -F: '{print $1}')
    PORT=$(echo "$DEVICE_SERIAL" | awk -F: '{print $2}')
  fi

  # Debugging: Print the value of DEVICE_SERIAL
  echo "Device Serial: [$DEVICE_SERIAL]"

else
  # --- Prompt for IP Address and Port ---
  IP_ADDRESS=$(osascript -e 'display dialog "No devices found. Enter the IP address of the Android device:" default answer "10.12.52." buttons {"Cancel", "OK"} default button "OK"' -e 'text returned of result' 2>/dev/null)

  if [ -z "$IP_ADDRESS" ]; then
    echo "User cancelled IP address input."
    exit 0
  fi

  PORT=$(osascript -e 'display dialog "Enter the port number (usually 5555):" default answer "5555" buttons {"Cancel", "OK"} default button "OK"' -e 'text returned of result' 2>/dev/null)

  if [ -z "$PORT" ]; then
    echo "User cancelled port input."
    exit 0
  fi

  DEVICE_SERIAL="$IP_ADDRESS:$PORT"
fi

# --- Connect to the Device (if not already connected) ---
if [[ "$chosen_device" == "Enter New IP" || -z "$connected_devices" ]]; then
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

# --- Install APKs ---
# Debugging: Print the value of DEVICE_SERIAL before installation
echo "Device Serial (before install loop): [$DEVICE_SERIAL]"

# Check if DEVICE_SERIAL is empty
if [ -z "$DEVICE_SERIAL" ]; then
  echo "Error: DEVICE_SERIAL is empty!  Cannot proceed with installation."
  osascript -e 'display dialog "Error: No device selected or DEVICE_SERIAL is empty.  Cannot proceed with installation." buttons {"OK"} default button "OK" with title "TNT - Android Tools" with icon caution'
  exit 1
fi

for apk_file in "$@"; do
  echo "Installing: $apk_file"

  # Debugging: Print the full adb install command
  echo "ADB Install Command: [\"$ADB_PATH\" -s \"$DEVICE_SERIAL\" install -r \"$apk_file\"]"

  "$ADB_PATH" -s "$DEVICE_SERIAL" install -r "$apk_file"
  install_result=$?

  # Debugging: Print the install_result
  echo "Install Result: [$install_result]"

  if [ $install_result -ne 0 ]; then
    echo "Installation failed for $apk_file"
    osascript -e 'display dialog "Installation failed for: $apk_file.  See Terminal for details." buttons {"OK"} default button "OK" with title "TNT - Android Tools" with icon caution'
  else
    echo "Installation successful for: $apk_file"
    osascript -e "display dialog \"Installation successful for: $apk_file on device $IP_ADDRESS:$PORT\" buttons {\"OK\"} default button \"OK\" with title \"TNT - Android Tools\" with icon note"
  fi

  # Debugging: Check for the existence of the apk_file
  if [ ! -f "$apk_file" ]; then
    echo "Error: APK file not found: $apk_file"
  fi
done

echo "Installation process complete."
