#!/bin/bash
E=$(cat "$1"); le(){ echo $(( 16#${1:2:2}${1:0:2} )); }
r=${E:144:36}
echo "range limits (flags 0x${r:8:2}): V $((16#${r:10:2}))-$((16#${r:12:2})) Hz, H $((16#${r:14:2}))-$((16#${r:16:2} + 255)) kHz, max pclk $((16#${r:18:2} * 10)) MHz"
d=${E:180:36}; pc=$(( 16#${d:2:2}${d:0:2} )); echo "base DTD slot 3: pclk $((pc*10)) kHz -> $(( pc*10000/(2720*1800) )) Hz"
b=${E:512:256}; n=$(( 16#${b:14:2} / 20 )); echo "DisplayID v${b:2:1}.${b:3:1} Type I block, $n descriptors:"
for ((i=0; i<n; i++)); do x=${b:$((16+i*40)):40}; pc=$(( 16#${x:4:2}${x:2:2}${x:0:2} + 1 )); ha=$(( $(le ${x:8:4}) + 1 )); hb=$(( $(le ${x:12:4}) + 1 )); va=$(( $(le ${x:24:4}) + 1 )); vb=$(( $(le ${x:28:4}) + 1 )); t=$(( (ha+hb)*(va+vb) )); echo "   ${ha}x${va} pclk $((pc*10)) kHz totals $((ha+hb))x$((va+vb)) -> $(( pc*1000000/t ))/100 Hz, options 0x${x:6:2}"; done
