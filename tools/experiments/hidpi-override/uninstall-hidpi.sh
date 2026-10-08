#!/bin/bash
# Removes the display override (HiDPI or 240 Hz). Run: sudo bash /Volumes/1401/hidpi/uninstall-hidpi.sh  then restart.
set -eu
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
rm -f /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5/DisplayProductID-c8b
rmdir /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5 2>/dev/null || true
echo "Override removed. Restart to apply."
