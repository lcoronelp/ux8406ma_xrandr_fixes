#!/usr/bin/env python3

import sys
import usb.core
import usb.util
import os

# USB Parameters
VENDOR_ID = 0x0b05
PRODUCT_ID = 0x1b2c
REPORT_ID = 0x5A
WVALUE = 0x035A
WINDEX = 4
WLENGTH = 16

# File to store the current level
STATE_FILE = "~/.config/keyboard_brightness_level"

def get_next_level():
    try:
        # Read the current level from the state file
        if os.path.exists(STATE_FILE):
            with open(STATE_FILE, "r") as file:
                level = int(file.read().strip())
        else:
            level = -1  # Default to -1 so the first increment is 0
    except Exception as e:
        print(f"Error reading state file: {e}")
        level = -1

    # Increment level and wrap around to 0 after 3
    level = (level + 1) % 4

    # Save the new level back to the state file
    try:
        with open(STATE_FILE, "w") as file:
            file.write(str(level))
    except Exception as e:
        print(f"Error writing state file: {e}")

    return level

def send_brightness_level(level):
    # Prepare the data packet
    data = [0] * WLENGTH
    data[0] = REPORT_ID
    data[1] = 0xBA
    data[2] = 0xC5
    data[3] = 0xC4
    data[4] = level

    # Find the device
    dev = usb.core.find(idVendor=VENDOR_ID, idProduct=PRODUCT_ID)

    if dev is None:
        print(f"Device not found (Vendor ID: 0x{VENDOR_ID:04X}, Product ID: 0x{PRODUCT_ID:04X})")
        sys.exit(1)

    # Detach kernel driver if necessary
    if dev.is_kernel_driver_active(WINDEX):
        try:
            dev.detach_kernel_driver(WINDEX)
        except usb.core.USBError as e:
            print(f"Could not detach kernel driver: {str(e)}")
            sys.exit(1)

    # Send the control transfer
    try:
        bmRequestType = 0x21  # Host to Device | Class | Interface
        bRequest = 0x09       # SET_REPORT
        wValue = WVALUE       # 0x035A
        wIndex = WINDEX       # Interface number
        ret = dev.ctrl_transfer(bmRequestType, bRequest, wValue, wIndex, data, timeout=1000)
        if ret != WLENGTH:
            print(f"Warning: Only {ret} bytes sent out of {WLENGTH}.")
        else:
            print(f"Brightness level {level} set successfully.")
    except usb.core.USBError as e:
        print(f"Control transfer failed: {str(e)}")
        usb.util.release_interface(dev, WINDEX)
        sys.exit(1)

    # Release the interface
    usb.util.release_interface(dev, WINDEX)
    # Reattach the kernel driver if necessary
    try:
        dev.attach_kernel_driver(WINDEX)
    except usb.core.USBError:
        pass  # Ignore if we can't reattach the driver

# Main logic
if __name__ == "__main__":
    level = get_next_level()
    send_brightness_level(level)
