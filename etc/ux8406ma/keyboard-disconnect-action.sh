#!/bin/bash

# Get current brightness of eDP-1
EDP1_CURRENT_BRIGHTNESS=$(DISPLAY=:0 xrandr --verbose | grep -A 5 "^eDP-1" | grep "Brightness" | awk '{print $2}')

# Turn on eDP-2 and position it below eDP-1
DISPLAY=:0 xrandr --output eDP-2 --auto --below eDP-1
DISPLAY=:0 xrandr --output eDP-1 --brightness $EDP1_CURRENT_BRIGHTNESS

# Start the rotation monitor service
systemctl start ux8406ma-screen-rotation-monitor

# Log
/etc/ux8406ma/log-manager.sh "Keyboard disconnected. Turn On eDP-2 and start screen rotation monitor service."