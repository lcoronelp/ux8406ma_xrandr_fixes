#!/bin/bash

# Turn on eDP-2 and position it below eDP-1
DISPLAY=:0 xrandr --output eDP-2 --auto --below eDP-1

# Start the rotation monitor service
systemctl start ux8406ma-screen-rotation-monitor

# Log
/etc/ux8406ma/log-manager.sh "Keyboard disconnected. Turn On eDP-2 and start screen rotation monitor service."