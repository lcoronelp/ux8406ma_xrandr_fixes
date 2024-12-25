#!/bin/bash

# Stop the rotation monitor service
systemctl stop ux8406ma-screen-rotation-monitor

# Get current brightness of eDP-1
EDP1_CURRENT_BRIGHTNESS=$(DISPLAY=:0 xrandr --verbose | grep -A 5 "^eDP-1" | grep "Brightness" | awk '{print $2}')


# Turn Off eDP-2 and rotate eDP-1 to normal
DISPLAY=:0 xrandr --output eDP-1 --rotate normal --output eDP-2 --off
DISPLAY=:0 xrandr --output eDP-1 --brightness $EDP1_CURRENT_BRIGHTNESS

# Log
/etc/ux8406ma/log-manager.sh "Keyboard connected. Turn eDP-1 restored to normal, turn Off eDP-2 and stop screen rotation monitor service."