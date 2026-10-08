#!/bin/bash
# Print the main milestones of the current boot, in seconds after the kernel started.
# Usage: bash /Volumes/1401/fastboot/boot-timing.sh
boot=$(sysctl -n kern.boottime | sed -E 's/^\{ sec = ([0-9]+),.*/\1/')
start=$(date -r "$boot" '+%Y-%m-%d %H:%M:%S')
echo "Kernel started: $start"

/usr/bin/log show --style compact --start "$start" --end "$(date -r $((boot + 240)) '+%Y-%m-%d %H:%M:%S')" --predicate '
  (process == "kernel" AND (eventMessage CONTAINS "BSD root:" OR eventMessage CONTAINS "Early boot complete"
     OR eventMessage CONTAINS "NVRM-xnu: probe 10de" OR eventMessage CONTAINS "boot screen:"
     OR eventMessage CONTAINS "auto-go: go(" OR eventMessage CONTAINS "VIDMEM ACCEPTED"
     OR eventMessage CONTAINS "boot hold RELEASED"))
  OR (process == "loginwindow" AND eventMessage CONTAINS "login state:")' 2>/dev/null |
awk -v boot="$boot" '
  /^[0-9]{4}-/ {
    split($2, t, ":"); cmd = "date -j -f \"%Y-%m-%d %H:%M:%S\" \"" $1 " " t[1] ":" t[2] ":00\" +%s"
    cmd | getline base; close(cmd)
    rel = base + t[3] - boot
    msg = $0; sub(/^[^]]*\] /, "", msg); sub(/.*login state: /, "login state: ", msg); sub(/^\([A-Za-z]+\) /, "", msg)
    if (!seen[msg]++) printf "%7.1f s  %s\n", rel, substr(msg, 1, 110)
  }' | sort -n
