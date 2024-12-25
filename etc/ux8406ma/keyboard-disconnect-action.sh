#!/bin/bash

source /etc/ux8406ma/.screen_functions.sh

edp1_current_brightness=$(get_current_brightness "eDP-1")

# Turn on eDP-2 and position it below eDP-1
DISPLAY=:0 xrandr --output eDP-2 --auto --below eDP-1

restore_brightness "eDP-1" "$edp1_current_brightness" "status" "on"

# Start the rotation monitor service
systemctl start ux8406ma-screen-rotation-monitor

# Log
/etc/ux8406ma/log-manager.sh "Keyboard disconnected. Turn On eDP-2 and start screen rotation monitor service."