**NullMoth on a laptop: Legion Pro 5 16IRX9, RTX 4060 Laptop (10DE:28E0, subsys 17AA:3CF2)**
macOS 15.8.1 · driver 1.0.9 (manual install.sh) · OpenCore 1.0.8 · BIOS GPU mode Discrete (MUX), internal eDP 2560×1600 on DP-4

**Works**
• Boots with Metal 3 on the internal panel, ~41 s to login
• NVRM resizes BAR1 64 MB → 8 GB itself and starts with the default 500 ms settle (1.0.1 needed nvrmsettle=100000 here)
• Display sleep, camera in QuickTime/browsers

**Bugs**
1. **System sleep → GPU lost** (1.0.6): `Xid 79: GPU has fallen off the bus` on resume, then `NV_ERR_GPU_IS_LOST`, VRAM alloc refused, black screen, WindowServer watchdog panic. Display-only sleep is fine. Workaround: `pmset disablesleep 1`.
2. **Changing resolution freezes the whole Mac** (1.0.9): every mode macOS offers is 1× on the 2560×1600 raster, so any other pick takes the scaled path. Last driver line is `getAttribute 'mrdf'`, then all logging stops. Hard reset.
3. **Photo Booth stays black** (1.0.9): Core Image rejects the drawable: `texture usage must include MTLTextureUsageShaderWrite` → `The destination is nil`. QuickTime works.
4. **No brightness control** on the eDP panel (no backlight device).

**Requests**
• 240 Hz: the panel lists 240 Hz only as a DisplayID 2.0 Type VII timing (1175.04 MHz), which macOS ignores, so only 60 Hz reaches NVRMFB. EDID overrides can't fix it (tested a classic DTD, DisplayID 1.3 and a CTA Type VII block; none reach NVRMFB). Publishing NVKMS's EDID mode list would expose it.
• Less `kapi event type 5` logging (~150 lines/s, fills dmesg in ~18 s)

Full report with log excerpts attached. Happy to test builds on this laptop.
