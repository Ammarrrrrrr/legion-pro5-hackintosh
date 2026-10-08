# NVIDIA graphics: the NullMoth driver

## What it is

NullMoth (<https://github.com/nullmoth/nvidia-macos-driver>) is a community port of NVIDIA's open kernel modules to macOS. It has four kexts (NVRM, NVRMFB, NVAccel, NVRMAGDC), a Metal plug-in (`NVMTLDriver.bundle`), a shader compiler and the GSP firmware. It's validated by its authors on an RTX 5060 desktop only. Laptops and RTX 40 cards are listed as "pending" validation.

## Installed version

| Item | Value |
|---|---|
| Package | `nullmoth-nvidia-1.0.9.tar.gz` (GitHub release v1.0.14), SHA-256 `9dbfdb1b1359e2ef4166a46905ee195774b0b4ba20be083a8111ef550b1e5789` |
| Install method | manual: [`tools/nullmoth-install.sh`](../tools/nullmoth-install.sh) wraps NullMoth's own `pkgroot/install.sh` (checksum check, `shasum -c SHA256SUMS`, install, kernel-collection check) |
| Location | `/Library/Extensions/NV*.kext`, `/Library/GPUBundles/`, firmware in `/Users/Shared/nvfw/` |
| Rollback | `sudo bash tools/nullmoth-install.sh 1.0.6` (package kept on the stick at `NullMoth/1.0.6/`). The installer also keeps a backup in `/Library/NullMoth/backup-*`. |
| Later releases | packages 1.0.10 and 1.0.11 (GitHub v1.0.15–v1.0.18) change only the installer and the 1401 app. All 47 GPU, kernel, compiler and firmware files are byte-identical to 1.0.9, so there's nothing to gain from updating. |

Version history on this laptop:
- **1.0.1:** boots in Safe Mode only. The desktop never came up because of a WindowServer hold timing bug.
- **1.0.6:** first working desktop.
- **1.0.9:** current.

## Required settings

From NullMoth's README:
- boot-args `nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80`
- `csr-active-config` `430A0000`

NullMoth recommends `ResizeGpuBars 13` / `ResizeAppleGpuBars -1` plus a Kernel→Block on `IONDRVSupport`. This laptop instead uses **`ResizeGpuBars -1` / `ResizeAppleGpuBars 0` with no IONDRV block**, and it works: the driver grows BAR1 by itself (below). The full-BAR variant was never tested on 1.0.6 or later.

## Boot timing (how 2½ minutes became 41 seconds)

NVRM waits a "settle" time after loading before starting the GPU. The default is 500 ms if it could place BAR1, or 100 000 ms if not. The boot-arg `nvrmsettle=<ms>` overrides it.

| Config | GPU starts | Login screen | Note |
|---|---|---|---|
| `nvrmsettle=100000` (first working setup) | ~127 s | ~145 s | needed on 1.0.1 |
| `nvrmsettle=20000` | ~47 s | ~66 s | |
| no `nvrmsettle` (driver default 500 ms) | ~28 s | **~41 s** | current; the early start no longer hangs on 1.0.6+ |

Times are counted from the kernel start. Another ~9 s per boot was saved by turning off OpenCore's log file on the USB stick (`Misc/Debug/Target 3`, `AppleDebug false`), and up to 7 s more by the 3 s picker timeout.

From 1.0.6 on, the driver resizes BAR1 itself and places it outside the boot console:

```
NVRM-xnu: bar1: Resizable BAR capability @0xbb0 says BAR1 = 64 MB (sizes supported mask 0x3fc0)
NVRM-xnu: bar1: host bridge 64-bit window 0x4000000000-0x7fffffffff (ACPI _CRS), CPU reaches 39 bits
NVRM-xnu: bar1: PLACED — BAR1 8192 MB live at 0x7c00000000
NVRM-xnu: auto-go: go(2) in 500 ms on its own thread (BAR1 placed outside the console)
NVKMS INFO: GPU:0: TAKEOVER boot head 0: firmware displayId 0x2000 -> connector DP-4, SOR 1
NVRM-fb: VIDMEM ACCEPTED -- aperture 0x7c00200000
```

## Known driver bugs and gaps on this laptop

Full details and log excerpts are in [`reports/nullmoth/`](../reports/nullmoth/).

1. **System sleep:** on wake the GPU is gone (`Xid 79: GPU has fallen off the bus`, `NV_ERR_GPU_IS_LOST`). The screen stays black and the system freezes. Workaround: sleep disabled, see [power-sleep.md](power-sleep.md). Display-only sleep works.
2. **Changing resolution freezes the whole system.** Every non-native mode goes through the scaled-mode path. See [display.md](display.md).
3. **Core Image can't draw into the driver's Metal drawables**, so Photo Booth is black: `texture usage must include MTLTextureUsageShaderWrite`.
4. **No backlight control.**
5. **No 240 Hz.** See [display.md](display.md).
6. **Log volume:** `NVRM-fb: kapi event type 5` is logged about 150 times a second.
7. **Idle CPU:** WindowServer uses about 50% of one core at idle.

Harmless messages seen on every boot:
- `clFindFHBAndGetChipsetInfoIndex_IMPL: … FHB/P2P/3DCTRL not found`
- asserts at `chipset.c:462/557`
- `busy timeout (60s): 'NVRM'`
- on 1.0.9, `PV-SENTINEL REFUSED … BootKC`

## Useful upstream issues

- **#15:** Legion 5 15ACH6H (RTX 3070 Laptop). NullMoth's `nv_acpi_*` functions are stubs. A small kext implementing `nv_acpi_dsm_method` made RM handle the internal panel. It's a possible lead for backlight control.
- **#26:** displays go black with only a white cursor on an Alienware (RTX 2080S). Same symptom as the resolution-change freeze here.
- **#23:** the 102 s boot delay when BAR1 isn't placed.

## Verifying the driver

```bash
kmutil showloaded --list-only | grep nullmoth        # 4 lines
system_profiler SPDisplaysDataType | grep -E "Chipset|Metal|Resolution"
/usr/bin/log show --last boot --predicate 'process == "kernel"' | grep -E "bar1:|auto-go|VIDMEM"
```
