# Timeline

## 2026-10-07 (from Windows)

1. **Starting point:** macOS 15.8.1 is installed. The stick holds the `efi_legion-main` EFI, made for Hybrid GPU mode, and the BIOS is set to Discrete so the NVIDIA GPU drives the panel.
2. **Boot hang found:** NootedBlue panics without an iGPU (`videoBuiltin is not IOPCIDevice`). NootedBlue disabled, `disable-gpu` removed from the RTX 4060, NullMoth boot-args and `csr-active-config` 0xA43 added.
3. **NullMoth 1.0.1 installed:** the desktop never comes up.
   - With the small BAR, the driver falls back to a 100 s start delay but holds WindowServer for only 40 s (`FB: 0 of 0 opened`).
   - Early starts and full-BAR settings hang.
   - Only Safe Mode with the driver parked gives a desktop.
4. **NullMoth 1.0.6 installed** (`nullmoth-update.sh`). It fixes the hold timing, so `nvrmsettle=100000` gives the first accelerated desktop. Boot takes about 2½ minutes.

## 2026-10-08 (from macOS)

1. **Verified:** 4 kexts, Metal 3, Wi-Fi via itlwm + HeliPort, Bluetooth, audio devices, camera, battery.
2. **Found:** with 1.0.6 the driver resizes BAR1 64 MB → 8 GB by itself, so the 100 s delay is only the `nvrmsettle` override.
3. **Trackpad, first attempt:** VoodooI2C copy with the I2C5 ID in the base class. Its controller driver never started. Two diagnostic boots couldn't capture its log.
4. **Boot time cut down:**
   - `nvrmsettle=20000`: login screen at about 66 s
   - no `nvrmsettle`, picker timeout 3 s, OpenCore file logging off: about 41 s
5. **Sleep tested:** the GPU is lost on wake. System sleep disabled with `pmset`.
6. **NullMoth driver updated to 1.0.9.**
7. **Trackpad fixed in two steps:**
   - The I2C5 ID in the **Lake** controller class, with the boot-dmesg LaunchDaemon to see the log. Works in polling mode, but jumpy.
   - VoodooGPIO built from the victorwitkamp fork (`INTC1085`). Works in GPIO interrupt mode.
8. **Changing resolution:** freezes the whole system. Documented as a driver bug.
9. **Webcam:** black everywhere because the physical E-shutter switch was closed. With it open QuickTime works, but Photo Booth doesn't (Core Image `ShaderWrite`).
10. **Mac identity:** own serial generated with macserial, `CustomSMBIOSGuid` enabled, Apple ID signed in.
11. **Internal-drive boot:** kit prepared but skipped.
12. **Shutdown stalls:** investigated, harmless.
13. **OpenCore and kexts updated:** OpenCore 1.0.5 → 1.0.8, plus Lilu, VirtualSMC, AppleALC, CpuTscSync, BlueToolFixup, USBToolBox and RealtekRTL8111. `ocvalidate` clean.
14. **NullMoth bug report** written for their Discord ([`reports/nullmoth/`](../reports/nullmoth/)).
15. **240 Hz:** three EDID-override versions tested, none reached the driver. Needs a NullMoth change.
16. **Clean-up:** test configs, logs and kits moved to the Trash; boot-dmesg job removed.
17. **NullMoth update check:** packages 1.0.10 and 1.0.11 have byte-identical driver files, so no update.
18. **RAM:** `SystemMemoryStatus Upgradable`.
19. **Native Wi-Fi:** AirportItlwm 2.4.0-alpha (laobamac fork, Sequoia build, no root patches). Works.
20. **This repository created.** Pushed to a private GitHub repository.
21. **Unused kexts removed:** six kexts that no config enabled, and the stock VoodooI2C after `config-safe-nvoff.plist` was switched to the working trackpad kexts.
22. **YogaSMC 1.5.3** added (`config-yogasmc.plist`): Lenovo Fn-lock, battery conservation and rapid charge.
23. **RGB keyboard:** internal USB port 1 (ITE `048d:c995`, 4-zone RGB) added to `UTBMap.kext` in place of the `SS06` USB 3 lane. Lighting app `~/legion-rgb` written: a Swift port of L5P-Keyboard-RGB with a menu bar app and the `legionrgb` CLI.
24. **RGB reset loop:** macOS kept resetting the controller because of its input-less interface 1; `LegionRGBUSBFix.kext` added (`config-rgbfix.plist`). The app now uses USB control transfers, so it needs no Input Monitoring.
25. **Fast boot:** debug boot-args removed, `-nvrmnobootscreen` added, picker hidden (`config-fastboot.plist`). Login window at 16 s instead of 39 s after kernel start.
26. **YogaSMC for the Legion (2026-10-09):** stock YogaSMC 1.5.3 found no sensors because this BIOS no longer implements the old Game Zone fan and temperature methods. Patched YogaSMC to use the interfaces LenovoLegionToolkit uses (`LENOVO_OTHER_METHOD` capabilities, Game Zone smart fan mode), built it without Xcode and added it as `YogaSMC-Legion.kext` (`config-yogasmc-legion.plist`). Fans, CPU/GPU/PCH temperatures, power mode switching, the Fn+Q popup and the menu bar section verified.
27. **YogaSMC pane (2026-10-09):** Legion tab added to the System Settings pane; fixed the pane crashing on its second opening (also in stock 1.5.3) and the never-connected rapid charge checkbox; rapid charge shown as unavailable while the EC disallows it. Kext, app and pane now 1.6.1 (kext active after the next reboot).
28. **YogaSMC-Legion repository:** private GitHub repository with the full source, a Legion README and release v1.6.1 (kext, menu bar app, pane, CLI tools, SHA-256 sums).
29. **YogaSMC 1.6.2:** power modes read from the firmware like LLT (adds Extreme on this laptop), `LENOVO_FAN_METHOD` as an extra sensor source for other Legions, compatibility notes in the README. Verified after a reboot (all five modes reported, Extreme switches, sensors unchanged); release v1.6.2 is the latest on GitHub.
