Legion Pro 5 16IRX9 trackpad (Goodix GXTP5100, I2C5 = PCI 8086:7a7d, GPIO controller INTC1085)

- VoodooI2C 2.9.1 + 0x7a7d8086 added to the VoodooI2CPCILakeController personality
  (first test kext, polling mode only, cursor jumpy - removed; the kext below includes the same patch)
- same + VoodooGPIO built from github.com/victorwitkamp/VoodooGPIO @ b53f717
  ("Add Alder Lake-S GPIO personality (INTC1085, INTC1056)")
  = EFI/OC/Kexts/VoodooI2C-RPL-GPIO.kext       (GPIO interrupt mode)
  build: bash build-voodoogpio.sh <VoodooGPIO clone> <MacKernelSDK clone> <out>  (Command Line Tools, no Xcode)
  copy of the built plugin: VoodooGPIO-AlderLakeS-build.kext

Configs (EFI/OC): config-fast-trackpad-gpio.plist = interrupt mode (the polling-only test config was removed),
config-safe-nvoff.plist = Safe Mode recovery with stock VoodooI2C.
