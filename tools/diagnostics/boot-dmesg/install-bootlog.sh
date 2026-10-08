#!/bin/bash
# Installs a startup job that saves the kernel message buffer (dmesg) once a second for the first ~25 s
# of every boot, before the NVIDIA driver's log spam overwrites it. Files: /Library/Logs/bootdmesg/
# Run:  sudo bash /Volumes/1401/trackpad/install-bootlog.sh        Remove: sudo bash /Volumes/1401/trackpad/remove-bootlog.sh
set -eu
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
H="$(cd "$(dirname "$0")" && pwd)"; L=/Library/LaunchDaemons/local.bootdmesg.plist
cp "$H/local.bootdmesg.plist" "$L"; xattr -c "$L" 2>/dev/null || true
chown root:wheel "$L"; chmod 644 "$L"; plutil -lint "$L"
mkdir -p /Library/Logs/bootdmesg; chmod 755 /Library/Logs/bootdmesg
launchctl bootout system "$L" 2>/dev/null || true
launchctl bootstrap system "$L" && sleep 3 && ls /Library/Logs/bootdmesg | tail -2
echo "Installed. It now runs at every boot."
