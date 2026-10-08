#!/bin/bash
# Builds the v2 test EDID from the v1 override EDID (edid-240.hex):
#  - base block, descriptor slot 3 (was the "BOE CQ" text): DTD 2560x1600 @ 120 Hz (587.52 MHz, same blanking as the 60 Hz DTD)
#    -> proves whether macOS uses the override's EDID for timings at all
#  - CTA-861 block: adds a Type VII Video Timing Data Block (ext tag 0x22) with the panel's own 240 Hz timing (1175.04 MHz)
#  - DisplayID 1.3 block with the Type I 240 Hz timing: unchanged from v1
# Usage: build-edid-v2.sh <edid-240.hex> <out.hex>
set -euo pipefail
E=$(tr -d '\n' < "$1")
[ $(( ${#E} / 2 )) -eq 384 ] || { echo "input is not 384 bytes"; exit 1; }
sum() { local h=$1 s=0 i; for ((i=0; i<${#h}; i+=2)); do s=$(( s + 16#${h:i:2} )); done; echo $s; }
fix() { local b=${1:0:254}; printf '%s%02x' "$b" $(( (256 - $(sum "$b") % 256) % 256 )); }

# --- block 0: replace descriptor 3 (bytes 90..107) with a 120 Hz DTD
B0=${E:0:256}
[ "${B0:180:10}" = "000000fe00" ] || { echo "slot 3 is not a text descriptor"; exit 1; }
DTD120="80e500a0a040c8603020360059d71000001a"   # pclk 58752 x 10 kHz = 0xe580, rest identical to the 60 Hz DTD
B0="${B0:0:180}${DTD120}${B0:216}"
B0=$(fix "$B0")

# --- block 1 (CTA): insert T7VTDB after the existing data blocks, move the DTD offset
B1=${E:256:256}
[ "${B1:0:2}" = "02" ] || { echo "block 1 is not CTA"; exit 1; }
OFF=$(( 16#${B1:4:2} ))                    # DTD offset (15)
T7="f6""22""02""ffed1105ff099f002f001f003f06c70002000500"   # tag 7 len 22, ext tag 0x22, rev 2, Type VII 240 Hz (not preferred)
NEWOFF=$(( OFF + ${#T7} / 2 ))
B1="${B1:0:4}$(printf '%02x' $NEWOFF)${B1:6:$(( OFF*2 - 6 ))}${T7}${B1:$(( OFF*2 ))}"
B1=${B1:0:254}; B1=$(fix "$B1")

# --- block 2: DisplayID 1.3 from v1, unchanged
B2=${E:512:256}

OUT="$B0$B1$B2"
[ $(( ${#OUT} / 2 )) -eq 384 ] || { echo "bad length"; exit 1; }
for i in 0 1 2; do echo "block $i sum%256=$(( $(sum "${OUT:$((i*256)):256}") % 256 ))"; done
echo "$OUT" > "$2"
