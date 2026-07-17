#!/bin/bash
# ----------------------------------------------------------------------------
# Script Name:   DOCKER_NOBLE_UPGRADE.sh
# Purpose:       Automate Docker installation on Ubuntu 26.04 (Noble fallback).
# Execution:     sudo chmod +x DOCKER_NOBLE_UPGRADE.sh && sudo ./DOCKER_NOBLE_UPGRADE.sh
# ----------------------------------------------------------------------------

# Ensure script is executed with root/administrative privileges
if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: This execution script must be run as root."
    exit 1
fi

echo "[+] Initializing Docker Engine deployment..."

# Remove any lingering broken repository configuration lists
rm -f /etc/apt/sources.list.d/docker.list

# Install prerequisite security layers
apt-get update
apt-get install -y ca-certificates curl gnupg

# Establish a secure directory keyring
install -m 0755 -d /etc/apt/keyrings

# Fetch the official Docker GPG security key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "[+] Injecting noble stable packages mirror fallback path..."
# Hardcode noble stable repository stream
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[+] Registering changes and installing core container runtime packages..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify the Docker system daemon status
echo "[+] Verification Check: Docker service status:"
systemctl is-active docker

# Establish non-root user execution permissions
TARGET_USER="amin"
if id "$TARGET_USER" &>/dev/null; then
    echo "[+] Assigning non-root socket privileges to user: $TARGET_USER..."
    usermod -aG docker "$TARGET_USER"
    echo "[+] System permissions successfully configured."
    echo "[*] Action required: Run 'newgrp docker' in active user terminal."
else
    echo "[*] Warning: User $TARGET_USER not found. Group assignment skipped."
fi
