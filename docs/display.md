# Display: resolution, refresh rate, brightness

The internal panel runs at **2560×1600 @ 60 Hz**: the firmware's mode, which the NVIDIA driver keeps at takeover.

## Changing resolution freezes the system (driver bug)

- **Steps:** System Settings → Displays → any resolution other than 2560×1600.
- **Result:** the screen goes black with only the cursor visible. About 0.3 s later every process stops logging. Only a hard reset recovers. The bad mode isn't saved.
- **Why:** every mode macOS offers here is **1×** (pixels = points), all on the same 2560×1600 raster with different desktop sizes, so every non-native choice uses NVRMFB's scaled-mode path. The last driver line before the freeze is `NVRM-fb: getAttribute 'mrdf' -> 0xe00002c7`; no `switchMode` result is logged.
- **Workaround:** leave the resolution at the default. Make text bigger with System Settings → Accessibility → Display → Text Size, or zoom inside apps.

### HiDPI idea (prepared, not tested)

[`tools/experiments/hidpi-override/`](../tools/experiments/hidpi-override/) contains a display override with `scale-resolutions`. Its backing sizes 2560×1600, 2880×1800, 3200×2000 and 3360×2100 appear as "looks like" 1280×800, 1440×900, 1600×1000 and 1680×1050. "Looks like 1280×800" keeps the native raster and might avoid the scaler. The others still need it and may freeze. `test-hidpi.sh` switches for the current session only and reverts after 15 s.

## 240 Hz: not possible without a driver change

The panel's EDID (384 bytes, BOE NE160QDM-NZB):
- **Base block:** a single detailed timing, 2560×1600 @ 60 Hz (293.76 MHz, totals 2720×1800). Its range-limits descriptor allows 60–240 Hz but only a 432 kHz line rate.
- **CTA-861 block:** colorimetry and HDR static metadata only.
- **DisplayID 2.0 block:**
  - Type VII timing 2560×1600 @ **240 Hz** (1175.04 MHz, same blanking)
  - dynamic timing range 60–240 Hz
  - adaptive-sync ranges
  - an AMD FreeSync data block

macOS never offers 240 Hz. NVRMFB publishes a 23–240 Hz timing range, but every timing macOS asks it to validate is the 60 Hz one. NVRMFB only accepts rasters that NVKMS lists as EDID modes ("not an EDID mode").

### Experiment: display overrides (three versions, three boots)

The overrides live in `/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5/DisplayProductID-c8b`. Kit: [`tools/experiments/240hz-edid-override/`](../tools/experiments/240hz-edid-override/).

| Version | Timings added to the override EDID | Display name applied? | Timing reached NVRMFB? |
|---|---|---|---|
| v1 | 240 Hz as a DisplayID 1.3 Type I timing | yes | no |
| v2 | + 120 Hz as a base-block DTD, + 240 Hz as a CTA-861 Type VII Video Timing Data Block | yes | no |
| v3 | + range limits widened (48–240 Hz, 100–440 kHz, 1180 MHz), + DisplayID 100 and 144 Hz | yes | no |

On every boot all 42 `validateDetailedTiming` calls carried `pclk 293760000`. macOS applies the override's name but builds this panel's mode list only from the driver's boot raster and its scaled variants.

**Conclusion:** 240 Hz needs NullMoth to publish NVKMS's mode list, which already includes the DisplayID 2.0 timing. At 8 bpc the mode needs about 28 Gbps against 25.9 Gbps for HBR3 ×4, so the driver would probably also have to enable DSC. The override was uninstalled afterwards.

## Brightness: no control

There's no backlight device (`AppleBacklightDisplay` count 0), so there's no slider and the brightness keys do nothing. With the MUX in Discrete mode the dGPU drives the eDP backlight, so this needs driver support. NullMoth issue #15 (ACPI `_DSM` stubs) is the most promising lead. A software-dimming app (MonitorControl, Lunar) can darken the picture in the meantime.

## External displays

Not tested yet. The HDMI port is wired to the NVIDIA GPU (`nvfbheads=4`). NullMoth 1.0.7 fixed second-monitor jitter.
