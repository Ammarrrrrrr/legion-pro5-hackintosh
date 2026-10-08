# YogaSMC Legion build

`0001-Legion-Game-Zone-support.patch` applies to [zhen-zen/YogaSMC](https://github.com/zhen-zen/YogaSMC) master `299907b` (2024-05-05). It adds the Legion Game Zone features described in [docs/power-sleep.md](../../docs/power-sleep.md#lenovo-features-yogasmc), and two build scripts that need only the Command Line Tools.

The working tree on this machine is `~/YogaSMC-Legion` (branch `legion`, local only).

## Build

```bash
git clone https://github.com/zhen-zen/YogaSMC ~/YogaSMC-Legion
cd ~/YogaSMC-Legion
git checkout -b legion 299907b
git am /path/to/0001-Legion-Game-Zone-support.patch
git clone --depth 1 https://github.com/acidanthera/MacKernelSDK
# Lilu-1.7.2-DEBUG.zip -> Lilu.kext, VirtualSMC-1.3.8-DEBUG.zip -> Kexts/VirtualSMC.kext, both into the repo root
Tools/build-kext.sh 1.6.0      # -> build/Release/YogaSMC.kext
Tools/build-app.sh 1.6.0       # -> build/Release/YogaSMCNC.app
```

`build-app.sh` reuses the compiled `Main.storyboardc` from the upstream 1.5.3 `YogaSMCNC.app` (default path `build/upstream-1.5.3/YogaSMCNC.app`, copied out of `YogaSMC-App-Release.dmg`), because `ibtool` ships only with Xcode. The storyboard hasn't changed upstream since 1.5.3.

Install the kext on the stick as `EFI/OC/Kexts/YogaSMC-Legion.kext` (it keeps the bundle id `org.zhen.YogaSMC`, so only one of the two YogaSMC kexts may be enabled in a config).

## Tools

```bash
clang -O2 -framework IOKit -framework CoreFoundation -o ~/.local/bin/yogactl yogactl.c
clang -O2 -framework IOKit -o ~/.local/bin/smckeys smckeys.c
```

| Command | What it does |
|---|---|
| `yogactl mode [quiet\|balanced\|performance\|custom]` | show or set the Fn+Q power mode |
| `yogactl sensors` | fan speeds and temperatures, plus where each is read from |
| `yogactl probe` | runs every read-only Game Zone getter and `LENOVO_OTHER_METHOD` capability |
| `yogactl query <gamezone\|other\|lighting\|fan> <id> [arg\|none\|hex:..]` | one read-only WMI method call (the kext refuses setters here) |
| `yogactl block <guid> [instance]` | read a WMI data block |
| `yogactl acpi DSDT dsdt.aml` | dump an ACPI table through the kext (macOS 15 no longer exposes them in ioreg) |
| `yogactl props [class]` | all properties of `IdeaWMIGameZone` (or another class, e.g. `IdeaVPC`) |
| `smckeys [prefix]` / `smckeys KEY…` | list or read AppleSMC keys |

None of them need root.
