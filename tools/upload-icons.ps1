<#
    Uploads the staged icons to Roblox through the Open Cloud Assets API and
    writes the resulting asset ids into icons/ids.txt.

    Needs an API key with the `asset:write` scope, created at
    create.roblox.com → Settings → Credentials → API Keys, and the id of the
    creator the assets belong to (your user id, or a group id).

    The key is read from icons/api-key.txt or the ROBLOX_API_KEY environment
    variable. It is never printed and never committed: icons/ is ignored except
    for ids.txt.

    The run is RESUMABLE. Every id is appended to ids.txt as soon as it comes
    back, and a slot already in the file is skipped — so a rate limit, a
    moderation hiccup or a closed terminal costs only the uploads that had not
    finished.

    Usage:  ./tools/upload-icons.ps1 -CreatorId 123456789 [-Group] [-Only speed,coins]
#>
param(
    [Parameter(Mandatory = $true)][string]$CreatorId,
    [switch]$Group,
    [string[]]$Only,
    [int]$DelayMs = 900
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$iconDir = Join-Path $root "icons"
$idsFile = Join-Path $iconDir "ids.txt"

# --- the key ---------------------------------------------------------------
$key = $env:ROBLOX_API_KEY
$keyFile = Join-Path $iconDir "api-key.txt"
if (-not $key -and (Test-Path $keyFile)) {
    $key = (Get-Content $keyFile -Raw).Trim()
}
if (-not $key) {
    Write-Host "No API key. Put it in icons/api-key.txt or set ROBLOX_API_KEY." -ForegroundColor Red
    exit 1
}

# --- what is already done --------------------------------------------------
$done = @{}
if (Test-Path $idsFile) {
    foreach ($line in Get-Content $idsFile) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }
        $parts = $trimmed -split "=", 2
        if ($parts.Length -eq 2 -and $parts[1].Trim() -match "\d+") {
            $done[$parts[0].Trim()] = $true
        }
    }
}

$files = Get-ChildItem (Join-Path $iconDir "*.png") | Sort-Object Name
if ($Only) {
    $files = $files | Where-Object { $Only -contains $_.BaseName }
}

$creatorField = if ($Group) { "groupId" } else { "userId" }
$uploaded = 0
$failed = @()

foreach ($file in $files) {
    $slot = $file.BaseName
    if ($done[$slot]) {
        Write-Host "  = $slot (already uploaded)" -ForegroundColor DarkGray
        continue
    }

    $request = @{
        assetType = "Decal"
        displayName = $slot
        description = "Interface icon"
        creationContext = @{ creator = @{ $creatorField = $CreatorId } }
    } | ConvertTo-Json -Compress -Depth 5

    # curl rather than Invoke-RestMethod: Windows PowerShell 5.1 has no -Form,
    # and hand-rolling a multipart body is how binary uploads get corrupted.
    $raw = & curl.exe -s -X POST "https://apis.roblox.com/assets/v1/assets" `
        -H "x-api-key: $key" `
        -F "request=$request;type=application/json" `
        -F "fileContent=@$($file.FullName);type=image/png"

    $response = $null
    try { $response = $raw | ConvertFrom-Json } catch {}

    if (-not $response -or -not $response.operationId) {
        $message = if ($response.message) { $response.message } else { $raw }
        Write-Host "  x $slot : $message" -ForegroundColor Red
        $failed += $slot
        Start-Sleep -Milliseconds $DelayMs
        continue
    }

    # The upload returns an operation, not an asset: moderation runs first.
    $assetId = $null
    for ($attempt = 1; $attempt -le 20; $attempt++) {
        Start-Sleep -Milliseconds 700
        $pollRaw = & curl.exe -s "https://apis.roblox.com/assets/v1/operations/$($response.operationId)" `
            -H "x-api-key: $key"
        $poll = $null
        try { $poll = $pollRaw | ConvertFrom-Json } catch {}
        if ($poll.done -and $poll.response.assetId) {
            $assetId = $poll.response.assetId
            break
        }
    }

    if (-not $assetId) {
        Write-Host "  ? $slot : still pending, retry later" -ForegroundColor Yellow
        $failed += $slot
        Start-Sleep -Milliseconds $DelayMs
        continue
    }

    Add-Content -Path $idsFile -Value "$slot=$assetId" -Encoding utf8
    Write-Host "  + $slot = $assetId" -ForegroundColor Green
    $uploaded += 1
    Start-Sleep -Milliseconds $DelayMs
}

Write-Host "`n$uploaded uploaded" -ForegroundColor Green
if ($failed.Count -gt 0) {
    Write-Host "$($failed.Count) to retry: $($failed -join ', ')" -ForegroundColor Yellow
    Write-Host "Run the same command again — what succeeded is skipped."
}
Write-Host "`nThen: ./tools/apply-icon-ids.ps1"
