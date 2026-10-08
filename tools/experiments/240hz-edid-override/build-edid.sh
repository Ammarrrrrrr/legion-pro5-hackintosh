#!/bin/bash
# Builds edid-240.hex: the panel's EDID with block 2 (DisplayID 2.0) replaced by a DisplayID 1.3
# section holding the panel's own 240 Hz timing as a Type I descriptor (macOS ignores the 2.0 Type VII one).
set -eu
SP="$(cd "$(dirname "$0")" && pwd)"
E=$(cat "$SP/edid.hex")
sum() { local h=$1 s=0 i; for ((i=0; i<${#h}; i+=2)); do s=$(( s + 16#${h:i:2} )); done; echo $s; }

# version 1.3, section length 0x79, product type 0 (extension section), 0 extensions
HDR="13790000"
# Type I timing block: tag 03, rev 00, 20 bytes
#   pclk 117504 x 10 kHz (stored -1 = 0x01CAFF), options 0x05 (16:10, not preferred, progressive)
#   H: active 2560, blank 160, front porch 48 (sync -), sync 32   V: active 1600, blank 200, fp 3 (sync -), sync 6
BLK="030014""ffca0105""ff09""9f00""2f00""1f00""3f06""c700""0200""0500"
SEC="$HDR$BLK"
while [ $(( ${#SEC} / 2 )) -lt 125 ]; do SEC="${SEC}00"; done
C1=$(printf '%02x' $(( (256 - $(sum "$SEC") % 256) % 256 )))
B2="70$SEC$C1"
C2=$(printf '%02x' $(( (256 - $(sum "$B2") % 256) % 256 )))
B2="$B2$C2"
NEW="${E:0:512}$B2"
[ $(( ${#NEW} / 2 )) -eq 384 ] || { echo "bad length $(( ${#NEW} / 2 ))"; exit 1; }
for blk in 0 1 2; do echo "block $blk sum%256=$(( $(sum "${NEW:$((blk*256)):256}") % 256 ))"; done
echo "DisplayID section sum%256=$(( $(sum "${B2:2:252}") % 256 ))"
echo "$NEW" > "$SP/edid-240.hex"
echo "${B2}" | fold -w 32
