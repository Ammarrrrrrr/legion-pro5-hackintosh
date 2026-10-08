# NullMoth on a Legion Pro 5 16IRX9 (RTX 4060 Laptop)

Field report for the NullMoth NVIDIA driver, 2026-10-08. The driver boots with full Metal acceleration on the laptop's internal panel. Four problems remain. All of them reproduce, and each one below has its log excerpt.

## Setup

| | |
|---|---|
| Laptop | Lenovo Legion Pro 5 16IRX9 (83DF), BIOS N0CN29WW |
| CPU / chipset | Intel Core i9-14900HX, HM770 (Raptor Lake-HX) |
| GPU | GeForce RTX 4060 Laptop, 10DE:28E0 rev A1, subsystem 17AA:3CF2, 8 GB, PCIe x8, `PciRoot(0x0)/Pci(0x1,0x0)/Pci(0x0,0x0)` |
| Display routing | BIOS GPU mode **Discrete** (MUX to the dGPU, iGPU off). Internal eDP panel BOE NE160QDM-NZB, 2560×1600, 60/240 Hz, on `DP-4`, SOR 1 |
| macOS | 15.8.1 (24H32) |
| Driver | package 1.0.9, manual `pkgroot/install.sh` (history 1.0.1 → 1.0.6 → 1.0.9) |
| OpenCore | 1.0.8 (tests before the update ran on 1.0.5), SMBIOS MacBookPro16,4, csr 0xA43 |
| BAR settings | `ResizeGpuBars -1`, `ResizeAppleGpuBars 0`, no IONDRVSupport block (firmware leaves BAR1 at 64 MB, NVRM resizes it) |
| Boot-args | `nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80` + `-v keepsyms=1 debug=0x100` |

## Status

| Area | Result | Driver |
|---|---|---|
| Boot with Metal 3 on the internal panel | Works | 1.0.6, 1.0.9 |
| Default GPU start (no `nvrmsettle`) | Works | 1.0.6+ |
| Display sleep (screen off/on) | Works | 1.0.6 |
| Camera in QuickTime / browsers | Works | 1.0.9 |
| System sleep and wake | **GPU lost on wake** | 1.0.6 |
| Changing the resolution | **Whole system freezes** | 1.0.9 |
| Core Image drawing (Photo Booth) | **Black output** | 1.0.9 |
| Brightness control | Missing | 1.0.9 |
| 240 Hz on the internal panel | Not offered | 1.0.9 |
| External displays (HDMI) | Not tested yet | – |

## What works well

On 1.0.6 and later, NVRM grows BAR1 from 64 MB to 8 GB itself and starts with its default 500 ms settle. Version 1.0.1 needed `nvrmsettle=100000` here and still lost the WindowServer race (`FB: 0 of 0 opened`). The login screen appears about 41 s after the kernel starts.

```
[NVRM-xnu] bar1: Resizable BAR capability @0xbb0 says BAR1 = 64 MB (sizes supported mask 0x3fc0)
[NVRM-xnu] bar1: host bridge 64-bit window 0x4000000000-0x7fffffffff (ACPI _CRS), CPU reaches 39 bits
[NVRM-xnu] bar1: PLACED — BAR1 8192 MB live at 0x7c00000000
[NVRM-xnu] auto-go: go(2) in 500 ms on its own thread (BAR1 placed outside the console)
[NVKMS]    GPU:0: TAKEOVER boot head 0: firmware displayId 0x2000 -> connector DP-4, SOR 1
[NVRM-fb]  VIDMEM ACCEPTED -- aperture 0x7c00200000
```

## Bug 1: System sleep, the GPU falls off the bus on wake (1.0.6)

- **Steps:** Apple menu → Sleep, or let the laptop idle-sleep. Wake with a key.
- **Result:** the screen stays black and the system freezes about 70 s after wake. WindowServer's watchdog then panics. A scheduled maintenance wake does the same thing.
- **Not affected:** display-only sleep. `NVRM-fb: setPowerState 0` and `1` work without errors.
- **Workaround:** `sudo pmset -a disablesleep 1 sleep 0 standby 0 hibernatemode 0`

```
07:54:30.110 PMRD: power clamp enabled NVRMFramebuffer, pendingCap 0x0, ps 0
07:54:30.114 PMRD: System Sleep
07:54:30.201 NVRM: Xid 79: GPU has fallen off the bus.
07:54:30.227 NVRM: krcRcAndNotifyAllChannels_IMPL: RC all channels for critical error 79.
07:54:30.268 NVRM: Xid 154: GPU recovery action changed from 0x0 (None) to 0x1 (PF FLR)
07:54:35.972 PMRD: System Wake
07:54:35.973 NVRM: _issueRpcAndWait: rpcSendMessage failed with status 0x0000000f for fn 78
07:54:35.973 NVRM: Check failed: GPU lost from the bus [NV_ERR_GPU_IS_LOST] (0x0000000F)
07:54:35.975 NVRM-xnu: STUB os_is_bif_reset_supported
07:54:36.010 NVRM-fb: setPowerState 1
07:54:36.012 NVKMS-rm: ALLOC class 0x40 parent 0x10001 -> status 0x26
07:54:36.012 NVRM-fb: nvAllocVram(262144): allocateMemory failed
07:54:36.012 NVAccel: NVVidMemory::allocPhysical(): 245760 bytes REFUSED by the framebuffer (0xe00002bd)

panic: userspace watchdog timeout: no successful checkins from WindowServer (2 induced crashes) in 120 seconds
```

Log timestamps don't advance during S3, so the Xid 79 line shows the sleep-entry time even though it was logged on resume. The GPU loses power in S3 and the GSP state with it. Either a resume path that re-runs GSP boot, or an assertion that blocks system sleep while the driver owns the GPU, would avoid the hard reset. Not retested on 1.0.9 yet.

## Bug 2: Changing the resolution freezes the whole system (1.0.9)

- **Steps:** System Settings → Displays → pick any resolution other than 2560×1600.
- **Result:** the screen goes black with the cursor still visible. About 0.3 s later every process stops logging. A hard reset is needed, and the new mode is not saved.
- **Context:** all 13 modes macOS offers are 1×, with pixels equal to points, and all use the same 2560×1600 raster with a different desktop size. Every choice except native goes through the scaled-mode path. No `switchMode` line is logged before the freeze.

```
at boot      NVRM-fb: fbmodes: boot raster 2560x1600 pitch 10240; scanout allocation sized for 3840x2160 (32448 KB, boot needs 16000 KB)
at boot      NVRM-fb: fbmodes: published IOFBScalerInfo (up+down, max 3840x2160) + IOFBTimingRange (25 MHz..1.2 GHz, 23..240 Hz)
at boot      NVRM-fb: fb0 setDetailedTimings: 18 timing(s) installed (0 malformed, 18 offered), current 0x1, EDID matches so far 21

17:40:07.943 NVRM-fb: getAttribute 'mrdf' -> 0xe00002c7 val 0
17:40:08.252 (last line in the unified log, from any process)
```

## Bug 3: Core Image cannot draw into Metal drawables, so Photo Booth stays black (1.0.9)

- **Steps:** open Photo Booth.
- **Result:** the camera streams and frames reach the app, but the preview is black. QuickTime (New Movie Recording) and browser previews work.
- **Likely cause:** the drawable's texture does not include `MTLTextureUsageShaderWrite`, which Core Image needs to render straight into it. Other Core Image apps that draw into a layer are probably affected too.

```
Photo Booth: -[CIRenderDestination initWithMTLTexture:commandBuffer:] texture usage must include MTLTextureUsageShaderWrite.
Photo Booth: -[CIContext(CIRenderDestination) _startTaskToRender:toDestination:forPrepareRender:forClear:error:] The destination is nil.
```

## Bug 4: No brightness control on the internal panel

macOS has no backlight device (`AppleBacklightDisplay` count 0), so there is no brightness slider and the brightness keys do nothing. With the MUX set to Discrete, the dGPU drives the eDP backlight. Exposing eDP backlight control through the framebuffer (DPCD AUX or PWM) would give macOS its brightness control back.

## Feature request: 240 Hz

The panel's base EDID block lists only 2560×1600 at 60 Hz (293.76 MHz). The 240 Hz mode exists only as a DisplayID 2.0 Type VII timing: 2560×1600, 1175.04 MHz, totals 2720×1800, with an adaptive-sync range of 48–240 Hz. macOS ignores that block, so only 60 Hz timings ever reach NVRMFB, even though NVRMFB publishes a 23–240 Hz timing range. NVRMFB already checks rasters against NVKMS's EDID modes, and NVKMS parses DisplayID 2.0. Publishing NVKMS's own mode list as detailed timings would bring 240 Hz into macOS. At 8 bpc that mode is about 28 Gbps against 25.9 Gbps for HBR3 ×4, so it probably needs DSC on this eDP link.

A display override can't work around this. I tested patched EDIDs in `/Library/Displays/Contents/Resources/Overrides` over three boots. macOS applied each override's display name, but none of its timings reached NVRMFB:

| Timing added by the override | Encoding | Sent to NVRMFB |
|---|---|---|
| 2560×1600 @ 120 Hz, 587.52 MHz (range limits widened to 100–440 kHz) | base-block detailed timing | No |
| 2560×1600 @ 100, 144 and 240 Hz | DisplayID 1.3 Type I | No |
| 2560×1600 @ 240 Hz, 1175.04 MHz | CTA-861 Type VII Video Timing Data Block | No |

On every boot all 42 `validateDetailedTiming` calls carried `pclk 293760000`. macOS builds this panel's mode list only from the driver's boot raster and its scaled variants, so a 240 Hz option has to come from NVRMFB's own mode list.

## Other observations

- **Log volume:** `NVRM-fb: kapi event type 5` is logged about 150 times a second while the desktop is active. It fills the 128 KB kernel message buffer in about 18 s, which makes `dmesg` useless for debugging other drivers.
- **Idle CPU:** WindowServer uses about 50% of one core on an idle desktop.
- **Chipset not in RM's table**, logged on every boot with no visible effect: `clFindFHBAndGetChipsetInfoIndex_IMPL: NVRM : This is Bad. FHB/P2P/3DCTRL not found in cached bus topology!!!`, then asserts at `chipset.c:462` and `:557`.
- **New in 1.0.9:** `NVRM-xnu: PV-SENTINEL REFUSED: slid _pmap_verify_free text != BootKC 24G830 bytes (kernel or KC differs)`. OpenCore injects kexts into the boot KC here.
- **When apps start:** `NVRM: GPU0 chandesConstruct_IMPL: bad class 0xc7b5`.
- **Camera service sandbox:** UVCAssistant cannot load the Metal plugin (`Error loading /Library/GPUBundles/NVMTLDriver.bundle … file system sandbox blocked mmap()`). The camera still works through the software path.
- **Hardware video encoder:** the 1401 app turns it off for RTX 40 cards from 1.0.11 on, but a manual `install.sh` setup doesn't get that change. Is there a switch to set it by hand?

Logs come from macOS's unified log and `/Library/Logs/DiagnosticReports` on this machine. I can test more builds on this laptop on request.
