# Power, sleep and shutdown

## System sleep is disabled (driver limitation)

Tested twice on NullMoth 1.0.6: once from Apple menu → Sleep, once by idle sleep followed by a scheduled maintenance wake.

1. Entering S3 removes the GPU's power.
2. On resume, NVRM logs `Xid 79: GPU has fallen off the bus`, then `Xid 154`, then every GSP call fails with `NV_ERR_GPU_IS_LOST`.
3. `NVRM-fb: setPowerState 1` can't allocate VRAM, and the screen stays black.
4. The system freezes about 70 s later, and WindowServer's watchdog panics after 120 s. With `debug=0x100` the machine then halts instead of restarting.

The driver has no resume path that re-runs GSP boot. Display-only sleep (`setPowerState 0/1`) works fine.

Applied (on AC and battery):

```bash
sudo pmset -a disablesleep 1 sleep 0 standby 0 hibernatemode 0 powernap 0 proximitywake 0
```

| Setting | Value |
|---|---|
| `SleepDisabled` | 1 |
| `sleep` / `standby` / `hibernatemode` / `powernap` / `proximitywake` | 0 |
| `displaysleep` | 10 min on AC, 2 min on battery (works) |

Consequences:
- **Closing the lid** only turns the panel off. Shut down before putting the laptop in a bag.
- **The hibernation file** `/var/vm/sleepimage` (1 GB) is no longer used and can be removed with `sudo rm /var/vm/sleepimage`.

## Shutdown "stalls" are harmless

`/Library/Logs/DiagnosticReports/shutdown_stall_*.shutdownStall` appears after every shutdown.

- **What they contain:** decoding one with `spindump -i` (no sudo needed) shows macOS sampled processes 2 s into shutdown. The processes still alive were ordinary agents (App Store and account services, Safari Safe Browsing, usage tracking, the FSKit services for the FAT32 stick).
- **Nothing was stuck:** no third-party driver was in a shutdown path.
- **Shutdown time:** about 5 s, from the restart request to the last log entry.

## Battery

SMCBatteryManager reports the battery normally. It sits at about 82% with "AC attached; not charging" because **Lenovo conservation mode** stops charging around 80%. That mode is enforced by the EC. Turn it off for a full charge, either in Lenovo Vantage on Windows or with "Battery Conservation" in the YogaSMCNC menu on macOS.

## Lenovo features (YogaSMC)

`config.plist` loads **YogaSMC 1.6.1, a Legion build** of [zhen-zen/YogaSMC](https://github.com/zhen-zen/YogaSMC) (upstream master `299907b` plus two patches, kept in [`tools/yogasmc/`](../tools/yogasmc/)). Every other config still loads the stock 1.5.3 release.

### Why stock YogaSMC wasn't enough

Stock 1.5.3 attaches `IdeaVPC` to `VPC0` (`VPC2004`) and handles Fn-lock, battery conservation and rapid charge. Its Game Zone code calls the old `LENOVO_GAMEZONE_DATA` getters (fan count, fan speeds, CPU/GPU temperature). On this BIOS (`N0CN29WW`, Game Zone version 16) `WMAA` has no branch for most of them, and `GetCPUTemp`/`GetGPUTemp` return a hard-coded 0, so it published no sensors. LenovoLegionToolkit (LLT) reads Gen 7+ Legions through the newer `LENOVO_OTHER_METHOD` instead.

### What the Legion build adds

| Feature | Firmware interface (from the BMOF on `GZFD` and LLT) |
|---|---|
| Power mode Quiet / Balanced / Performance / Custom, read and set | `LENOVO_GAMEZONE_DATA` 45 `GetSmartFanMode`, 44 `SetSmartFanMode` (values 1, 2, 3, 255) |
| Fn+Q on-screen popup with the new mode | Fn+Q EC query does `Notify (GZFD, 0xE3)` (smart fan mode event), then `0xE7` (thermal mode) |
| CPU and GPU fan speed (rpm) | `LENOVO_OTHER_METHOD` 17 `GetFeatureValue` `0x04030001` / `0x04030002` |
| CPU, GPU and PCH temperature | `GetFeatureValue` `0x05040000` / `0x05050000` / `0x05010000` |
| Touchpad lock, Win key lock | Game Zone 24–26 and 21–23 (the BIOS reports both as supported) |
| Display overdrive | not supported on this panel (`IsSupportOD` = 0), hidden |

The sensors are published as VirtualSMC keys, so monitoring apps see them: `FNum` = 2, `F0Ac` / `F1Ac` (fans), `TCXC` (CPU), `TG0P` and `TG0D` (GPU), `TPCD` (PCH). SMCProcessor keeps providing the per-core CPU temperatures.

Verified on 2026-10-09 (1.6.0): fans around 1,900 rpm idle, temperatures live, Quiet → Balanced → Performance → Quiet switched from macOS (the firmware's thermal mode follows), Fn+Q shows the popup, menu bar section works.

### Using it

- **Menu bar:** `/Applications/YogaSMCNC.app` (1.6.1, same build). The top of its menu has the power mode submenu, temperatures, fan speeds and toggles for battery conservation (stop at about 80%, the same EC setting as Lenovo Vantage), rapid charge, Fn lock, always-on USB, touchpad lock and "Disable Win (⌘) Key". It isn't a login item by default; use "Start at Login" in its menu.
- **Shell:** `yogactl mode [quiet|balanced|performance|custom]`, `yogactl sensors`, `yogactl probe` (every read-only getter), `yogactl acpi DSDT dsdt.aml`. `smckeys F` / `smckeys TG0P` read the SMC keys. Both are built from `tools/yogasmc/` into `~/.local/bin`. No root needed.
- **Caveats:** "Disable Win (⌘) Key" disables Command, because that is the Windows key on macOS. Touchpad lock is an EC feature and may not affect the I2C touchpad.
- **System Settings pane** (`~/Library/PreferencePanes/YogaSMCPane.prefPane`, 1.6.1, at the bottom of System Settings): a **Legion** tab with the power mode, live temperatures and fan speeds (every 2 s while open), touchpad lock and Win-key lock. The Idea tab keeps always-on USB, conservation mode and rapid charge; the General tab keeps Fn-key mode and the menu bar options. The stock 1.5.3 pane crashed when opened a second time on an IdeaPad-class machine (it freed the removed Think tab, then used its checkboxes); fixed.
- **Rapid charge** shows as unavailable: this BIOS accepts it (`SBMC` 7/8) only while the EC flag `QCBX` is set, and `GBMD` reports the capability the same way. It is re-checked on every battery update, so it appears if the EC enables it.

### Building

The build needs no Xcode. `tools/yogasmc/README.md` has the steps: apply the patch to upstream, put the Lilu 1.7.2 and VirtualSMC 1.3.8 DEBUG SDK kexts and acidanthera MacKernelSDK in the repo root, then run `Tools/build-kext.sh` and `Tools/build-app.sh`. The kext's imports match the official 1.5.3 binary.

## CPU power management

`X86PlatformPlugin` loads with the MacBookPro16,4 board-id. CpuTopologyRebuild and `ProvideCurrentCpuInfo` handle the hybrid P/E cores. Not tuned further; CPUFriend isn't used.
