#!/bin/bash
# Installs the HiDPI (Retina-style) display override for the built-in panel (vendor 9e5, product c8b).
# Run:  sudo bash /Volumes/1401/hidpi/install-hidpi.sh     then restart.
# NOTE: the 240 Hz kit (/Volumes/1401/refresh240) uses the same file; installing one replaces the other.
set -eu
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
H="$(cd "$(dirname "$0")" && pwd)"; T=/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5
mkdir -p "$T"; cp "$H/DisplayProductID-c8b" "$T/DisplayProductID-c8b"; xattr -c "$T/DisplayProductID-c8b" 2>/dev/null || true
chown -R root:wheel /Library/Displays; chmod 755 "$T"; chmod 644 "$T/DisplayProductID-c8b"; plutil -lint "$T/DisplayProductID-c8b"
echo "Installed. Restart, then:  bash $H/test-hidpi.sh list"
