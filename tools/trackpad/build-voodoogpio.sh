#!/bin/bash
# Builds VoodooGPIO.kext from source with the Command Line Tools (no Xcode), mirroring the Xcode
# target: x86_64, C++ (gnu++11), kernel flags, MacKernelSDK headers + libkmod, kmod_info for an
# IOKit kext (no MODULE_START), Info.plist with the Xcode variables filled in.
# Usage: build-voodoogpio.sh <VoodooGPIO repo> <MacKernelSDK> <output dir>
set -euo pipefail
SRC=$(cd "$1" && pwd); SDK=$(cd "$2" && pwd); OUT=$3
NAME=VoodooGPIO; ID=org.coolstar.VoodooGPIO
VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$SRC/VoodooGPIO/Info.plist")
rm -rf "$OUT"; mkdir -p "$OUT/obj" "$OUT/$NAME.kext/Contents/MacOS"

COMMON=(-arch x86_64 -mmacosx-version-min=10.12 -mkernel -nostdinc -fno-builtin -fno-common
        -mno-red-zone -fno-stack-protector -fno-strict-aliasing -Os -g0
        -DKERNEL -DKERNEL_PRIVATE -DDRIVER_PRIVATE -DAPPLE -DNeXT
        -I"$SDK/Headers" -I"$SRC/VoodooGPIO")
CXX=(-x c++ -std=gnu++11 -fapple-kext -nostdinc++ -fno-exceptions -fno-rtti -Wno-inconsistent-missing-override)

objs=()
while IFS= read -r f; do
  o="$OUT/obj/$(basename "${f%.cpp}").o"
  echo "  c++  ${f#$SRC/}"
  clang "${COMMON[@]}" "${CXX[@]}" -c "$f" -o "$o"
  objs+=("$o")
done < <(find "$SRC/VoodooGPIO" -name '*.cpp' | sort)

cat > "$OUT/obj/kmod_info.c" <<EOF
#include <mach/mach_types.h>
extern kern_return_t _start(kmod_info_t *ki, void *data);
extern kern_return_t _stop(kmod_info_t *ki, void *data);
__attribute__((visibility("default"))) KMOD_EXPLICIT_DECL($ID, "$VER", _start, _stop)
__private_extern__ kmod_start_func_t *_realmain = 0;
__private_extern__ kmod_stop_func_t *_antimain = 0;
__private_extern__ int _kext_apple_cc = __APPLE_CC__;
EOF
echo "  cc   kmod_info.c"
clang "${COMMON[@]}" -x c -std=gnu99 -c "$OUT/obj/kmod_info.c" -o "$OUT/obj/kmod_info.o"

echo "  ld   $NAME"
clang++ -arch x86_64 -mmacosx-version-min=10.12 -mkernel -fapple-kext -nostdlib \
  -Xlinker -kext -L"$SDK/Library/x86_64" -lkmod \
  "${objs[@]}" "$OUT/obj/kmod_info.o" -o "$OUT/$NAME.kext/Contents/MacOS/$NAME"

sed -e "s/\$(EXECUTABLE_NAME)/$NAME/g" -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/$ID/g" \
    -e "s/\$(PRODUCT_NAME)/$NAME/g" "$SRC/VoodooGPIO/Info.plist" > "$OUT/$NAME.kext/Contents/Info.plist"
plutil -lint "$OUT/$NAME.kext/Contents/Info.plist" >/dev/null
echo "built $OUT/$NAME.kext ($ID $VER)"
