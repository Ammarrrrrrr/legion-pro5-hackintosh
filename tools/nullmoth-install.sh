#!/bin/bash
# Installs a NullMoth NVIDIA driver package from this stick, following the README's "prebuilt install"
# (check the download, shasum -c SHA256SUMS, sudo ./install.sh). The OpenCore config is NOT touched.
#   update:    sudo bash /Volumes/1401/nullmoth-install.sh 1.0.9
#   rollback:  sudo bash /Volumes/1401/nullmoth-install.sh 1.0.6
# Then restart. Output is also saved to nullmoth-install-<version>-log.txt on this stick.
set -u
STICK=$(cd "$(dirname "$0")" && pwd)
V=${1:-}
case "$V" in
  1.0.9) SHA=9dbfdb1b1359e2ef4166a46905ee195774b0b4ba20be083a8111ef550b1e5789 ;;   # GitHub release v1.0.14 asset digest
  1.0.6) SHA=25fdedc727b4ee3792ff5439d056d79f362219c77e5a3f2bdd35e054429229cf ;;   # GitHub release v1.0.9 asset digest
  *) echo "usage: sudo bash $0 1.0.9   (or 1.0.6 to roll back)"; exit 2 ;;
esac
PKG="$STICK/NullMoth/$V/nullmoth-nvidia-$V.tar.gz"
LOG="$STICK/nullmoth-install-$V-log.txt"
exec > >(tee "$LOG") 2>&1
stop() { echo; echo "STOPPED: $*"; echo "Nothing after this point ran. Your current driver is unchanged unless install.sh said it restored a backup."; exit 1; }

echo "== $(date)   macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion))   installing NullMoth driver $V"
[ "$(id -u)" -eq 0 ] || stop "run it with sudo:  sudo bash $0 $V"
[ -f "$PKG" ] || stop "package not found: $PKG"
echo "   driver loaded now:"; kmutil showloaded --list-only 2>/dev/null | grep -i nullmoth | awk '{print "     " $6, $7}'

echo "== 1. checking the download against the GitHub digest"
got=$(shasum -a 256 "$PKG" | awk '{print $1}')
[ "$got" = "$SHA" ] || stop "SHA-256 mismatch ($got)"
echo "   ok  $got"

echo "== 2. unpacking and checking every file (shasum -c SHA256SUMS)"
T=$(mktemp -d /var/tmp/nullmoth-$V.XXXX) || stop "could not make a temp folder"
tar -xzf "$PKG" -C "$T" || stop "could not unpack"
( cd "$T/pkgroot" && shasum -a 256 -c SHA256SUMS >/dev/null ) || stop "a file in the package does not match SHA256SUMS"
echo "   ok  all files match"

echo "== 3. NullMoth's install.sh (backs up the current driver to /Library/NullMoth/backup-*)"
( cd "$T/pkgroot" && ./install.sh ); rc=$?
[ $rc -eq 0 ] || stop "install.sh failed (exit $rc) - see the lines above"

echo "== 4. driver in the new auxiliary kernel collection:"
kmutil inspect -a x86_64 -A /Library/KernelCollections/AuxiliaryKernelExtensions.kc 2>/dev/null | grep -i nullmoth
rm -rf "$T"

echo
echo "DONE: driver $V installed. Restart now:   sudo shutdown -r now"
echo "If macOS asks to allow the extensions (System Settings > Privacy & Security), allow them and restart once more."
