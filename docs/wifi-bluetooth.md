# Wi-Fi and Bluetooth

Card: Intel Wi-Fi 6E **AX211** CNVi, PCI `8086:7A70`, subsystem `8086:0094`. Bluetooth runs over USB.

## Wi-Fi: native AirportItlwm on Sequoia (current)

| Item | Value |
|---|---|
| Kext | `AirportItlwm.kext` **2.4.0-alpha**, Sequoia RELEASE build, from [laobamac/itlwm](https://github.com/laobamac/itlwm/releases) (release `v2.4.0-alpha`, commit `9bc4b4d`) |
| File | `AirportItlwm-Sequoia-v2.4.0-RELEASE-alpha-9bc4b4d.zip`, SHA-256 `53b4eba2fd67ba37ff850a0b5fb55a3012049b08cf4f15b7c73dac206aab5355` |
| Config | `Kernel/Add` entry enabled, `MinKernel 24.2.0`, `MaxKernel 24.99.99` (as the fork's README says). `itlwm.kext` disabled. |
| Root patches | **none.** No IOSkywalkFamily block, no OCLP. It uses macOS 15's own `IO80211Family` and `IOSkywalkFamily`. |
| Result | Wi-Fi in the macOS menu bar and System Settings, WPA2, private Wi-Fi address, firmware `68.01d30b0c.0`, no driver errors |

Why this route:
- The official OpenIntelWireless AirportItlwm stops at v2.3.0 (Sonoma 14.4).
- The usual Sequoia method uses OpenCore Legacy Patcher **root patches**: a Ventura `IOSkywalkFamily` + `IO80211FamilyLegacy`, a Kernel→Block, and `csr-active-config` `0x803`. That modifies the sealed system volume and rebuilds kernel collections, which risks breaking NullMoth's Auxiliary Kernel Collection, and it has to be redone after every macOS update.
- The laobamac fork builds AirportItlwm natively against Sequoia 15.2+. The method is described in [5T33Z0/OCLP4Hackintosh](https://github.com/5T33Z0/OCLP4Hackintosh/blob/main/Enable_Features/AirportItllwm_Sequoia.md) as "Method A".

Limits of this alpha:
- **Wi-Fi 6 off by default.** Wi-Fi 6 (802.11ax) is off, so the card reports a/b/g/n/ac. The boot-arg `itlwm_he=1` turns it on (not tested here).
- **Unsupported:** WPA3-only networks, networks that require PMF, AWDL/AirDrop and MLO.

Fallback: `config-identity.plist` uses **itlwm 2.3.0 + the HeliPort app**, which worked from day one.

## Bluetooth

| Kext | Version |
|---|---|
| IntelBluetoothFirmware | 2.5.0 |
| IntelBTPatcher | 2.5.0 |
| BlueToolFixup (BrcmPatchRAM) | 2.7.2 |

The controller is on and its firmware loads. Pairing hasn't been tested yet.
