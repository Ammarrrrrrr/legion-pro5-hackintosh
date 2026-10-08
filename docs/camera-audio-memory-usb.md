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
