# Lenovo Legion Pro 5 16IRX9 on macOS Sequoia with NVIDIA acceleration

macOS 15.8.1 Sequoia on a Lenovo Legion Pro 5 16IRX9 (i9-14900HX, RTX 4060 Laptop). It runs with real Metal 3 acceleration on the laptop's own screen through the community **NullMoth** NVIDIA driver, booted by **OpenCore 1.0.8** from a USB stick.

This repository documents the whole setup, built on 2026-10-07 and 2026-10-08:

- where every piece came from
- what was changed and why
- what works, and what doesn't yet
- how to recover

The OpenCore EFI in `EFI/` is the exact working copy. The only difference is that the Mac serial number, board serial, UUID and ROM are **replaced by placeholders**. Generate your own before using it (see [docs/mac-identity.md](docs/mac-identity.md)).

## Status

| Area | Status | Notes |
|---|---|---|
| Graphics | ✅ NVIDIA RTX 4060, Metal 3, 2560×1600 @ 60 Hz | NullMoth driver 1.0.9 (all later packages up to 1.0.11 ship the same driver files) |
| Boot | ✅ about 16 s from kernel start to the login window | no verbose mode, `-nvrmnobootscreen`, hidden picker (hold Alt or Esc), no `nvrmsettle` |
| Trackpad | ✅ multitouch with gestures, interrupt mode | VoodooI2C with a Raptor Lake controller ID, plus a Raptor Lake build of VoodooGPIO |
| Wi-Fi | ✅ native macOS Wi-Fi menu | AirportItlwm 2.4.0-alpha (laobamac fork) for Sequoia, no root patches |
| Bluetooth | ✅ | IntelBluetoothFirmware + IntelBTPatcher + BlueToolFixup |
| Keyboard | ✅ PS/2 | VoodooPS2 |
| Keyboard lighting | ✅ 4-zone RGB | USB map change + `LegionRGBUSBFix.kext`; app in the private repo [legion-rgb-macos](https://github.com/Ammarrrrrrr/legion-rgb-macos) |
| Lenovo features | ✅ driver loaded | YogaSMC 1.5.3 (`IdeaVPC`, Game Zone WMI): Fn-lock, battery conservation and rapid charge. Not every feature tested. |
| Audio | ✅ devices present (speakers, mic) | AppleALC layout-id 99. Headphone jack not tested. |
| Camera | ✅ QuickTime, FaceTime, browsers | Photo Booth stays black (driver gap). The laptop's physical camera switch must be open. |
| Battery, USB, NVMe, Ethernet | ✅ | SMCBatteryManager, USBToolBox + UTBMap, NVMeFix, RealtekRTL8111 |
| Apple ID / iCloud | ✅ signed in | own MacBookPro16,4 serial, `CustomSMBIOSGuid` |
| System sleep | ❌ disabled | the driver loses the GPU on wake (`Xid 79`). Display sleep works. |
| Changing resolution | ❌ freezes the system | every non-native mode goes through the driver's scaler path |
| Brightness control | ❌ | no backlight device in the driver |
| 240 Hz | ❌ 60 Hz only | the panel lists 240 Hz only in DisplayID 2.0. EDID overrides don't help, so the driver has to offer the mode. |
| External displays | untested | HDMI is wired to the NVIDIA GPU |

## Repository layout

| Path | Contents |
|---|---|
| `EFI/` | The working OpenCore 1.0.8 EFI (identity values sanitised). `EFI/OC/config.plist` is the everyday config. |
| `docs/` | One document per topic (below). |
| `tools/` | Every script written for this machine: driver installer, trackpad kext build, internal-boot setup, diagnostics, experiments. |
| `reports/nullmoth/` | The bug report written for the NullMoth developers. |

## Documentation

| Document | Covers |
|---|---|
| [docs/hardware.md](docs/hardware.md) | Exact hardware, PCI IDs, BIOS settings |
| [docs/opencore-efi.md](docs/opencore-efi.md) | How the EFI was built, every kext and setting, the config files |
| [docs/nvidia-nullmoth.md](docs/nvidia-nullmoth.md) | The NVIDIA driver: install, versions, boot timing, BAR1, known bugs |
| [docs/trackpad.md](docs/trackpad.md) | How the I2C trackpad was made to work, step by step |
| [docs/wifi-bluetooth.md](docs/wifi-bluetooth.md) | itlwm + HeliPort → native AirportItlwm on Sequoia |
| [docs/mac-identity.md](docs/mac-identity.md) | SMBIOS, serial generation, the `CustomSMBIOSGuid` fix |
| [docs/display.md](docs/display.md) | Resolution freeze, 240 Hz investigation, brightness, HiDPI idea |
| [docs/power-sleep.md](docs/power-sleep.md) | Why system sleep is disabled, shutdown "stalls" |
| [docs/camera-audio-memory-usb.md](docs/camera-audio-memory-usb.md) | Webcam, audio, RAM reporting, USB |
| [docs/maintenance-updates.md](docs/maintenance-updates.md) | Updating OpenCore, kexts, NullMoth and macOS safely |
| [docs/recovery.md](docs/recovery.md) | What to do when it doesn't boot |
| [docs/debugging-notes.md](docs/debugging-notes.md) | Logging techniques and pitfalls found on this machine |
| [docs/sources.md](docs/sources.md) | Every download with version, URL and SHA-256 |
| [docs/timeline.md](docs/timeline.md) | What was done, in order |

## Quick facts

- **BIOS GPU mode must stay *Discrete*.** In Hybrid mode the panel hangs off the Intel iGPU, which macOS can't drive.
- **The OpenCore stick is required to boot.** Keep it plugged in. A script to move OpenCore to the internal drive is prepared but not used yet (`tools/internal-boot/`).
- **Automatic macOS updates are off.** The NVIDIA driver must be checked against each macOS update. It needs macOS 15.5 or later, and macOS 26 isn't supported.
- **System sleep is disabled** (`pmset disablesleep 1`). Closing the lid only turns the screen off, so shut down before putting the laptop in a bag.
