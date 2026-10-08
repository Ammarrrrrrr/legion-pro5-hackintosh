# Hardware

| Component | Detail |
|---|---|
| Laptop | Lenovo Legion Pro 5 16IRX9, machine type 83DF |
| BIOS | N0CN29WW |
| CPU | Intel Core i9-14900HX (Raptor Lake-HX), 8 P-cores + 16 E-cores, 32 threads |
| Chipset | HM770 (Raptor Lake-S/HX PCH, the same PCH family as Alder Lake-S) |
| GPU | NVIDIA GeForce RTX 4060 Laptop GPU, 8 GB, PCI `10DE:28E0` rev A1, subsystem `17AA:3CF2`, PCIe x8, at `PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)` |
| Internal panel | BOE NE160QDM-NZB, 16", 2560×1600, 60 Hz and 240 Hz (EDID vendor `0x09E5`, product `0x0C8B`), eDP, driven by the NVIDIA GPU on connector `DP-4`, SOR 1 |
| Memory | 2 × 16 GB Samsung DDR5-5600 SO-DIMM (M425R2GA3PB0-CWM), user-replaceable |
| Storage | Samsung NVMe 1 TB (MZVL21T0HCLR). Windows on partition 3; macOS APFS container on partition 6; spare 1 GB EFI partition 5 |
| Wi-Fi / Bluetooth | Intel Wi-Fi 6E AX211 CNVi, PCI `8086:7A70` subsystem `8086:0094`, Bluetooth over USB |
| Ethernet | Realtek RTL8111-family, PCIe |
| Trackpad | Goodix GXTP5100 (ACPI `TPD0`, `PNP0C50`, HID-over-I2C, VID `0x27C6` PID `0x01E0`), I2C address `0x5D` on `I2C5` = PCI `8086:7A7D` (`Pci(0x19,0x1)`), interrupt on a GPIO pin of `GPI0` (ACPI `INTC1085`) |
| Keyboard | PS/2 (ACPI `PS2K`), ITE 8910 USB RGB controller |
| Camera | "Integrated Camera", USB UVC, vendor `0x30C9` product `0x00AC` (Luxvisions), 1080p MJPEG, physical E-shutter switch on the side of the chassis |
| Audio | Intel HDA (`Pci(0x1f,0x3)`), AppleALC layout-id 99 |
| Battery | internal, read through the EC (SMCBatteryManager). Lenovo conservation mode (set in Vantage on Windows) stops charging at about 80%. |

## BIOS settings

| Setting | Value | Why |
|---|---|---|
| GPU mode | **Discrete** (MUX to dGPU) | The panel must be wired to the NVIDIA GPU. In Hybrid it's on the Intel iGPU, which macOS can't drive. |
| Secure Boot | Off | |
| Boot mode | UEFI | |
| Resizable BAR / Above 4G | effectively on (Windows shows an 8 GB BAR1) | In macOS the firmware leaves BAR1 at 64 MB and the NVIDIA driver resizes it itself. |
| VT-d | On | handled by OpenCore's `DisableIoMapper` |

No other BIOS changes were needed.
