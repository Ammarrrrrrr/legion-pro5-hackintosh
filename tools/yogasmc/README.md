# YogaSMC Legion build

Two patches for [zhen-zen/YogaSMC](https://github.com/zhen-zen/YogaSMC) master `299907b` (2024-05-05), applied in order:

- `0001-Legion-Game-Zone-support.patch`: the Legion Game Zone features described in [docs/power-sleep.md](../../docs/power-sleep.md#lenovo-features-yogasmc), the menu bar section, and build scripts for the kext and the app that need only the Command Line Tools.
- `0002-Pane-Legion-tab-rapid-charge-and-crash-fixes.patch`: the Legion tab in the System Settings pane, a fix for the pane crashing when it's opened a second time, rapid charge fixes, and `build-pane.sh`. Version 1.6.1.
- `0003-Detect-power-modes-and-sensor-sources-per-model.patch`: power modes from the firmware (adds Extreme on this laptop), `LENOVO_FAN_METHOD` as a second sensor source, for other Legions. Version 1.6.2.

The repository also has a README, `Tools/release.sh` and the release zips; the patches cover the driver, the apps and the build scripts.

The full source with history is the private repository [Ammarrrrrrr/YogaSMC-Legion](https://github.com/Ammarrrrrrr/YogaSMC-Legion) (`~/YogaSMC-Legion`, branch `main`). Built files: its [releases](https://github.com/Ammarrrrrrr/YogaSMC-Legion/releases) (v1.6.2 is current). The patches here are kept as a self-contained copy.

## Build

```bash
git clone https://github.com/zhen-zen/YogaSMC ~/YogaSMC-Legion
cd ~/YogaSMC-Legion
git checkout -b legion 299907b
git am /path/to/0001-*.patch /path/to/0002-*.patch /path/to/0003-*.patch
git clone --depth 1 https://github.com/acidanthera/MacKernelSDK
# Lilu-1.7.2-DEBUG.zip -> Lilu.kext, VirtualSMC-1.3.8-DEBUG.zip -> Kexts/VirtualSMC.kext, both into the repo root
Tools/build-kext.sh 1.6.2      # -> build/Release/YogaSMC.kext
Tools/build-app.sh 1.6.2       # -> build/Release/YogaSMCNC.app
Tools/build-pane.sh 1.6.2      # -> build/Release/YogaSMCPane.prefPane
```

`build-app.sh` and `build-pane.sh` reuse the compiled `Main.storyboardc` and `YogaSMCPane.nib` from the upstream 1.5.3 release (default path `build/upstream-1.5.3/`, copied out of `YogaSMC-App-Release.dmg`), because `ibtool` ships only with Xcode. Their outlets match current upstream; the pane's Legion tab is built in code.

Install the kext on the stick as `EFI/OC/Kexts/YogaSMC-Legion.kext` (it keeps the bundle id `org.zhen.YogaSMC`, so only one of the two YogaSMC kexts may be enabled in a config).

## Tools

```bash
clang -O2 -framework IOKit -framework CoreFoundation -o ~/.local/bin/yogactl yogactl.c
clang -O2 -framework IOKit -o ~/.local/bin/smckeys smckeys.c
```

| Command | What it does |
|---|---|
| `yogactl mode [quiet\|balanced\|performance\|custom\|224]` | show or set the Fn+Q power mode (224 = Extreme) |
| `yogactl sensors` | fan speeds and temperatures, plus where each is read from |
| `yogactl probe` | runs every read-only Game Zone getter and `LENOVO_OTHER_METHOD` capability |
| `yogactl query <gamezone\|other\|lighting\|fan> <id> [arg\|none\|hex:..]` | one read-only WMI method call (the kext refuses setters here) |
| `yogactl block <guid> [instance]` | read a WMI data block |
| `yogactl acpi DSDT dsdt.aml` | dump an ACPI table through the kext (macOS 15 no longer exposes them in ioreg) |
| `yogactl props [class]` | all properties of `IdeaWMIGameZone` (or another class, e.g. `IdeaVPC`) |
| `smckeys [prefix]` / `smckeys KEY…` | list or read AppleSMC keys |

None of them need root.
