<#
    Copies the icons the game actually uses out of the icon pack, into icons/,
    each renamed to its slot.

    The rename is the whole point. Roblox lists uploaded images by file name, so
    a file called speed.png comes back as an asset called speed, and pasting the
    ids back becomes lookup instead of detective work.

    Usage:  ./tools/stage-icons.ps1
    Then:   Studio -> Asset Manager -> Images -> right-click -> Add Images...
#>
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$map = Get-Content (Join-Path $PSScriptRoot "icon-map.json") -Raw | ConvertFrom-Json

$pack = Join-Path $root $map._pack
if (-not (Test-Path $pack)) {
    Write-Host "Icon pack not found: $pack" -ForegroundColor Red
    exit 1
}

$out = Join-Path $root "icons"
New-Item -ItemType Directory -Force $out | Out-Null

$size = $map._size
$copied = 0
$missing = @()

foreach ($property in $map.PSObject.Properties) {
    if ($property.Name.StartsWith("_")) { continue }

    $slot = $property.Name
    $parts = $property.Value -split "/"
    $folder = ($parts[0..($parts.Length - 2)]) -join "/"
    $file = $parts[-1]

    # The pack is not consistent: most folders are "256px", a few are "256w", and
    # the folder suffix does not always match the one in the file name.
    $source = $null
    foreach ($dirSuffix in @("px", "w")) {
        foreach ($fileSuffix in @("px", "w")) {
            $candidate = Join-Path $pack "$folder/$size$dirSuffix/$file $size$fileSuffix.png"
            if (Test-Path $candidate) { $source = $candidate; break }
        }
        if ($source) { break }
    }

    if (-not $source) {
        $missing += "$slot -> $($property.Value)"
        continue
    }

    Copy-Item $source (Join-Path $out "$slot.png") -Force
    $copied += 1
}

Write-Host "$copied icons staged in icons/" -ForegroundColor Green

if ($missing.Count -gt 0) {
    Write-Host "`nNot found in the pack:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host @"

Next:
  1. Studio -> View -> Asset Manager -> Images -> right-click -> Add Images...
  2. Select everything in icons/ and upload
  3. Wait for moderation, then right-click each -> Copy Asset ID
  4. Write them into icons/ids.txt as  slot=id  (one per line)
  5. ./tools/apply-icon-ids.ps1
"@
