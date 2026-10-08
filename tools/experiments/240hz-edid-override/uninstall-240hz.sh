#!/bin/bash
# Removes the 240 Hz EDID override (macOS goes back to the panel's own EDID, 60 Hz only). Reboot afterwards.
# Run:  sudo bash /Volumes/1401/refresh240/uninstall-240hz.sh
set -eu
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
rm -f /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5/DisplayProductID-c8b
rmdir /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5 2>/dev/null || true
echo "Override removed. Reboot to apply."
