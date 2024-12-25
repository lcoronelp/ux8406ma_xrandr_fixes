#!/bin/bash

source /etc/ux8406ma/_screen_functions.sh

# Handle screen orientation changes
handle_orientation() {
    local orientation=$1
    local current_orientation
    local edp1_current_brightness

    if ! is_edp2_on; then
        systemctl stop ux8406ma-screen-rotation-monitor.service
        /etc/ux8406ma/log-manager.sh "No rotation applied: eDP-2 is off"
        exit 0
    fi

    current_orientation=$(get_orientation "eDP-1")
    edp1_current_brightness=$(get_current_brightness "eDP-1")

    if [[ $current_orientation == "$orientation" ]]; then
        /etc/ux8406ma/log-manager.sh "No rotation applied: eDP-1 is already $orientation"
        return
    fi

    case $orientation in
        "normal")
            DISPLAY=:0 xrandr --output eDP-1 --rotate normal --output eDP-2 --rotate normal --below eDP-1 &>/dev/null
            touch_transform "$TOUCH1" "$SCREEN1" "$MATRIX_TOP_HALF"
            touch_transform "$TOUCH2" "$SCREEN2" "$MATRIX_BOTTOM_HALF"
            /etc/ux8406ma/log-manager.sh "Rotated to normal position"
            ;;
        "inverted")
            DISPLAY=:0 xrandr --output eDP-1 --rotate inverted --output eDP-2 --rotate inverted --above eDP-1 &>/dev/null
            touch_transform "$TOUCH1" "$SCREEN1" "$MATRIX_INVERTED_BOTTOM_HALF"
            touch_transform "$TOUCH2" "$SCREEN2" "$MATRIX_INVERTED_TOP_HALF"
            /etc/ux8406ma/log-manager.sh "Rotated to inverted position"
            ;;
        "left")
            DISPLAY=:0 xrandr --output eDP-1 --rotate left --output eDP-2 --rotate left --left-of eDP-1 &>/dev/null
            touch_transform "$TOUCH1" "$SCREEN1" "$MATRIX_LEFT_HALF"
            touch_transform "$TOUCH2" "$SCREEN2" "$MATRIX_RIGHT_HALF"
            /etc/ux8406ma/log-manager.sh "Rotated to left position"
            ;;
        "right")
            DISPLAY=:0 xrandr --output eDP-1 --rotate right --output eDP-2 --rotate right --right-of eDP-1 &>/dev/null
            touch_transform "$TOUCH1" "$SCREEN1" "$MATRIX_RIGHT_HALF"
            touch_transform "$TOUCH2" "$SCREEN2" "$MATRIX_LEFT_HALF"
            /etc/ux8406ma/log-manager.sh "Rotated to right position"
            ;;
        *)
            
            /etc/ux8406ma/log-manager.sh "ERROR: Unknown orientation: $orientation"
            ;;
    esac

    restore_brightness "eDP-1" "$edp1_current_brightness" "orientation" "eDP-1" "$orientation"
}


monitor-sensor | while read -r line; do
    if [[ $line == *"Accelerometer orientation changed:"* ]]; then
        orientation=$(echo "$line" | awk -F': ' '{print $2}')
        transformed_orientation=$(convert_orientation "$orientation")
        handle_orientation "$transformed_orientation"
    fi
done
