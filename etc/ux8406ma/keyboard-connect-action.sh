#!/bin/bash

# Stop the rotation monitor service
systemctl stop ux8406ma-screen-rotation-monitor

# Turn Off eDP-2 and rotate eDP-1 to normal
DISPLAY=:0 xrandr --output eDP-1 --rotate normal --output eDP-2 --off

# Log
/etc/ux8406ma/log-manager.sh "Keyboard connected. Turn eDP-1 restored to normal, turn Off eDP-2 and stop screen rotation monitor service."