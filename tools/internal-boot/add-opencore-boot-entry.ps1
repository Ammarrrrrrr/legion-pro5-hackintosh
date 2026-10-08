# Adds an "OpenCore" entry to the laptop's UEFI boot menu, pointing at OpenCore on the internal
# 1 GB EFI partition (GPT partition GUID 4134DAA5-618A-459A-9F2C-19DBA0B0D52E), and puts it first.
# Windows Boot Manager stays in the list, so Windows still boots from F12 or from the OpenCore picker.
# Run in an ADMINISTRATOR PowerShell:
#   powershell -ExecutionPolicy Bypass -File Z:\internal-boot\add-opencore-boot-entry.ps1
$ErrorActionPreference = 'Stop'
$guid = '{4134daa5-618a-459a-9f2c-19dba0b0d52e}'
$p = Get-Partition | Where-Object { $_.Guid -eq $guid }
if (-not $p) { throw "Partition $guid not found" }
"Found OpenCore partition: disk $($p.DiskNumber), partition $($p.PartitionNumber), $([math]::Round($p.Size/1MB)) MB"
$L = [char[]](71..89) | Where-Object { -not (Test-Path "$($_):\") } | Select-Object -Last 1
$dp = "$env:TEMP\oc-diskpart.txt"
"select disk $($p.DiskNumber)`nselect partition $($p.PartitionNumber)`nassign letter=$L" | Set-Content $dp -Encoding ASCII
diskpart /s $dp | Out-Null
try {
  if (-not (Test-Path "$($L):\EFI\OC\OpenCore.efi")) { throw "OpenCore.efi not found on that partition - do the macOS copy step first" }
  $out = bcdedit /copy '{bootmgr}' /d "OpenCore"
  $id = [regex]::Match(($out -join ' '), '\{[0-9a-fA-F-]{36}\}').Value
  if (-not $id) { throw "bcdedit /copy failed: $out" }
  bcdedit /set $id device "partition=$($L):" | Out-Null
  bcdedit /set $id path '\EFI\OC\OpenCore.efi' | Out-Null
  bcdedit /set '{fwbootmgr}' displayorder $id /addfirst | Out-Null
  "Added OpenCore boot entry $id as the first boot option."
} finally {
  "select disk $($p.DiskNumber)`nselect partition $($p.PartitionNumber)`nremove letter=$L" | Set-Content $dp -Encoding ASCII
  diskpart /s $dp | Out-Null; Remove-Item $dp
}
bcdedit /enum firmware | Select-String -Pattern 'identifier|description|path|displayorder'
"To undo:  bcdedit /delete <the OpenCore id above>"
