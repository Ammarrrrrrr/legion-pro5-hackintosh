# Camera, audio, memory, USB

## Camera

USB UVC "Integrated Camera" (Luxvisions `0x30C9:0x00AC`), 1080p MJPEG at 30 fps.

- **Black picture in every app at first:** caused by the laptop's **physical E-shutter switch** on the side of the chassis. With it closed, the camera still streams, but every frame is black.
- **With the switch open:** QuickTime (File → New Movie Recording), FaceTime and browsers work.
- **Photo Booth stays black (NullMoth driver gap).** Frames arrive, but Core Image refuses to draw them:
  ```
  -[CIRenderDestination initWithMTLTexture:commandBuffer:] texture usage must include MTLTextureUsageShaderWrite.
  -[CIContext(CIRenderDestination) …] The destination is nil.
  ```
- **Software decoding only:** there's no hardware video decode (`AppleGVA: no plugin`), because the iGPU is off. UVCAssistant's sandbox also blocks loading the NVIDIA Metal plug-in. The camera still works through the software path.
- **Diagnostic tool:** [`tools/diagnostics/camera/grab.swift`](../tools/diagnostics/camera/grab.swift) grabs frames without drawing them and reports their brightness. Build it with `swiftc -O grab.swift -o grab` and run it from Terminal.app, which needs camera permission.

## Audio

AppleALC 1.9.8 with `layout-id 99` on `Pci(0x1f,0x3)`. Internal speakers and microphone are present. The headphone jack hasn't been tested yet.

## Memory

- **Detected from the firmware:** macOS reads the real modules straight from the firmware SMBIOS. `CustomMemory` is false and there's no custom memory table. It reports 2 × 16 GB Samsung DDR5-5600 (M425R2GA3PB0-CWM) with their real serials.
- **Upgradeable flag:** `SystemMemoryStatus` changed from `Auto` to `Upgradable`. MacBookPro16,4 has soldered RAM, so `Auto` reported "Upgradeable Memory: No".
- **"Type: RAM":** macOS shows this because no Intel Mac ever had DDR5. It's left as is rather than faking a type.

## USB

USBToolBox 1.2.0 with `UTBMap.kext` (the Legion EFI's port map). The camera, Bluetooth, the ITE keyboard controller, the USB stick and a USB mouse all enumerate.

**RGB keyboard controller (2026-10-08):** the 4-zone lighting is a separate ITE controller, `048d:c995` (HID usage `0xFF89:0xCC`), on **internal port 1**. The original map left that port out, so macOS only saw the keys controller `048d:c106`. Windows confirmed the port: `C:\Windows\INF\setupapi.dev*.log` lists `USB\VID_048D&PID_C995\5&14d9a93&0&1`, and the trailing `1` is the root hub port. The map was already at the 15-port limit, so one USB 3 lane was given up:

- added `HS10` = port `<01000000>`, `UsbConnector` 255 (internal)
- removed `SS06` = port `<18000000>`: one USB-A socket now runs at USB 2 speed in macOS only
- `port-count` `<18000000>` → `<15000000>`

The previous map is on the stick at `rgb/backup/UTBMap-Info.plist.before-rgb-20261008`. The lighting app is in `~/legion-rgb`, published privately as [Ammarrrrrrr/legion-rgb-macos](https://github.com/Ammarrrrrrr/legion-rgb-macos) (a Swift port of L5P-Keyboard-RGB: menu bar app, `legionrgb` CLI and a step-by-step guide).

**Reset loop (2026-10-08):** once visible, `c995` re-enumerated about every 0.6 s, also in Hackintool. Its interface 1 (HID `ffc2:04`, feature and output reports only) has an interrupt IN endpoint `0x82`. macOS polls it, every read fails with `0xe00002ed` (transaction error), and after 10 retries 50 ms apart IOUserUSBHostHIDDevice resets the device. Fix: `LegionRGBUSBFix.kext`, a codeless kext that matches that interface (`idVendor 1165`, `idProduct 51605`, `bConfigurationValue 1`, `bInterfaceNumber 1`, probe score 100000) with a plain `IOService`, so Apple's HID driver never polls it. On the stick it is `Kernel.Add` 31 of `config.plist` (= `config-rgbfix.plist`); the previous config is `config-yogasmc.plist`.

**No Input Monitoring needed:** interface 0 also carries a boot keyboard collection, so `IOHIDDeviceOpen` on it needs Input Monitoring. The app instead sends HID `SET_REPORT` as a USB control transfer through IOUSBLib (`DeviceRequestTO`, no device open), which needs no permission.
