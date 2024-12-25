#!/bin/bash

# Input variables
DIRECTION=$1 # "up" to increase brightness, "down" to decrease brightness
INCREMENT=0.15 # Brightness adjustment step
MIN_BRIGHTNESS=0.15 # Minimum brightness allowed
MAX_BRIGHTNESS=1.15 # Maximum brightness allowed
MONITORS=("eDP-1" "eDP-2") # List of monitors to adjust brightness for

# Function to calculate the new brightness
calculate_new_brightness() {
    CURRENT_BRIGHTNESS=$1

    # Adjust brightness based on direction
    if [[ $DIRECTION == "up" ]]; then
        NEW_BRIGHTNESS=$(echo "$CURRENT_BRIGHTNESS + $INCREMENT" | bc)
    elif [[ $DIRECTION == "down" ]]; then
        NEW_BRIGHTNESS=$(echo "$CURRENT_BRIGHTNESS - $INCREMENT" | bc)
    else
        echo "Invalid direction: use 'up' or 'down'"
        exit 1
    fi

    # Clamp the brightness within the allowed range
    if (( $(echo "$NEW_BRIGHTNESS < $MIN_BRIGHTNESS" | bc -l) )); then
        NEW_BRIGHTNESS=$MIN_BRIGHTNESS
    elif (( $(echo "$NEW_BRIGHTNESS > $MAX_BRIGHTNESS" | bc -l) )); then
        NEW_BRIGHTNESS=$MAX_BRIGHTNESS
    fi

    echo $NEW_BRIGHTNESS
}

# Get the current brightness of the primary monitor (eDP-1)
PRIMARY_MONITOR="eDP-1"
CURRENT_BRIGHTNESS=$(DISPLAY=:0 xrandr --verbose | grep -A 5 "^$PRIMARY_MONITOR" | grep "Brightness" | awk '{print $2}')
if [[ -z $CURRENT_BRIGHTNESS ]]; then
    echo "Failed to get brightness for $PRIMARY_MONITOR"
    exit 1
fi

# Calculate the new brightness
NEW_BRIGHTNESS=$(calculate_new_brightness $CURRENT_BRIGHTNESS)

# Adjust brightness for each monitor in the list
for MONITOR in "${MONITORS[@]}"; do
    DISPLAY=:0 xrandr --output $MONITOR --brightness $NEW_BRIGHTNESS 2>/dev/null || echo "Monitor $MONITOR not connected"
done

echo "Brightness adjusted to $NEW_BRIGHTNESS for available monitors"
