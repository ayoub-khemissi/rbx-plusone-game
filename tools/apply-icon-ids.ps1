<#
    Writes uploaded asset ids back into the configuration.

    Reads icons/ids.txt, one `slot=id` per line, and rewrites the value on every
    line carrying the matching `-- icon:<slot>` marker. Blank lines and lines
    starting with # are ignored, and an id may be written bare (1234567) or whole
    (rbxassetid://1234567).

    Doing this by hand means forty-odd copy-pastes across four files, which is
    exactly the kind of task that ends with one wrong id and an afternoon spent
    finding it.

    Usage:  ./tools/apply-icon-ids.ps1  [-DryRun]
#>
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$idsFile = Join-Path $root "icons/ids.txt"

if (-not (Test-Path $idsFile)) {
    Write-Host "Not found: icons/ids.txt" -ForegroundColor Red
    Write-Host "Write one line per icon:  slot=1234567"
    exit 1
}

$ids = @{}
foreach ($line in Get-Content $idsFile) {
    $trimmed = $line.Trim()
    if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }

    $parts = $trimmed -split "=", 2
    if ($parts.Length -ne 2) {
        Write-Host "Line not understood: $trimmed" -ForegroundColor Yellow
        continue
    }

    $id = $parts[1].Trim() -replace "^rbxassetid://", ""
    if ($id -notmatch "^\d+$") {
        Write-Host "Not an id: $trimmed" -ForegroundColor Yellow
        continue
    }
    $ids[$parts[0].Trim()] = $id
}

$targets = @(
    "src/Shared/Config/Themes/Default.luau",
    "src/Shared/Config/Upgrades.luau",
    "src/Shared/Config/Passes.luau",
    "src/Shared/Config/Products.luau"
)

$applied = @{}

foreach ($relative in $targets) {
    $path = Join-Path $root $relative
    # Read and write UTF-8 explicitly, without a BOM. The default encodings mangle
    # the emoji fallbacks on the way in and prepend a BOM on the way out, and a
    # BOM at the top of a .luau file is a parse error.
    $lines = Get-Content $path -Encoding utf8
    $changed = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch "--\s*icon:(\w+)\s*$") { continue }

        $slot = $Matches[1]
        if (-not $ids.ContainsKey($slot)) { continue }

        # The value is either nil or an existing asset id; both are replaced.
        $updated = $lines[$i] -replace '(?<=image = )nil', "`"rbxassetid://$($ids[$slot])`""
        $updated = $updated -replace 'rbxassetid://\d+', "rbxassetid://$($ids[$slot])"

        if ($updated -ne $lines[$i]) {
            $lines[$i] = $updated
            $applied[$slot] = $relative
            $changed = $true
        }
    }

    if ($changed -and -not $DryRun) {
        # WriteAllLines would use the platform newline; the repository is LF and
        # StyLua enforces it, so a CRLF rewrite shows up as every line changed.
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($path, ($lines -join "`n") + "`n", $utf8NoBom)
    }
}

$unused = $ids.Keys | Where-Object { -not $applied.ContainsKey($_) }

Write-Host "$($applied.Count) / $($ids.Count) ids written" -ForegroundColor Green
if ($DryRun) { Write-Host "(dry run: nothing was saved)" -ForegroundColor Yellow }

if ($unused) {
    Write-Host "`nNo marker matched these slots:" -ForegroundColor Yellow
    $unused | Sort-Object | ForEach-Object { Write-Host "  $_" }
}

Write-Host "`nRun ./scripts/check.ps1 before committing."
