#!/bin/bash
export PATH="/Users/marc.fontdevila/downloads/platform-tools:$PATH"
# Take the screenshot

adb shell screencap -p /sdcard/Pictures/tv_screenshot.png

# Check if the command was successful
if [ $? -ne 0 ]; then
  echo "Error taking screenshot.  Check permissions and storage path."
  exit 1
fi

# Pull the screenshot to the current directory

adb pull /sdcard/Pictures/tv_screenshot.png ~/Downloads/screenshots/tv_screenshot.png

# Check if the pull command was successful
if [ $? -ne 0 ]; then
  echo "Error pulling screenshot.  Check the path on the TV."
  exit 1
fi

echo "Screenshot saved as tv_screenshot.png in the current directory."

# Open Finder to the specified directory
open ~/downloads/screenshots/tv_screenshot.png