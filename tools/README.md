# Tools

| Path | What it does |
|---|---|
| `nullmoth-install.sh` | Installs a NullMoth driver package from the boot stick (checks the GitHub SHA-256, runs `shasum -c SHA256SUMS`, then NullMoth's `install.sh`). `sudo bash nullmoth-install.sh 1.0.9` (or `1.0.6` to roll back). |
| `trackpad/` | `build-voodoogpio.sh` builds VoodooGPIO (victorwitkamp fork, `INTC1085`) with the Command Line Tools + MacKernelSDK; `README.txt` summarises the trackpad kext. |
| `internal-boot/` | Prepared but unused: copy OpenCore to the spare internal EFI partition (`copy-oc-to-internal.sh`, sudo) and add a firmware boot entry from Windows (`add-opencore-boot-entry.ps1`, admin PowerShell). |
| `yogasmc/` | The YogaSMC Legion patch (power mode, fans, temperatures), how to build it without Xcode, and the `yogactl` / `smckeys` CLIs. |
| `fastboot/` | `boot-timing.sh` prints the current boot's milestones in seconds after kernel start. `set-startup-disk.sh` (sudo) makes macOS OpenCore's default entry, needed with the hidden picker. |
| `diagnostics/boot-dmesg/` | LaunchDaemon that saves `dmesg` every second for the first 25 s of boot (to see OpenCore-injected kexts' messages). Install, remove and clean-up scripts. |
| `diagnostics/camera/` | `grab.swift`: grabs camera frames without drawing them and reports brightness (tells a black sensor from a drawing problem). |
| `experiments/240hz-edid-override/` | The three 240 Hz display-override experiments: EDID builders, decoder, install, uninstall and test scripts. Result: macOS ignores override timings with this driver. |
| `experiments/hidpi-override/` | Untested HiDPI (Retina-style) display override and a safe switching test. |

Scripts that need root say so at the top; run them with `sudo bash <script>`. Paths assume the boot stick is mounted at `/Volumes/1401`.
