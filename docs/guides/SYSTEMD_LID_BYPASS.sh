#!/bin/bash
# ----------------------------------------------------------------------------
# Script Name:   SYSTEMD_LID_BYPASS.sh
# Purpose:       Automate laptop lid-close sleep override on Ubuntu Server.
# Execution:     sudo chmod +x SYSTEMD_LID_BYPASS.sh && sudo ./SYSTEMD_LID_BYPASS.sh
# ----------------------------------------------------------------------------

# Ensure script is executed with root/administrative privileges
if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: This execution script must be run as root."
    exit 1
fi

echo "[+] Initializing closed-lid power policy override..."

# Target configuration file path
CONFIG_FILE="/etc/systemd/logind.conf"

# Verify that the configuration file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "[+] Modifying ACPI sleep profiles inside $CONFIG_FILE..."

    # Remove comment characters and set policies to ignore
    sed -i 's/^#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' "$CONFIG_FILE"
    sed -i 's/^#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' "$CONFIG_FILE"

    # Double check for cases where the parameters were already uncommented
    sed -i 's/^HandleLidSwitch=suspend/HandleLidSwitch=ignore/' "$CONFIG_FILE"
    sed -i 's/^HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' "$CONFIG_FILE"

    echo "[+] Configuration updated successfully."
else
    echo "[-] Error: Configuration file $CONFIG_FILE was not found."
    exit 1
fi

echo "[+] Restarting systemd-logind service to apply changes..."
systemctl restart systemd-logind

echo "[+] Verification Check: systemd-logind status:"
systemctl is-active systemd-logind

echo "[+] Operational success. You may now close the physical laptop lid."
