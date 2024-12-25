#!/bin/bash

set -e

# Ensure correct execution directory
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR"

# Install necessary dependencies (if applicable)
echo "Installing dependencies..."
sudo apt update && sudo apt install -y iio-sensor-proxy

# Remove previous configurations and services
echo "Checking for existing configurations and services..."

# Old udev rules
if [ -f "/etc/udev/rules.d/90-ux8406ma-keyboard.rules" ]; then
    echo "Removing old udev rules..."
    sudo rm /etc/udev/rules.d/90-ux8406ma-keyboard.rules
    sudo udevadm control --reload-rules
fi

# Old screen rotation service
if [ -f "/etc/systemd/system/ux8406ma-screen-rotation-monitor.service" ]; then
    echo "Removing old screen rotation service..."
    sudo systemctl stop ux8406ma-screen-rotation-monitor || true
    sudo systemctl disable ux8406ma-screen-rotation-monitor || true
    sudo rm /etc/systemd/system/ux8406ma-screen-rotation-monitor.service
    sudo systemctl daemon-reload
fi

# Old lightdm configurations
if [ -f "/etc/lightdm/lightdm.conf.d/50-ux8406ma-monitor-layout.conf" ]; then
    echo "Removing old lightdm configuration..."
    sudo rm /etc/lightdm/lightdm.conf.d/50-ux8406ma-monitor-layout.conf
fi

# Old files in /etc/ux8406ma
if [ -d "/etc/ux8406ma" ]; then
    echo "Removing old files in /etc/ux8406ma..."
    sudo rm -rf /etc/ux8406ma
fi

# Detect shell and prompt the user
USER_SHELL=$(basename "$SHELL")
echo "Detected shell: $USER_SHELL"
echo "Do you want to use this shell to configure xhost? (default: $USER_SHELL)"
read -rp "Enter shell (bash, zsh, sh, etc.): " SELECTED_SHELL
SELECTED_SHELL=${SELECTED_SHELL:-$USER_SHELL}

# Configure xhost in shell initialization file
echo "Configuring xhost for $SELECTED_SHELL..."
SHELL_RC="$HOME/.${SELECTED_SHELL}rc"
if ! grep -q "xhost +SI:localuser:root" "$SHELL_RC" 2>/dev/null; then
    echo "xhost +SI:localuser:root" >> "$SHELL_RC"
    echo "xhost permissions added to $SHELL_RC."
else
    echo "xhost permissions already exist in $SHELL_RC."
fi

# Create necessary directories
echo "Creating directories..."
sudo mkdir -p /etc/ux8406ma
sudo mkdir -p /etc/lightdm/lightdm.conf.d

# Copy files
cp etc/ux8406ma/* /etc/ux8406ma/
sudo cp etc/udev/rules.d/90-ux8406ma-keyboard.rules /etc/udev/rules.d/
sudo cp etc/lightdm/lightdm.conf.d/50-ux8406ma-monitor-layout.conf /etc/lightdm/lightdm.conf.d/
sudo cp etc/systemd/system/ux8406ma-screen-rotation-monitor.service /etc/systemd/system/

# Make scripts executable
echo "Setting execution permissions..."
sudo chmod +x /etc/ux8406ma/*.sh

# Reload udev rules
echo "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

# Enable and start iio-sensor-proxy service
echo "Attempting to activate iio-sensor-proxy..."
sudo systemctl start iio-sensor-proxy || echo "Failed to start iio-sensor-proxy."

# Enable and activate new screen rotation service
echo "Enabling and activating screen rotation service..."
sudo systemctl daemon-reload
#sudo systemctl enable ux8406ma-screen-rotation-monitor.service
#sudo systemctl start ux8406ma-screen-rotation-monitor.service

echo "Installation completed."
