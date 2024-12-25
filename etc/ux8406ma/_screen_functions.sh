#!/bin/bash

TOUCH1="ELAN9008:00 04F3:4259"
TOUCH2="ELAN9009:00 04F3:42EC"
SCREEN1="eDP-1"
SCREEN2="eDP-2"
SCREEN_NONE="none"

# Matrices de transformación para el área táctil
MATRIX_FULL_SCREEN="1 0 0 0 1 0 0 0 1" # OK

MATRIX_NORMAL_TOP_HALF="1 0 0 0 0.5 0 0 0 1" # OK
MATRIX_NORMAL_BOTTOM_HALF="1 0 0 0 0.5 0.5 0 0 1" # OK

MATRIX_INVERTED_TOP_HALF="-1 0 1 0 -0.5 0.5 0 0 1" # OK
MATRIX_INVERTED_BOTTOM_HALF="-1 0 1 0 -0.5 1 0 0 1" # OK

MATRIX_LEFT_LEFT_HALF="0 -0.5 0.5 1 0 0 0 0 1" # OK
MATRIX_LEFT_RIGHT_HALF="0 -0.5 1 1 0 0 0 0 1" # OK

MATRIX_RIGHT_LEFT_HALF="0 0.5 0 -1 0 1 0 0 1" # OK 
MATRIX_RIGHT_RIGHT_HALF="0 0.5 0.5 -1 0 1 0 0 1" # OK

# Check if eDP-2 is powered on using xrandr --listmonitors
is_edp2_on() {
    DISPLAY=:0 xrandr --listmonitors | grep -q "eDP-2"
}

# Get the current orientation of a screen
get_orientation() {
    local screen=$1
    local current_orientation
    current_orientation=$(DISPLAY=:0 xrandr | grep "$screen connected" | grep -o "normal\|inverted\|left\|right" | head -n 1)
    
    if [[ -z "$current_orientation" ]]; then
        /etc/ux8406ma/log-manager.sh "ERROR: Unable to get orientation for screen $screen"
        exit 1
    fi
    
    echo "$current_orientation"
}

# Get the current brightness of a screen
get_current_brightness() {
    local screen=$1
    local current_brightness
    current_brightness=$(DISPLAY=:0 xrandr --verbose | grep -A 5 "^$screen" | grep "Brightness" | awk '{print $2}')
    
    if [[ -z "$current_brightness" ]]; then
        /etc/ux8406ma/log-manager.sh "ERROR: Error getting brightness for $screen"
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
        /etc/ux8406ma/log-manager.sh "ERROR: Invalid status parameter. Use 'on' or 'off'."
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
    
    # Wait for the desired status or rotation
    if [[ "$action" == "status" ]]; then
        wait_for_edp2_status "$status_or_screen"
    elif [[ "$action" == "orientation" ]]; then
        wait_for_screen_orientation "$status_or_screen" "$expected_orientation"
    else
        /etc/ux8406ma/log-manager.sh "ERROR: Invalid action parameter. Use 'status' or 'orientation'."
        exit 1
    fi

    # Restore brightness
    DISPLAY=:0 xrandr --output "$screen" --brightness "$current_brightness"
    
    # Log the first brightness restoration attempt
    /etc/ux8406ma/log-manager.sh "Attempting to restore brightness $current_brightness"

    while true; do
        actual_brightness=$(get_current_brightness "$screen")
        
        if [[ "$actual_brightness" != "$current_brightness" ]]; then
            /etc/ux8406ma/log-manager.sh "Brightness mismatch: actual ($actual_brightness) does not match expected ($current_brightness). Retrying..."
            DISPLAY=:0 xrandr --output "$screen" --brightness "$current_brightness"  # Retry restoring brightness
        else
            break  # Exit the loop once the brightness matches
        fi
        sleep 0.5  # Small delay before checking again
    done

    /etc/ux8406ma/log-manager.sh "Successfully restored brightness to $current_brightness"
}

convert_orientation() {
    local orientation=$1
    case $orientation in
        "bottom-up")
            echo "inverted"
            ;;
        "left-up")
            echo "left"
            ;;
        "right-up")
            echo "right"
            ;;
        *)
            echo "$orientation"
            ;;
    esac
}

touch_transform() {
  local touch=$1
  local screen=$2
  local matrix=$3

  DISPLAY=:0 xinput map-to-output "$touch" $screen

  if [ -n "$matrix" ]; then
    DISPLAY=:0 xinput set-prop "$touch" "Coordinate Transformation Matrix" $matrix
  fi

  /etc/ux8406ma/log-manager.sh "Applying matrix touch to screen $screen"
}
