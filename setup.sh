#!/bin/bash

set -e

# Log file for debugging
LOG_FILE="/var/log/ux8406ma_install.log"
exec > >(tee -i "$LOG_FILE") 2>&1

# Global variables
SCRIPT_DIR=$(dirname "$0")
USER_SHELL=$(basename "$SHELL")

DEPENDENCIES=(
    "iio-sensor-proxy"
    "python3-usb"
)

# Ensure correct execution directory
ensure_execution_directory() {
    if [ -d "$SCRIPT_DIR" ]; then
        cd "$SCRIPT_DIR"
    else
        echo "Error: Script directory does not exist."
        exit 1
    fi
}

# Validate critical dependencies
validate_dependencies() {
    for dependency in "${DEPENDENCIES[@]}"; do
        echo "Validating dependency: $dependency..."
        
        # Check if the dependency is installed
        if ! dpkg -l | grep -q "${dependency}"; then
            echo "Installing $dependency..."
            sudo apt update && sudo apt install -y "$dependency"

            # Verify installation
            if ! dpkg -l | grep -q "${dependency}"; then
                echo "Error: $dependency package could not be installed."
                exit 1
            fi
        else
            echo "Dependency $dependency already exists."
        fi
    done
}

# Clean previous configurations
clean_previous_configurations() {
    echo "Removing old configurations..."
    
    # Remove old udev rules
    if [ -f "/etc/udev/rules.d/90-ux8406ma-keyboard.rules" ]; then
        echo "Removing old udev rules..."
        sudo rm "/etc/udev/rules.d/90-ux8406ma-keyboard.rules"
        sudo udevadm control --reload-rules
    fi

    # Remove old screen rotation service
    if [ -f "/etc/systemd/system/ux8406ma-screen-rotation-monitor.service" ]; then
        echo "Removing old screen rotation service..."
        sudo systemctl stop ux8406ma-screen-rotation-monitor || true
        sudo systemctl disable ux8406ma-screen-rotation-monitor || true
        sudo rm "/etc/systemd/system/ux8406ma-screen-rotation-monitor.service"
        sudo systemctl daemon-reload
    fi

    # Remove old LightDM configurations
    if [ -f "/etc/lightdm/lightdm.conf.d/50-ux8406ma-monitor-layout.conf" ]; then
        echo "Removing old LightDM configuration..."
        sudo rm "/etc/lightdm/lightdm.conf.d/50-ux8406ma-monitor-layout.conf"
    fi

    # Remove old files in /etc/ux8406ma
    if [ -d "/etc/ux8406ma" ]; then
        echo "Removing old files in /etc/ux8406ma..."
        sudo rm -rf "/etc/ux8406ma"
    fi
}

# Detect and configure the user's shell
configure_xhost_xprofile() {
    echo "Configuring xhost in .xprofile..."

    # Define the .xprofile file
    local xprofile_file="$HOME/.xprofile"

    # Check if the file exists, if not, create it
    if [ ! -f "$xprofile_file" ]; then
        echo "Creating .xprofile file..."
        touch "$xprofile_file"
    fi

    # Ensure the file has execution permissions
    chmod +x "$xprofile_file"

    # Check if the xhost command is already in the file
    if ! grep -q "DISPLAY=:0 xhost +SI:localuser:root" "$xprofile_file" 2>/dev/null; then
        echo "Adding xhost permissions to .xprofile..."
        echo "DISPLAY=:0 xhost +SI:localuser:root" >> "$xprofile_file"
    else
        echo "xhost permissions already exist in .xprofile."
    fi

    echo "Configuration complete. The .xprofile file has been updated."
}

# Install necessary files
install_files() {
    echo "Copying files and setting permissions..."
    sudo mkdir -p /etc/ux8406ma
    sudo mkdir -p /etc/lightdm/lightdm.conf.d
    
    if [ -d "etc/ux8406ma" ]; then
        sudo cp -r etc/ux8406ma/* /etc/ux8406ma/
    fi
    if [ -f "etc/udev/rules.d/90-ux8406ma-keyboard.rules" ]; then
        sudo cp etc/udev/rules.d/90-ux8406ma-keyboard.rules /etc/udev/rules.d/
    fi

    if [ -f "etc/lightdm/lightdm.conf.d/50-ux8406ma-monitor-layout.conf" ]; then
        sudo cp etc/lightdm/lightdm.conf.d/50-ux8406ma-monitor-layout.conf /etc/lightdm/lightdm.conf.d/
    fi

    if [ -f "etc/systemd/system/ux8406ma-screen-rotation-monitor.service" ]; then
        sudo cp etc/systemd/system/ux8406ma-screen-rotation-monitor.service /etc/systemd/system/
    fi

    sudo chmod +x /etc/ux8406ma/*.sh

}

# Reload services and apply changes
reload_services() {
    echo "Reloading services..."
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    sudo systemctl start iio-sensor-proxy || echo "Failed to start iio-sensor-proxy."
    sudo systemctl daemon-reload
    echo "Services reloaded successfully."
}

# Create the shortcuts
create_shortcuts() {
    echo "Creating shortcuts..."

    SHORTCUTS=(
        "<Super>F1:/etc/ux8406ma/speaker-volume.sh mute"
        "<Super>F2:/etc/ux8406ma/speaker-volume.sh down"
        "<Super>F3:/etc/ux8406ma/speaker-volume.sh up"
        "<Super>F4:python3 /etc/ux8406ma/keyboard-backlight.py"
        "<Super>F5:/etc/ux8406ma/screen-brightness-change-action.sh down"
        "<Super>F6:/etc/ux8406ma/screen-brightness-change-action.sh up"
        "<Super>F7:/etc/ux8406ma/screen-brightness-change-action.sh reset"
    )
    for shortcut in "${SHORTCUTS[@]}"; do
        KEYBINDING="${shortcut%%:*}" # Extraer la tecla
        COMMAND="${shortcut##*:}"    # Extraer el comando
        xfconf-query -c $XFCE_CHANNEL -p "$CUSTOM_PATH/$KEYBINDING" -r 2>/dev/null
        xfconf-query -c $XFCE_CHANNEL -p "$CUSTOM_PATH/$KEYBINDING" -s "$COMMAND" --create -t string
    done
    echo "Shortcuts created succesfully."
}

# Main execution flow
main() {
    ensure_execution_directory
    echo ""
    validate_dependencies
    echo ""
    clean_previous_configurations
    echo ""
    configure_xhost_xprofile
    echo ""
    install_files
    echo ""
    reload_services
    echo ""
    create_shortcuts
    echo ""
    echo "Installation completed successfully."
}

main
