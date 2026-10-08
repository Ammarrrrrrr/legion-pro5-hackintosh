#!/bin/bash
# Copies OpenCore from the USB stick (/Volumes/1401/EFI) to the spare internal EFI partition
# (1 GB FAT32, partition UUID 4134DAA5-618A-459A-9F2C-19DBA0B0D52E, normally disk0s5).
# Anything already in its EFI folder is backed up to the stick first. The internal copy gets
# Misc > Boot > LauncherOption = Full so OpenCore keeps itself first in the firmware boot order.
# Run:  sudo bash /Volumes/1401/internal-boot/copy-oc-to-internal.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
PART_UUID=4134DAA5-618A-459A-9F2C-19DBA0B0D52E
SRC=/Volumes/1401/EFI; H="$(cd "$(dirname "$0")" && pwd)"; TS=$(date +%Y%m%d-%H%M%S)
DEV=$(diskutil info "$PART_UUID" | awk -F': *' '/Device Node/{print $2}')
[ -n "$DEV" ] || { echo "STOP: partition $PART_UUID not found"; exit 1; }
diskutil info "$DEV" | grep -q "Partition Type: *EFI" || { echo "STOP: $DEV is not an EFI partition"; exit 1; }
echo "== target $DEV"; diskutil info "$DEV" | grep -E "Disk Size|File System Personality"
diskutil mount "$DEV" >/dev/null; MP=$(diskutil info "$DEV" | awk -F': *' '/Mount Point/{print $2}')
[ -d "$MP" ] || { echo "STOP: could not mount $DEV"; exit 1; }
echo "== current contents of $MP"; ls -la "$MP"
if [ -e "$MP/EFI" ]; then
  tar -czf "$H/internal-EFI-backup-$TS.tgz" -C "$MP" EFI && echo "   backed up existing EFI to $H/internal-EFI-backup-$TS.tgz"
fi
rm -rf "$MP/EFI.new"
ditto --norsrc --noextattr --noqtn "$SRC" "$MP/EFI.new"; find "$MP/EFI.new" -name '._*' -delete
[ ! -e "$MP/EFI" ] || mv "$MP/EFI" "$MP/EFI.old-$TS"
mv "$MP/EFI.new" "$MP/EFI"
/usr/libexec/PlistBuddy -c "Set :Misc:Boot:LauncherOption Full" "$MP/EFI/OC/config.plist"
plutil -lint "$MP/EFI/OC/config.plist"
echo "== differences stick vs internal (expect only config.plist):"; diff -rq "$SRC" "$MP/EFI" | grep -v '/\._' || true
sync; diskutil unmount "$DEV" >/dev/null && echo "== done, $DEV unmounted. Next: the Windows step in README.txt"
