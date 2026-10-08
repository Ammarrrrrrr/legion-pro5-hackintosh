# Mac identity (SMBIOS)

## What was wrong

- **macOS saw the Lenovo identity.** It reported model `83DF`, the Lenovo serial and "Processor: Unknown". Only the board-id (`Mac-A61BADE1FDAD7B05`, MacBookPro16,4) came through.
- **Cause:** `PlatformInfo → UpdateSMBIOSMode` is `Custom`, which writes the Mac SMBIOS to a separate table so Windows keeps the Lenovo one. But `Kernel → Quirks → CustomSMBIOSGuid` was `false`, so macOS never read that table.
- **The serial wasn't private.** The serial, MLB and UUID in the config were the **public ones** shipped in `efi_legion-main`, so anyone using that EFI shares them. That gets serials blocked from iCloud, iMessage and FaceTime.

## Fix

1. Build `macserial` from OpenCorePkg source (commit `963025f`) with the Command Line Tools:
   ```bash
   git clone --depth 1 --filter=blob:none --sparse https://github.com/acidanthera/OpenCorePkg.git
   cd OpenCorePkg && git sparse-checkout set Utilities/macserial User
   make -C Utilities/macserial
   ```
2. Generate a serial and MLB for the model, and check them:
   ```bash
   ./macserial -m MacBookPro16,4 -n 1        # SERIAL | MLB
   ./macserial -i <SERIAL>                    # should decode as MacBookPro16,4
   ./macserial --verify <MLB>                 # "Valid MLB checksum."
   uuidgen                                    # SystemUUID
   ```
3. Set `ROM` to the MAC address of `en0`, the Wi-Fi interface. It's built-in and primary, so iServices are satisfied.
4. Write `SystemSerialNumber`, `MLB`, `SystemUUID` and `ROM` into `PlatformInfo → Generic`, and set `Kernel → Quirks → CustomSMBIOSGuid = true`.
5. Reboot, check About This Mac, then sign in to the Apple ID. You can optionally check the serial at checkcoverage.apple.com first; "not valid" is the result you want.

The macOS **Hardware UUID** differs from `SystemUUID` by design. xnu derives `IOPlatformUUID` as a version-5 hash of the firmware's `system-id`, which does equal `SystemUUID`.

Result: MacBookPro16,4 "MacBook Pro (16-inch, 2019)" with its own serial, and an Apple ID signed in.

## In this repository

All configs carry OpenCore's sample placeholders (`W00000000001`, `M0000000000000001`, an all-zero UUID, ROM `112233445566`). **Generate your own** before using this EFI. The real values live only in `smbios/identity.txt` on the boot stick, which is never committed.
