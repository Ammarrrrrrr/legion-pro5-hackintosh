#!/bin/bash
# Removes the boot dmesg job and its saved files.   Run: sudo bash /Volumes/1401/trackpad/remove-bootlog.sh
set -u
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
launchctl bootout system /Library/LaunchDaemons/local.bootdmesg.plist 2>/dev/null
rm -f /Library/LaunchDaemons/local.bootdmesg.plist; rm -rf /Library/Logs/bootdmesg
echo "Removed."
