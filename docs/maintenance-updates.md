# Maintenance and updates

## macOS updates

**Automatic macOS updates are off** (System Settings → General → Software Update → Automatic Updates → "Install macOS updates" off). Before installing any macOS update:

1. Check the NullMoth releases and issues for that exact version. Its NVIDIA userland needs macOS 15.5 or later, and **macOS 26 isn't supported**.
2. Make sure you can recover (see [recovery.md](recovery.md)): the stick, `config-safe-nvoff.plist` and the Windows fallback.
3. After the update, check that the four NullMoth kexts load (`kmutil showloaded --list-only | grep nullmoth`). If they don't, reinstall the driver: `sudo bash tools/nullmoth-install.sh 1.0.9`.

## OpenCore and kext updates (as done on 2026-10-08, OpenCore 1.0.5 → 1.0.8)

1. Inventory: `nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version`, then read every kext's `CFBundleShortVersionString`.
2. Get the latest release versions and their asset SHA-256 digests from the GitHub API (`/repos/<owner>/<repo>/releases/latest`).
3. Download the **RELEASE** zips, each into its own empty folder, and compare SHA-256 against the published digest.
4. Build the new EFI in a scratch folder, not on the stick:
   - `BOOTx64.efi`, `OpenCore.efi`, `OpenRuntime.efi`, `OpenCanopy.efi`, `ResetNvramEntry.efi` from `X64/EFI/`
   - replace each kext bundle whole, keeping the same bundle name and executable
5. Run the new `Utilities/ocvalidate/ocvalidate` on every config and add any missing keys with their `Docs/Sample.plist` defaults. 1.0.8 only needed `UEFI/Drivers/*/HideVerbose = false`. Repeat until it reports "No issues found".
6. Read `Docs/Changelog.md` for the versions you're skipping.
7. Back up the stick's EFI (`EFI-backup-oc105-20261008`), copy the new EFI over it, and compare with `diff -rq`.
8. Reboot and check `opencore-version` and the loaded kext versions.

Kexts that were **not** updated on purpose:
- **Already newer than the last public release:** VoodooPS2 2.3.8, BrightnessKeys 1.0.4, IntelBluetoothFirmware/IntelBTPatcher 2.5.0.
- **Custom builds:** VoodooI2C-RPL-GPIO (see [trackpad.md](trackpad.md)) and AirportItlwm (laobamac fork).

## NullMoth driver updates

1. Read the release notes. Many releases change only the installer or the 1401 app. Packages 1.0.10 and 1.0.11 have driver files byte-identical to 1.0.9.
2. Download `nullmoth-nvidia-<v>.tar.gz` and check its SHA-256 against the GitHub asset digest and `SHA256SUMS.txt`.
3. Add the version and its hash to [`tools/nullmoth-install.sh`](../tools/nullmoth-install.sh), put the package at `/Volumes/1401/NullMoth/<v>/`, then run `sudo bash nullmoth-install.sh <v>` and reboot.
4. **Don't use the 1401 app's "USB-to-internal OpenCore promotion"** in app versions up to 1.0.15. It could delete Windows' boot files, and was disabled in 1.0.16.

## Trackpad kext after a VoodooI2C update

Reapply both changes from [trackpad.md](trackpad.md):
1. `0x7a7d8086&0xFFFFFFFF` in the `VoodooI2CPCILakeController` `IOPCIMatch`.
2. The VoodooGPIO plug-in built from the victorwitkamp fork, unless upstream has merged `INTC1085` support by then.

## Wi-Fi kext

Watch [laobamac/itlwm](https://github.com/laobamac/itlwm/releases) for a non-alpha Sequoia build. Use the **Sequoia** build only, with `MinKernel 24.2.0` / `MaxKernel 24.99.99`.

## Open items

- Optional Wi-Fi 6: add `itlwm_he=1`.
- Not tested yet: headphone jack, Bluetooth pairing, HDMI output, Fn keys.
- Windows clock: Windows keeps the hardware clock in local time and macOS in UTC. Fix it on the Windows side with the registry value `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\RealTimeIsUniversal` (DWORD 1).
- Boot from the internal drive: [`tools/internal-boot/`](../tools/internal-boot/) is prepared (copy to the spare 1 GB EFI partition, then add a `bcdedit` boot entry from Windows) but not used.
