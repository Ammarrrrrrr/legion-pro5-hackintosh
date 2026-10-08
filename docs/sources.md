# Sources

Every external component, where it came from and how it was verified. SHA-256 values are the GitHub release asset digests, and each matched the downloaded file.

## Downloaded and installed on 2026-10-08

| Component | Version | File | SHA-256 | Source |
|---|---|---|---|---|
| OpenCore | 1.0.8 | `OpenCore-1.0.8-RELEASE.zip` | `2011e8b7216ecb2645d97ea710df965947edd406846e92050b9bc4190be6d27b` | https://github.com/acidanthera/OpenCorePkg/releases |
| Lilu | 1.7.2 | `Lilu-1.7.2-RELEASE.zip` | `53967d7dcfaab01023a33df2e969a89522f13d6654a6a56ac4711b62dabf3ab8` | https://github.com/acidanthera/Lilu/releases |
| VirtualSMC (+ SMC plugins) | 1.3.8 | `VirtualSMC-1.3.8-RELEASE.zip` | `2e29a8aaf91b4eb0bcdf5913ed17e70f5cf76531122acd4132eff7813a54de8b` | https://github.com/acidanthera/VirtualSMC/releases |
| AppleALC | 1.9.8 | `AppleALC-1.9.8-RELEASE.zip` | `d4d36cd2da7863cf7cbfcb0892d45c08457f4f4ddd065a073dd010e46bd63bcb` | https://github.com/acidanthera/AppleALC/releases |
| CpuTscSync | 1.1.2 | `CpuTscSync-1.1.2-RELEASE.zip` | `bc289f780c52015ae788827b3db8e6c2ab9f512992b3a157a4a5c15df1eb4ed3` | https://github.com/acidanthera/CpuTscSync/releases |
| BlueToolFixup (BrcmPatchRAM) | 2.7.2 | `BrcmPatchRAM-2.7.2-RELEASE.zip` | `e1c1c55347526d031a8ae2fdd1f52efa3019161e497fb38e1cfa809752f8af21` | https://github.com/acidanthera/BrcmPatchRAM/releases |
| USBToolBox | 1.2.0 | `USBToolBox-1.2.0-RELEASE.zip` | `c315a3a5acfd496dd97d0d19b4fbd1d487103d2fd541c5651583d4c9cebcfe07` | https://github.com/USBToolBox/kext/releases |
| RealtekRTL8111 | 3.0.0 | `RealtekRTL8111-V3.0.0.zip` | `a0f2e64ac3c76e2d416ff88f35a197ce229e74ea78e968631a736a43b4d8231c` | https://github.com/Mieze/RTL8111_driver_for_OS_X/releases |
| NullMoth driver | package 1.0.9 (release v1.0.14) | `nullmoth-nvidia-1.0.9.tar.gz` | `9dbfdb1b1359e2ef4166a46905ee195774b0b4ba20be083a8111ef550b1e5789` | https://github.com/nullmoth/nvidia-macos-driver/releases |
| NullMoth driver (rollback) | package 1.0.6 (release v1.0.9) | `nullmoth-nvidia-1.0.6.tar.gz` | `25fdedc727b4ee3792ff5439d056d79f362219c77e5a3f2bdd35e054429229cf` | same |
| AirportItlwm (Sequoia) | 2.4.0-alpha (`9bc4b4d`) | `AirportItlwm-Sequoia-v2.4.0-RELEASE-alpha-9bc4b4d.zip` | `53b4eba2fd67ba37ff850a0b5fb55a3012049b08cf4f15b7c73dac206aab5355` | https://github.com/laobamac/itlwm/releases |
| YogaSMC (kext) | 1.5.3 | `YogaSMC-Release.zip` | `d212edf601a6f7722f60e63a572ed3e689430d89fdae8a0f5365c8d6f799768e` | https://github.com/zhen-zen/YogaSMC/releases (no published digest for this 2022 release; hash taken after download) |
| YogaSMC (apps) | 1.5.3 | `YogaSMC-App-Release.dmg` | `48a664f67f0523fd8e2ed572ceb504debe318778a777a726a9882178e0e967e7` | same |
| Lilu SDK (for building YogaSMC, 2026-10-09) | 1.7.2 | `Lilu-1.7.2-DEBUG.zip` | `e95df95d82e8b151047abf359ecd9c853755c59293e19dfcc3907da8fbd8cf89` | https://github.com/acidanthera/Lilu/releases |
| VirtualSMC SDK (for building YogaSMC, 2026-10-09) | 1.3.8 | `VirtualSMC-1.3.8-DEBUG.zip` | `d1a13a4ad5564f97d4fa4cb584eaa63cb4fbe280c6997100133789dd4bdac200` | https://github.com/acidanthera/VirtualSMC/releases |
| iasl (from MaciASL, 2026-10-09; `iasl-stable` 20200925) | 1.6.5 | `MaciASL-1.6.5-RELEASE.dmg` | `67071f4e91167360e4881ed2532cf6cc3cdcc4850b1ccbcaf4e13f270465f878` | https://github.com/acidanthera/MaciASL/releases |

## Built from source on this machine (Command Line Tools)

| Component | Source | Revision | How |
|---|---|---|---|
| VoodooGPIO with `VoodooGPIOAlderLakeS` (`INTC1085`) | https://github.com/victorwitkamp/VoodooGPIO | `b53f717` (2026-09-22) | `tools/trackpad/build-voodoogpio.sh` with acidanthera MacKernelSDK (master, cloned 2026-10-08) |
| macserial | https://github.com/acidanthera/OpenCorePkg (`Utilities/macserial`) | `963025f` (2026-09-30) | `make` |
| YogaSMC 1.6.1 Legion build (kext, YogaSMCNC app, YogaSMCPane) | https://github.com/zhen-zen/YogaSMC + the two patches in `tools/yogasmc/` | `299907b` (2024-05-05) | `Tools/build-kext.sh` / `build-app.sh` / `build-pane.sh` from the patches, with MacKernelSDK `3f75008` (2026-09-23) and the SDK kexts below; see [tools/yogasmc/](../tools/yogasmc/) |
| `yogactl`, `smckeys` | `tools/yogasmc/` | this repository | `clang` (see the README there) |

## Modified

| Component | Base | Change |
|---|---|---|
| `VoodooI2C-RPL-GPIO.kext` | VoodooI2C 2.9.1 (https://github.com/VoodooI2C/VoodooI2C/releases, as shipped in the Legion EFI) | `0x7a7d8086&0xFFFFFFFF` added to the `VoodooI2CPCILakeController` `IOPCIMatch`; VoodooGPIO plug-in replaced by the build above |

## Unchanged from the base EFI (`efi_legion-main`)

- **acidanthera:** NVMeFix 1.1.3, RestrictEvents 1.1.6, VoodooPS2Controller/Keyboard 2.3.8, BrightnessKeys 1.0.4
- **b00t0x:** CpuTopologyRebuild 2.0.2
- **OpenIntelWireless:** IntelBluetoothFirmware and IntelBTPatcher 2.5.0, itlwm 2.3.0 (now the fallback)
- **USB map:** UTBMap 1.1
- **ACPI:** all SSDTs
- **Other:** `HfsPlus.efi`, OpenCanopy theme resources

## References used

- NullMoth README, `docs/HOW-IT-WORKS.md`, `docs/CARD-SUPPORT.md`, and issues #15, #23, #26
- InsanelyMac guide "Enabling I2C Touchpad … Tiger Lake / Alder Lake (Polling mode only)": the Lake controller class idea
- 5T33Z0/OCLP4Hackintosh `AirportItllwm_Sequoia.md`: the root-patch-free AirportItlwm method
- Linux `drivers/pinctrl/intel/pinctrl-alderlake.c`: the GPIO tables used by the VoodooGPIO fork
- Dortania OpenCore Install Guide: SMBIOS and iServices
