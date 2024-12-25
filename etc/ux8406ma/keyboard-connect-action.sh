#!/bin/bash

source /etc/ux8406ma/.screen_functions.sh

# Stop the rotation monitor service
systemctl stop ux8406ma-screen-rotation-monitor

edp1_current_brightness=$(get_current_brightness "eDP-1")

# Turn Off eDP-2 and rotate eDP-1 to normal
DISPLAY=:0 xrandr --output eDP-1 --rotate normal --output eDP-2 --off

restore_brightness "eDP-1" "$edp1_current_brightness" "status" "off"

# Log
/etc/ux8406ma/log-manager.sh "Keyboard connected. Turn eDP-1 restored to normal, turn Off eDP-2 and stop screen rotation monitor service."