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
configure_shell() {
    echo "Detecting and configuring shell..."

    # Generate available shells from /etc/shells and remove duplicates
    local available_shells
    available_shells=($(grep -Eo '/[^ ]+$' /etc/shells | xargs -n1 basename | sort -u))

    # Mark the current shell with (current)
    for i in "${!available_shells[@]}"; do
        if [ "${available_shells[$i]}" = "$USER_SHELL" ]; then
            available_shells[$i]="${available_shells[$i]} (current)"
        fi
    done

    PS3="Choose your shell option (or enter the number): "

    # Use select to allow the user to choose a shell
    echo "Please select the shell to configure xhost from the following options:"

    while true; do
        select OPTION in "${available_shells[@]}" "Other"; do
            OPTION_CLEANED="${OPTION% (current)}"

            if [[ " ${available_shells[@]} " =~ " ${OPTION_CLEANED} " ]]; then
                SELECTED_SHELL="$OPTION_CLEANED"
                break 2
            elif [[ "$OPTION_CLEANED" == "Other" ]]; then
                read -rp "Enter your shell (e.g., fish, ksh, etc.): " SELECTED_SHELL
                break 2
            else
                echo "Invalid option, please choose a valid option:"
                break
            fi
        done
    done

    SELECTED_SHELL=${SELECTED_SHELL:-$USER_SHELL}
    
    # Configure xhost in shell initialization file
    echo ""
    echo "Configuring xhost for $SELECTED_SHELL..."
    local shell_rc="$HOME/.${SELECTED_SHELL}rc"

    if ! grep -q "xhost +SI:localuser:root" "$shell_rc" 2>/dev/null; then
        echo "Adding xhost permissions to $shell_rc..."
        echo "xhost +SI:localuser:root" >> "$shell_rc"
    else
        echo "xhost permissions already exist in $shell_rc."
    fi
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

# Main execution flow
main() {
    ensure_execution_directory
    echo ""
    validate_dependencies
    echo ""
    clean_previous_configurations
    echo ""
    configure_shell
    echo ""
    install_files
    echo ""
    reload_services
    echo ""
    echo "Installation completed successfully."
}

main
