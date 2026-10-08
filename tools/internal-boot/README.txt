Boot OpenCore from the internal drive (no USB stick needed)

1. macOS (Terminal):   sudo bash /Volumes/1401/internal-boot/copy-oc-to-internal.sh
   Copies /Volumes/1401/EFI to the spare 1 GB EFI partition (GUID 4134DAA5-...), backing up anything
   already there, and sets LauncherOption=Full in the internal config.plist.
2. Windows (Administrator PowerShell):
   powershell -ExecutionPolicy Bypass -File Z:\internal-boot\add-opencore-boot-entry.ps1
   Adds an "OpenCore" UEFI boot entry first in the boot order (Windows Boot Manager stays).
3. Restart without the USB stick -> OpenCore picker (3 s) -> macOS. Windows: pick it in the picker or F12.

Afterwards the internal copy is the one that boots: config changes must be made on the internal EFI
partition (mount with: sudo diskutil mount 4134DAA5-618A-459A-9F2C-19DBA0B0D52E). Keep the stick as a rescue
disk: plug it in and choose it with F12 if the internal copy ever fails.
Undo: in Windows, bcdedit /delete {the OpenCore id}; or just keep booting from the stick with F12.
