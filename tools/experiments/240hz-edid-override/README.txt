240 Hz on the Legion's built-in panel (BOE NE160QDM-NZB, EDID vendor 9e5 product c8b)

Why only 60 Hz: the panel's EDID has its 60 Hz mode in the base block and its 240 Hz mode
(2560x1600, pixel clock 1175.04 MHz) only in a DisplayID 2.0 "Type VII" block. macOS ignores that
block, so it never asks the NullMoth driver for 240 Hz. The driver (NVKMS) accepts only modes that
are in the panel's real EDID, so the override below re-states the SAME 240 Hz timing as a
DisplayID 1.3 "Type I" timing, which macOS reads. 60 Hz stays the preferred mode.

Files
  DisplayProductID-c8b   display override (IODisplayEDID = patched EDID, IODisplayEDIDOriginal = real one)
  install-240hz.sh       sudo: copies it to /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5/
  uninstall-240hz.sh     sudo: removes it
  test-240hz.sh          no sudo: switches to 240 Hz for 15 s, reverts unless you click Keep; prints driver log
  build-edid.sh, edid.hex, edid-240.hex   how the patched EDID was made

Steps
  1. sudo bash /Volumes/1401/refresh240/install-240hz.sh
  2. Reboot (still 60 Hz after login).
  3. bash /Volumes/1401/refresh240/test-240hz.sh
     - "No 2560x1600 mode above 60 Hz": macOS still didn't take the timing, or the driver refused it (see log lines).
     - Screen black: wait 15 s, it reverts. Nothing is saved unless you click Keep.

If the login screen is black after step 2 (not expected)
  From Windows copy Z:\EFI\OC\config-safe-nvoff.plist over config.plist, boot to the Safe Mode desktop,
  run  sudo bash /Volumes/1401/refresh240/uninstall-240hz.sh , then copy config-v106-smallbar.plist
  (or the config you were using) back over config.plist and reboot.
