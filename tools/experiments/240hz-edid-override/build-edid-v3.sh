#!/bin/bash
# Builds the v3 diagnostic EDID from v2 (edid-240-v2.hex):
#  - base block slot 2 (range limits): V 48-240 Hz, H 100-440 kHz, max pclk 1180 MHz (was H 432-432 kHz)
#  - base block slot 3: 120 Hz DTD (587.52 MHz), kept from v2
#  - CTA block: Type VII Video Timing Data Block with 240 Hz, kept from v2
#  - DisplayID 1.3 block: Type I timings 240 Hz (1175.04 MHz), 144 Hz (705.02 MHz), 100 Hz (489.60 MHz)
# All timings use the panel's blanking (totals 2720x1800, sync H-/V-). Only 60 Hz stays preferred.
# Usage: build-edid-v3.sh <edid-240-v2.hex> <out.hex>
set -euo pipefail
E=$(tr -d '\n' < "$1")
[ $(( ${#E} / 2 )) -eq 384 ] || { echo "input is not 384 bytes"; exit 1; }
sum() { local h=$1 s=0 i; for ((i=0; i<${#h}; i+=2)); do s=$(( s + 16#${h:i:2} )); done; echo $s; }
fix() { local b=${1:0:254}; printf '%s%02x' "$b" $(( (256 - $(sum "$b") % 256) % 256 )); }

# --- block 0: range limits in slot 2 (bytes 72..89)
B0=${E:0:256}
[ "${B0:144:10}" = "000000fd0c" ] || { echo "slot 2 is not the expected range-limits descriptor"; exit 1; }
RL="000000fd""08""30""f0""64""b9""76""01""0a202020202020"   # flags: max H +255; minV 48 maxV 240 minH 100 maxH 185+255=440 kHz; 1180 MHz
B0=$(fix "${B0:0:144}${RL}${B0:180}")

B1=${E:256:256}   # CTA with T7VTDB, unchanged

# --- block 2: DisplayID 1.3 with three Type I descriptors
desc() { printf '%s05ff099f002f001f003f06c70002000500' "$1"; }   # $1 = pclk (10 kHz units - 1), little endian, 3 bytes
D240=$(desc ffca01)   # 117504 -> 1175.04 MHz -> 240.0 Hz
D144=$(desc 651301)   # 70502  ->  705.02 MHz -> 144.0 Hz
D100=$(desc 3fbf00)   # 48960  ->  489.60 MHz -> 100.0 Hz
SEC="13790000""03003c${D240}${D144}${D100}"
while [ $(( ${#SEC} / 2 )) -lt 125 ]; do SEC="${SEC}00"; done
C=$(printf '%02x' $(( (256 - $(sum "$SEC") % 256) % 256 )))
B2=$(fix "70${SEC}${C}00")

OUT="$B0$B1$B2"
[ $(( ${#OUT} / 2 )) -eq 384 ] || { echo "bad length"; exit 1; }
for i in 0 1 2; do echo "block $i sum%256=$(( $(sum "${OUT:$((i*256)):256}") % 256 ))"; done
echo "DisplayID section sum%256=$(( $(sum "${OUT:514:252}") % 256 ))"
echo "$OUT" > "$2"
