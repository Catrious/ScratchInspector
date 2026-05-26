#!/bin/bash
# Get the directory where the script is located
DIR="$(dirname "$0")"

# Execute the AppleScript located in the Resources folder
osascript "$DIR/../Resources/main.applescript"
