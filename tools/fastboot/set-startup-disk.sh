#!/bin/bash
# Make the running macOS volume OpenCore's default boot entry.
# OpenCore reads efi-boot-device (the Startup Disk setting) from NVRAM. With the
# picker hidden (ShowPicker false), this decides what boots without a key press.
# Usage: sudo bash /Volumes/1401/fastboot/set-startup-disk.sh
set -e
[ "$(id -u)" = 0 ] || { echo "Run it with sudo."; exit 1; }

bless --mount / --setBoot
echo "Startup disk set. NVRAM now says:"
nvram efi-boot-device | cut -c1-200
