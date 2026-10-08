#!/bin/bash
# Stops the boot-log startup job (installed for trackpad debugging) and moves it and its saved
# kernel logs into your Trash. Run:  sudo bash /Volumes/1401/cleanup-bootlog.sh
set -u
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
U=${SUDO_USER:-$(stat -f %Su /dev/console)}; T=/Users/$U/.Trash/claude-bootlog-20261008
mkdir -p "$T"
launchctl bootout system /Library/LaunchDaemons/local.bootdmesg.plist 2>/dev/null
[ -e /Library/LaunchDaemons/local.bootdmesg.plist ] && mv /Library/LaunchDaemons/local.bootdmesg.plist "$T/"
[ -d /Library/Logs/bootdmesg ] && mv /Library/Logs/bootdmesg "$T/"
chown -R "$U":staff "$T"
launchctl print system/local.bootdmesg >/dev/null 2>&1 && echo "WARNING: job still loaded" || echo "Boot-log job stopped and removed."
echo "Moved to your Trash: $(du -sh "$T" | cut -f1) in $(basename "$T")"
