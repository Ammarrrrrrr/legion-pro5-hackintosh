# Trackpad: Goodix GXTP5100 on Raptor Lake I2C

**Result:** full multitouch with gestures, in GPIO interrupt mode (`"Interrupt Mode" = "GPIO"`), with no I2C errors and normal idle CPU.

## The problem

The trackpad is a HID-over-I2C device (`PNP0C50`, ACPI `TPD0`). Two chips in the 14th-gen chipset sit between it and macOS:

| Part | ID | Status in VoodooI2C 2.9.1 (latest release) |
|---|---|---|
| I2C controller `I2C5` | PCI `8086:7A7D` | not in its PCI ID list, so nothing attaches |
| GPIO controller `GPI0` (carries the trackpad's interrupt line) | ACPI `INTC1085` | VoodooGPIO supports nothing newer than Tiger Lake-LP |

Upstream VoodooI2C and VoodooGPIO had no Alder Lake or Raptor Lake support, and no issues about it. The Legion EFI already had VoodooI2C enabled, with `SSDT-GPI0` and `SSDT-XOSI`, but VoodooI2CHID was disabled, so the trackpad never worked there.

## The fix

The kext is `EFI/OC/Kexts/VoodooI2C-RPL-GPIO.kext`: VoodooI2C 2.9.1 with two changes.

### 1. Add the I2C controller to VoodooI2C's "Lake" controller class

In `VoodooI2C-RPL-GPIO.kext/Contents/Info.plist`, personality `VoodooI2CPCILakeController`, key `IOPCIMatch`, append:

```
0x7a7d8086&0xFFFFFFFF
```

- **The base class doesn't work.** Putting the ID in the base `VoodooI2CPCIController` class instead makes the controller nub appear, but the controller driver never starts.
- **The Lake class does.** This came from an InsanelyMac guide for Tiger Lake and Alder Lake, which put `0xa0e8`/`0x51e8` in the Lake class. The Lake class also applies its "Current CPU is Comet Lake or Ice Lake, patching…" fix, because this EFI presents the CPU as an Ice Lake-family CPUID (see [opencore-efi.md](opencore-efi.md)).

`VoodooI2CHID.kext` (from VoodooI2C 2.9.1) is enabled as well.

With only this change and the boot-arg `-vi2c-force-polling`, the trackpad works in **polling mode**. The cursor jumped around when click-dragging windows.

### 2. Replace VoodooGPIO with a Raptor Lake-capable build for interrupt mode

Without forced polling, VoodooI2C reports that the trackpad's `_CRS`/`_DSM` offers **only a GPIO interrupt**:

```
VoodooI2CDeviceNub::TPD0 Found valid GPIO interrupts
VoodooI2CControllerDriver::TPD0 Could not find GPIO controller, exiting
```

- **The fork:** [victorwitkamp/VoodooGPIO](https://github.com/victorwitkamp/VoodooGPIO) commit **`b53f717`** (2026-09-22), "Add Alder Lake-S GPIO personality (INTC1085, INTC1056)".
- **What it adds:** a `VoodooGPIOAlderLakeS` class with the Linux `pinctrl-alderlake.c` "adls" tables: 304 pins, 5 communities, and register offsets PAD_OWN `0x0a0`, PADCFGLOCK `0x110`, HOSTSW_OWN `0x150`, GPI_IS `0x200`, GPI_IE `0x220`. It also makes the `GPI_IS` offset per-community.
- **Prior testing:** the author tested it on an ASUS ROG Strix G814JI (i9-13980HX, the same PCH) with VoodooI2C 2.9.1.
- **No binary release:** the fork has none, so it was **built locally**:
  - Apple Command Line Tools only, no Xcode
  - acidanthera MacKernelSDK
  - [`tools/trackpad/build-voodoogpio.sh`](../tools/trackpad/build-voodoogpio.sh)
- **Checks:** the build is an x86_64 kext bundle containing `VoodooGPIOAlderLakeS`, with exactly the same 303 undefined kernel symbols as the stock VoodooGPIO.
- **Installed as:** the plug-in `VoodooI2C-RPL-GPIO.kext/Contents/PlugIns/VoodooGPIO.kext`, and `-vi2c-force-polling` was removed.

```
VoodooI2CDeviceNub::TPD0 Got GPIO Controller! VoodooGPIOAlderLakeS
VoodooGPIOAlderLakeS::Successfully registered hardware pin 0x08 for GPIO IRQ pin 0x08
"Interrupt Mode" = "GPIO"
```

Build it again:

```bash
git clone https://github.com/victorwitkamp/VoodooGPIO.git      # commit b53f717
git clone --depth 1 https://github.com/acidanthera/MacKernelSDK.git
bash tools/trackpad/build-voodoogpio.sh VoodooGPIO MacKernelSDK out
# -> out/VoodooGPIO.kext (org.coolstar.VoodooGPIO 1.1); copy into VoodooI2C-RPL-GPIO.kext/Contents/PlugIns/
```

## Details

| Item | Value |
|---|---|
| Driver chain | `VoodooI2CPCILakeController` → `VoodooI2CControllerNub` → `VoodooI2CControllerDriver` → `TPD0` (`VoodooI2CDeviceNub`) → `VoodooI2CHIDDevice` → `VoodooI2CPrecisionTouchpadHIDEventDriver` → `VoodooInput` → Apple's multitouch driver |
| I2C | address `0x5D`, 400 kHz. ACPI has no `SSCN`/`FMCN`, so VoodooI2C uses its default bus timings, which work. |
| Interrupt | GPIO pin 8 on `GPI0` (`INTC1085`) |

## Dead ends

- **Base-class PCI ID:** the controller nub appears, but the driver doesn't start.
- **PS/2 fallback:** VoodooPS2Mouse and VoodooPS2Trackpad only time out on the PS/2 aux port. ACPI has no `PS2M`, so this touchpad has no PS/2 mode.
- **[ndh0408/Hackintosh-Y9000P](https://github.com/ndh0408/Hackintosh-Y9000P):** the same CPU and GPU, but stock kexts and an untested config. Nothing usable.

## Debugging technique that made this possible

Kexts injected by OpenCore never write to `log show`, and NullMoth's log spam overwrites the 128 KB kernel buffer within seconds. A small LaunchDaemon that saves `/sbin/dmesg` every second for the first 25 s of boot captured VoodooI2C's messages. See [debugging-notes.md](debugging-notes.md) and [`tools/diagnostics/boot-dmesg/`](../tools/diagnostics/boot-dmesg/).
