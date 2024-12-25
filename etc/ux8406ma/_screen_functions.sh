#!/bin/bash

# Check if eDP-2 is powered on using xrandr --listmonitors
is_edp2_on() {
    xrandr --listmonitors | grep -q "eDP-2"
}

# Get the current orientation of a screen
get_orientation() {
    local screen=$1
    local current_orientation
    current_orientation=$(DISPLAY=:0 xrandr | grep "$screen connected" | grep -o "normal\|inverted\|left\|right" | head -n 1)
    
    if [[ -z "$current_orientation" ]]; then
        echo "Error: Unable to get orientation for screen $screen"
        exit 1
    fi
    
    echo "$current_orientation"
}

# Get the current brightness of a screen
get_current_brightness() {
    local screen=$1
    local current_brightness
    current_brightness=$(xrandr --verbose | grep -A 5 "^$screen" | grep "Brightness" | awk '{print $2}')
    
    if [[ -z "$current_brightness" ]]; then
        /etc/ux8406ma/log-manager.sh "Error getting brightness for $screen"
        exit 1
    fi
    
    echo "$current_brightness"
}

# Function to wait until eDP-2 is on or off
wait_for_edp2_status() {
    local status=$1  # "on" or "off"
    
    if [[ "$status" == "on" ]]; then
        while ! is_edp2_on; do
            sleep 0.1  # Small delay to avoid continuous checking
        done
    elif [[ "$status" == "off" ]]; then
        while is_edp2_on; do
            sleep 0.1  # Small delay to reduce CPU usage
        done
    else
        echo "Invalid status parameter. Use 'on' or 'off'."
        exit 1
    fi
}

# Function to wait until the orientation has been applied
wait_for_screen_orientation() {
    local screen=$1
    local expected_orientation=$2
    local current_orientation

    while true; do
        current_orientation=$(get_orientation "$screen")
        
        if [[ "$current_orientation" == "$expected_orientation" ]]; then
            break
        fi

        sleep 0.1  # Small delay before checking again
    done
}


restore_brightness() {
    local screen=$1
    local current_brightness=$2
    local action=$3  # "status" or "orientation"
    local status_or_screen=$4   # The status or the screen (status "on"/"off" or screen name)
    local expected_orientation=$5  # Expected orientation if action is "orientation"
    
    if [[ "$action" == "status" ]]; then
        # Wait for the desired status (connection or disconnection)
        wait_for_edp2_status "$status_or_screen"
    elif [[ "$action" == "orientation" ]]; then
        # Wait for the orientation to be applied to the screen
        wait_for_screen_orientation "$status_or_screen" "$expected_orientation"
    else
        echo "Invalid action parameter. Use 'status' or 'orientation'."
        exit 1
    fi
    
    # Restore brightness
    DISPLAY=:0 xrandr --output "$screen" --brightness "$current_brightness"
}
