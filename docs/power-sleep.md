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

SMCBatteryManager reports the battery normally. It sits at about 82% with "AC attached; not charging" because **Lenovo conservation mode** stops charging around 80%. That mode is set in Lenovo Vantage on Windows and enforced by the EC. Turn it off there for a full charge.

## Lenovo features (YogaSMC)

YogaSMC 1.5.3 ([zhen-zen/YogaSMC](https://github.com/zhen-zen/YogaSMC), the last release) loads from the EFI. Its `IdeaVPC` driver attaches to `VPC0` (`VPC2004`) under `EC0` and reports `ConservationMode`, `RapidChargeMode`, `FnlockMode` and battery details in ioreg. Its WMI part found the Game Zone (`GZFD`), battery and Fn+S devices. The EC sensor names in its default list don't exist on this EC (`DirectECKey` all `No`), so expect no extra temperature readings from it.

Control it with the menu bar app `/Applications/YogaSMCNC.app` or the pane at the bottom of System Settings (`~/Library/PreferencePanes/YogaSMCPane.prefPane`). Battery conservation mode (stop at about 80%) set here is the same EC setting as in Lenovo Vantage. The downloads and their SHA-256 are in `YogaSMC/1.5.3/` on the stick.

## CPU power management

`X86PlatformPlugin` loads with the MacBookPro16,4 board-id. CpuTopologyRebuild and `ProvideCurrentCpuInfo` handle the hybrid P/E cores. Not tuned further; CPUFriend isn't used.
