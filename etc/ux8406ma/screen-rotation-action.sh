#!/bin/bash

# Check if eDP-2 is powered on
is_edp2_on() {
    DISPLAY=:0 xrandr | grep -q "eDP-2 connected [0-9]"
    return $?
}

# Get the current orientation of a screen
get_orientation() {
    local screen=$1
    DISPLAY=:0 xrandr | grep "$screen connected" | grep -o "normal\|inverted\|left\|right" | head -n 1
}

handle_orientation() {
    local orientation=$1

    if ! is_edp2_on; then
        systemctl stop ux8406ma-screen-rotation-monitor.service
        /etc/ux8406ma/log-manager.sh "No rotation applied: eDP-2 is Off"
        exit 0
    fi

    local current_orientation=$(get_orientation "eDP-1")

    if [[ $current_orientation == "$orientation" ]]; then
        /etc/ux8406ma/log-manager.sh "No rotation applied: eDP-1 is already $orientation"
        return
    fi

    case $orientation in
        "normal")
            DISPLAY=:0 xrandr --output eDP-1 --rotate normal --output eDP-2 --rotate normal --below eDP-1 &>/dev/null
            /etc/ux8406ma/log-manager.sh "Rotated to normal position"
            ;;
        "bottom-up")
            DISPLAY=:0 xrandr --output eDP-1 --rotate inverted --output eDP-2 --rotate inverted --above eDP-1 &>/dev/null
            /etc/ux8406ma/log-manager.sh "Rotated to inverted position"
            ;;
        "left-up")
            DISPLAY=:0 xrandr --output eDP-1 --rotate left --output eDP-2 --rotate left --left-of eDP-1 &>/dev/null
            /etc/ux8406ma/log-manager.sh "Rotated to left position"
            ;;
        "right-up")
            DISPLAY=:0 xrandr --output eDP-1 --rotate right --output eDP-2 --rotate right --right-of eDP-1 &>/dev/null
            /etc/ux8406ma/log-manager.sh "Rotated to right position"
            ;;
        *)
            echo "$(date '+%Y/%m/%d %H:%M:%S') Unknown orientation: $orientation"
            ;;
    esac
}

monitor-sensor | while read -r line; do
    if [[ $line == *"Accelerometer orientation changed:"* ]]; then
        orientation=$(echo "$line" | awk -F': ' '{print $2}')
        handle_orientation "$orientation"
    fi
done