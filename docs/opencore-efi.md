# OpenCore EFI

## Where it came from

1. **Base: `efi_legion-main`.** This is a community OpenCore EFI for this laptop, written for **Hybrid** GPU mode with the Intel iGPU driven by NootedBlue. It was downloaded as `efi_legion-main.zip` on Windows; the exact source URL wasn't recorded. A copy of the stick's EFI before any edits is kept on the stick as `EFI-backup-before-claude`. `EFI-noedit` on the stick is the EFI that the NullMoth "1401" app generated.
2. **Adapted for Discrete mode and the NullMoth driver** on 2026-10-07 and 2026-10-08:
   - NootedBlue disabled. With the iGPU off it panicked with `videoBuiltin is not IOPCIDevice`, which was the original boot hang.
   - `disable-gpu` removed from the RTX 4060 in DeviceProperties.
   - NullMoth boot-args added, and `csr-active-config` set to `0xA43`, as NullMoth requires.
3. **Then tuned:**
   - boot time (see [nvidia-nullmoth.md](nvidia-nullmoth.md))
   - trackpad ([trackpad.md](trackpad.md))
   - Mac identity ([mac-identity.md](mac-identity.md))
   - native Wi-Fi ([wifi-bluetooth.md](wifi-bluetooth.md))
   - updated from OpenCore 1.0.5 to **1.0.8**, along with its kexts

## Config files in `EFI/OC/`

| File | Role |
|---|---|
| `config.plist` | **Everyday config.** Identical to `config-yogasmc-legion.plist`. |
| `config-yogasmc-legion.plist` | `config-fastboot.plist` with `YogaSMC-Legion.kext` (1.6.1 Legion build) instead of `YogaSMC.kext` 1.5.3. Nothing else differs. |
| `config-fastboot.plist` | `config-rgbfix.plist` without the debug boot-args, plus `-nvrmnobootscreen` and a hidden picker (`ShowPicker false`, `Timeout 0`, `TakeoffDelay 10000`) |
| `config-rgbfix.plist` | `config-yogasmc.plist` + `LegionRGBUSBFix.kext`. Verbose boot with the picker: the first fallback. |
| `config-yogasmc.plist` | `config-airportitlwm.plist` + `YogaSMC.kext` |
| `config-airportitlwm.plist` | `config-identity.plist` + native Wi-Fi (AirportItlwm enabled, itlwm disabled) + `SystemMemoryStatus Upgradable` |
| `config-identity.plist` | Previous everyday config: itlwm + HeliPort for Wi-Fi, own Mac identity |
| `config-fast-trackpad-gpio.plist` | Like `config-identity.plist`, but without the Mac identity fix (`CustomSMBIOSGuid` off) |
| `config-v110-normal.plist` | Identical to `config-fastboot.plist` (kept from the NullMoth 1.1.0 test) |
| `config-safe-110.plist` | `config-fastboot.plist` with `-v -x -nvoff` and without `-nvrmnobootscreen`: Safe Mode recovery used during the NullMoth 1.1.0 240 Hz test |
| `config-safe-nvoff.plist` | **Recovery:** Safe Mode (`-x`) + `-nvoff`. The NVIDIA driver doesn't load, giving an unaccelerated desktop to repair things from. Same kexts as `config-identity.plist`, so the trackpad works there too. |

All eleven pass `ocvalidate` from OpenCore 1.0.8 with no issues. In this repository the identity values (`SystemSerialNumber`, `MLB`, `SystemUUID`, `ROM`) are OpenCore's sample placeholders.

## Key settings (everyday config)

| Section | Setting | Value | Why |
|---|---|---|---|
| Booter/Quirks | `ResizeAppleGpuBars` | `0` | small BAR for macOS; the NVIDIA driver resizes BAR1 itself |
| UEFI/Quirks | `ResizeGpuBars` | `-1` | leave the firmware's BAR alone |
| Kernel/Block | (empty) | – | no IONDRVSupport block needed with this BAR setup; no IOSkywalkFamily block (no Wi-Fi root patches) |
| Kernel/Emulate | `Cpuid1Data` / `Mask` | `E5060700…` / `FFFFFFFF…` | CPU presented as an Ice Lake-family CPUID (`0x706E5`), from the Legion EFI. Side effect: VoodooI2C's "Comet Lake or Ice Lake" controller fix applies (see [trackpad.md](trackpad.md)). |
| Kernel/Quirks | `DisableIoMapper` | `true` | VT-d is on in BIOS |
| Kernel/Quirks | `CustomSMBIOSGuid` | `true` | required because `UpdateSMBIOSMode` is `Custom`, see [mac-identity.md](mac-identity.md) |
| Kernel/Quirks | `ProvideCurrentCpuInfo`, `AppleXcpmCfgLock`, `AppleXcpmExtraMsrs` | `true` | from the Legion EFI, for the hybrid CPU and XCPM |
| Misc/Boot | `ShowPicker` / `Timeout` / `TakeoffDelay` | `false` / `0` / `10000` | no picker delay. Hold **Alt** (Option) or **Esc** at power-on to show the picker; it then waits for a choice. The default entry is the Startup Disk (`efi-boot-device`), set with [`tools/fastboot/set-startup-disk.sh`](../tools/fastboot/set-startup-disk.sh). |
| Misc/Debug | `Target` / `AppleDebug` | `3` / `false` | no log file on the USB stick. File logging cost about 9.3 s per boot. |
| Misc/Security | `SecureBootModel` / `ScanPolicy` | `Disabled` / `0` | |
| NVRAM | `boot-args` | `nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth -nvrmnobootscreen amfi_get_out_of_my_way=0x1 amfi=0x80` | NullMoth's required args plus `-nvrmnobootscreen` (see [nvidia-nullmoth.md](nvidia-nullmoth.md)). The debug args `-v keepsyms=1 debug=0x100 -liludbg liludump=60` were removed on 2026-10-08; `config-rgbfix.plist` still has them. |
| NVRAM | `csr-active-config` | `430A0000` (0xA43) | required by NullMoth (unsigned kexts in the Auxiliary KC) |
| NVRAM/Delete | `boot-args`, `csr-active-config` | listed | config edits apply at the next boot without an NVRAM reset |
| PlatformInfo | `SystemProductName` | `MacBookPro16,4` | |
| PlatformInfo | `UpdateSMBIOSMode` | `Custom` | Windows keeps seeing the Lenovo SMBIOS |
| PlatformInfo | `SystemMemoryStatus` | `Upgradable` | the laptop has SO-DIMM slots; `Auto` copied the Mac's soldered RAM |
| DeviceProperties | `PciRoot(0x0)/Pci(0x1f,0x3)` → `layout-id` | `99` | AppleALC audio layout |

ACPI tables (from the Legion EFI):
- `SSDT-PLUG-ALT`, `SSDT-AWAC`, `SSDT-EC-USBX`, `SSDT-GPRW`
- `SSDT-GPI0` and `SSDT-XOSI`, for the trackpad
- `SSDT-ALS0`, `SSDT-PNLF`, `SSDT-SBUS-MCHC`, `SSDT-USB-Reset-RHUB`

ACPI renames: `GPI0 _STA → XSTA`, `PNLF → XNLF`, `_OSI → XOSI`.

UEFI drivers: `OpenRuntime`, `OpenCanopy`, `ResetNvramEntry` (all OpenCore 1.0.8) and `HfsPlus`.

## Kexts (load order in the everyday config)

| # | Kext | Version | On | Source / note |
|---|---|---|---|---|
| 0 | Lilu | 1.7.2 | ✅ | acidanthera |
| 1–5 | VirtualSMC, SMCBatteryManager, SMCLightSensor, SMCProcessor, SMCSuperIO | 1.3.8 | ✅ | acidanthera |
| 6 | AppleALC | 1.9.8 | ✅ | acidanthera, layout-id 99 |
| 7 | NVMeFix | 1.1.3 | ✅ | acidanthera |
| 8 | RestrictEvents | 1.1.6 | ✅ | acidanthera (`revpatch=sbvmm,cpuname`, `revcpuname` = real CPU name) |
| 9 | CpuTscSync | 1.1.2 | ✅ | acidanthera |
| 10 | CpuTopologyRebuild | 2.0.2 | ✅ | b00t0x, for the hybrid P/E-core CPU |
| 11 | RealtekRTL8111 | 3.0.0 | ✅ | Mieze |
| 12 | **AirportItlwm** | **2.4.0-alpha** | ✅ | laobamac/itlwm fork, Sequoia build, `MinKernel 24.2.0` `MaxKernel 24.99.99` |
| 13–14 | IntelBTPatcher, IntelBluetoothFirmware | 2.5.0 | ✅ | OpenIntelWireless (newer than the last public release) |
| 15 | BlueToolFixup | 2.7.2 | ✅ | acidanthera BrcmPatchRAM |
| 16 | BrightnessKeys | 1.0.4 | ✅ | acidanthera |
| 17–20 | **VoodooI2C-RPL-GPIO** (+ VoodooGPIO, VoodooI2CServices, VoodooInput plugins) | 2.9.1 modified | ✅ | see [trackpad.md](trackpad.md) |
| 21 | VoodooI2CHID | 1.0 (from VoodooI2C 2.9.1) | ✅ | |
| 22, 24 | VoodooPS2Controller + VoodooPS2Keyboard | 2.3.8 | ✅ | acidanthera |
| 28–29 | USBToolBox + UTBMap | 1.2.0 / 1.1 | ✅ | USBToolBox; UTBMap is the Legion EFI's port map |
| 30 | YogaSMC | 1.6.1 Legion build | ✅ | `YogaSMC-Legion.kext` in `config.plist` / `config-yogasmc-legion.plist`; every other config loads the stock `YogaSMC.kext` 1.5.3 (zhen-zen). Lenovo `VPC2004` (`IdeaVPC`) and Game Zone WMI, see [power-sleep.md](power-sleep.md#lenovo-features-yogasmc) |
| 31 | LegionRGBUSBFix (codeless) | 1.0.0 | ✅ | Gives interface 1 of the ITE 8295 RGB controller (`048d:c995`) a do-nothing driver so macOS stops resetting it every 0.6 s; see camera-audio-memory-usb.md |
| 27 | itlwm | 2.3.0 | off | used before AirportItlwm, with HeliPort |
| 23, 25–26 | VoodooInput, VoodooPS2Mouse, VoodooPS2Trackpad (plug-ins inside VoodooPS2Controller) | 2.3.8 | off | not needed with the I2C trackpad |

**Removed on 2026-10-08:** VoodooRMI, VoodooSMBus, WhateverGreen, XHCI-unsupported, NootedBlue, USBInjectAll and the stock VoodooI2C. They came with the Legion EFI. The first six were off in every config and aren't needed in Discrete mode. The stock VoodooI2C was only used by `config-safe-nvoff.plist`, which now uses VoodooI2C-RPL-GPIO like the other configs. Copies are in `EFI-backup-oc105-20261008` on the stick.

The **NullMoth** kexts are not in the EFI. They're installed into `/Library/Extensions` and load from macOS's Auxiliary Kernel Collection (see [nvidia-nullmoth.md](nvidia-nullmoth.md)).

## Where the live EFI is

The working copy is on the USB stick labelled `1401`: macOS `/Volumes/1401/EFI`, Windows `Z:\EFI`. The stick is also where the backups live:
- `EFI-backup-oc105-20261008`: the OpenCore 1.0.5 EFI before the update, including every old test config
- `EFI-backup-before-claude`
- `EFI-noedit`
