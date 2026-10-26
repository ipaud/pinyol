# Installs the pinyol libretro core in RetroBat (docs/libretro.md). From the folder where RetroBat is:
#   irm https://raw.githubusercontent.com/ipaud/pinyol/main/platform/libretro/retrobat-pinyol.ps1 | iex
# or save it and run: powershell -ExecutionPolicy Bypass -File retrobat-pinyol.ps1 [-RetroBat C:\RetroBat]
# It downloads the release "libretro" (Windows x86-64), puts the core and its .info in RetroArch's folders, makes
# roms\pinyol and adds the Pinyol system to EmulationStation (es_systems_pinyol.cfg, which runs RetroArch itself).
param([string]$RetroBat = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
$ra = Join-Path $RetroBat 'emulators\retroarch'
if (-not (Test-Path (Join-Path $ra 'retroarch.exe'))) { throw "No RetroBat in $RetroBat (emulators\retroarch\retroarch.exe is missing): pass -RetroBat <its folder>" }
$tmp = Join-Path $env:TEMP 'pinyol-libretro'
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
New-Item $tmp -ItemType Directory | Out-Null
$zip = Join-Path $tmp 'core.zip'
Invoke-WebRequest 'https://github.com/ipaud/pinyol/releases/download/libretro/pinyol_libretro-windows-x86_64.zip' -OutFile $zip
Expand-Archive $zip $tmp
New-Item (Join-Path $ra 'cores'), (Join-Path $ra 'info') -ItemType Directory -Force | Out-Null
Copy-Item (Join-Path $tmp 'pinyol_libretro.dll') (Join-Path $ra 'cores') -Force
Copy-Item (Join-Path $tmp 'pinyol_libretro.info') (Join-Path $ra 'info') -Force
$roms = Join-Path $RetroBat 'roms\pinyol'
New-Item $roms -ItemType Directory -Force | Out-Null
$es = Join-Path $RetroBat 'emulationstation\.emulationstation'
New-Item $es -ItemType Directory -Force | Out-Null
$cfg = @"
<?xml version="1.0"?>
<systemList>
  <system>
    <name>pinyol</name>
    <fullname>Pinyol</fullname>
    <path>$roms</path>
    <extension>.pinyol .zip .PINYOL .ZIP</extension>
    <command>"$ra\retroarch.exe" -L "$ra\cores\pinyol_libretro.dll" "%ROM%"</command>
    <platform>pinyol</platform>
    <theme>pinyol</theme>
  </system>
</systemList>
"@
Set-Content (Join-Path $es 'es_systems_pinyol.cfg') $cfg -Encoding UTF8
Remove-Item $tmp -Recurse -Force
Write-Host "Done. Copy the games' .zip into $roms and restart RetroBat."
