# Recovery

The USB stick `1401` (FAT32) boots OpenCore. macOS mounts it at `/Volumes/1401` and Windows shows it as `Z:\`. Windows can always be started with **F12 → Windows Boot Manager**, independent of the stick, which makes Windows the universal way to repair the stick.

## Fallback configs (on the stick in `EFI/OC/`)

| Problem after a change | Copy this over `config.plist` |
|---|---|
| Boot hangs or needs debugging | `config-rgbfix.plist`: same setup with verbose boot and the picker |
| Wi-Fi broken | `config-identity.plist` (itlwm, then open HeliPort) |
| Identity or iServices problem | `config-fast-trackpad-gpio.plist` |
| No desktop at all (graphics) | `config-safe-nvoff.plist`: Safe Mode with the NVIDIA driver off |
| An older test config | `EFI-backup-oc105-20261008/OC/` on the stick has all of them |

All configs share one USB map. If USB ports misbehave after the RGB port change, copy `rgb/backup/UTBMap-Info.plist.before-rgb-20261008` from the stick over `EFI/OC/Kexts/UTBMap.kext/Contents/Info.plist`.
If the boot or USB misbehaves after `LegionRGBUSBFix.kext` was added, copy `config-yogasmc.plist` over `config.plist` (same config without that kext).

From macOS:

```bash
cp /Volumes/1401/EFI/OC/config-identity.plist /Volumes/1401/EFI/OC/config.plist
```

From Windows, copy `Z:\EFI\OC\config-identity.plist` over `Z:\EFI\OC\config.plist`.

`NVRAM → Delete` covers `boot-args` and `csr-active-config`, so a config change takes effect at the next boot without an NVRAM reset.

## Boot picker

The picker is hidden. Hold **Alt** (Option) or **Esc** right after power-on to show it; it then waits for a choice. If macOS isn't the default any more, pick it and press **Ctrl+Enter**, or run `sudo bash /Volumes/1401/fastboot/set-startup-disk.sh` from macOS.

## OpenCore itself broken (picker doesn't appear)

From Windows, rename `Z:\EFI` and copy `Z:\EFI-backup-oc105-20261008` to `Z:\EFI`. That's the OpenCore 1.0.5 EFI from before the update.

## NVIDIA driver broken

1. Boot `config-safe-nvoff.plist` (Safe Mode, driver off).
2. Reinstall or roll back with `sudo bash /Volumes/1401/nullmoth-install.sh 1.0.9`, or `1.0.6`.
3. To remove the driver completely: run `sudo ./uninstall.sh` from the package's `pkgroot`, **then** remove `nvfb=1 nvaccel=1` from boot-args, or the screen stays black.

`-nvoff` alone doesn't give a desktop: NVRMFB's `NVRMFBClaim` personality still blocks the generic framebuffer. Only Safe Mode (`-x`) skips the Auxiliary Kernel Collection.

## Black screen after sleep or a resolution change

Both are known driver bugs (see [power-sleep.md](power-sleep.md) and [display.md](display.md)). Hold the power button. Neither one saves a bad state.

## Kernel panics

With `debug=0x100` a panic stays on screen. Take a photo. The report is saved to `/Library/Logs/DiagnosticReports/Kernel-*.panic` at the next boot.
