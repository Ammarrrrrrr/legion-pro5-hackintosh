# Debugging notes

Pitfalls and techniques found while working on this machine.

## Logs

- **In zsh, `log` is a shell builtin.** Always call `/usr/bin/log show …`, or the query silently returns nothing.
- **NullMoth logs show up in the unified log** with sender `(NVRM)`, `(NVRMFB)` or `(NVAccel)`, because they load from the Auxiliary Kernel Collection:
  ```bash
  /usr/bin/log show --last boot --style compact --predicate 'process == "kernel"' | grep -E "NVRM|NVKMS"
  ```
- **Kexts injected by OpenCore never appear in `log show`.** Not even RealtekRTL8111 or itlwm. Their `IOLog` output only goes to the kernel message buffer (`sudo dmesg`) and the `-v` console.
- **The kernel message buffer is 128 KB** and gets overwritten within seconds:
  - by NVRMFB's `kapi event type 5` lines (about 150 a second) in a normal boot
  - by the FAT32 driver's `readdir:` debug lines in Safe Mode, while Spotlight scans the stick
  - the `msgbuf=` boot-arg is ignored
- **Workaround:** a LaunchDaemon that runs `/sbin/dmesg` every second for the first 25 s of boot, before NullMoth starts at about 28 s. Snapshots go to `/Library/Logs/bootdmesg/`. See [`tools/diagnostics/boot-dmesg/`](../tools/diagnostics/boot-dmesg/) (`install-bootlog.sh`, `remove-bootlog.sh`, `cleanup-bootlog.sh`). Even the first snapshot starts at about 7 s, so very early lines are lost, but VoodooI2C's controller start-up was captured.
- **Clock skew corrupts time-range queries.** Windows keeps the hardware clock in local time. After switching OSes, some log entries carry future timestamps, which breaks `log show --start/--last` ranges. Filter by the timestamp text instead.

## Shutdown stalls

`spindump -i /Library/Logs/DiagnosticReports/shutdown_stall_*.shutdownStall -o out.txt` works without sudo.

## Tools

- **The Command Line Tools are installed:** clang 17, git, swift, otool, xxd. Before that, `python3`, `strings` and `otool` were stubs that popped up an install dialog. Use `grep -a` instead of `strings`.
- **OpenCore plists:** `jq` fails on plists containing `<data>`. Use `plutil -extract <keypath> xml1 -o - file` or `/usr/libexec/PlistBuddy`.
- **PlistBuddy pitfall:** `Print :Array:N` with N past the end doesn't fail, so `while PlistBuddy …` loops forever. Use the array count from `plutil -extract <array> raw`.
- **FAT32 `._` files:** copying bundles to the FAT32 stick creates `._*` AppleDouble files. They're harmless to OpenCore, but delete them with `find … -name '._*' -delete` for clean diffs.
- **`/private/tmp` is wiped on reboot,** so keep anything durable on the stick or in this repository.

## Display mode tests without System Settings

JXA (`osascript -l JavaScript`) can list and switch display modes through CoreGraphics:
- `CGDisplayCopyAllDisplayModes(d, $())`; pass `$()`, not `null`
- configure with `kCGConfigureForAppOnly`, so a bad mode reverts when the script exits

See `tools/experiments/240hz-edid-override/test-240hz.sh` and `tools/experiments/hidpi-override/test-hidpi.sh`.
