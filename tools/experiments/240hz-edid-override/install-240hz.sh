#!/bin/bash
# Installs the 240 Hz EDID override for the built-in BOE panel (vendor 9e5, product c8b).
# Run:  sudo bash /Volumes/1401/refresh240/install-240hz.sh      then reboot.
set -eu
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
H="$(cd "$(dirname "$0")" && pwd)"
T=/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5
mkdir -p "$T"
cp "$H/DisplayProductID-c8b" "$T/DisplayProductID-c8b"
xattr -c "$T/DisplayProductID-c8b" 2>/dev/null || true
chown -R root:wheel /Library/Displays; chmod 755 "$T"; chmod 644 "$T/DisplayProductID-c8b"
plutil -lint "$T/DisplayProductID-c8b"
echo "Installed $T/DisplayProductID-c8b. Reboot, then run: bash $H/test-240hz.sh"
