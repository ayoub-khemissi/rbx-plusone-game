<#
    Full check: format, lint, build, tests.
    Usage:  ./scripts/check.ps1  [-Fix]
#>
param([switch]$Fix)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root ".tools"
Push-Location $root

$failed = @()

# A missing configuration file does not make these tools fail: they quietly fall
# back to their defaults and reformat the whole repository. So their presence is
# checked explicitly, which is cheaper than reviewing a thousand-line diff.
$required = @("stylua.toml", "selene.toml", ".luaurc", "default.project.json")
foreach ($file in $required) {
    if (-not (Test-Path (Join-Path $root $file))) {
        Write-Host "Missing configuration file: $file" -ForegroundColor Red
        $failed += $file
    }
}

try {
    Write-Host "`n== StyLua ==" -ForegroundColor Cyan
    if ($Fix) {
        & (Join-Path $tools "stylua.exe") src tests
    } else {
        & (Join-Path $tools "stylua.exe") --check src tests
    }
    if ($LASTEXITCODE -ne 0) { $failed += "stylua" }

    Write-Host "`n== Selene ==" -ForegroundColor Cyan
    & (Join-Path $tools "selene.exe") src
    if ($LASTEXITCODE -ne 0) { $failed += "selene" }

    Write-Host "`n== Build Rojo ==" -ForegroundColor Cyan
    # Validates default.project.json and the tree without opening Studio.
    & (Join-Path $tools "rojo.exe") build default.project.json --output "$env:TEMP\build-check.rbxl"
    if ($LASTEXITCODE -ne 0) { $failed += "rojo build" }

    Write-Host "`n== Tests ==" -ForegroundColor Cyan
    & (Join-Path $tools "lune.exe") run tests/run
    if ($LASTEXITCODE -ne 0) { $failed += "tests" }
} finally {
    Pop-Location
}

if ($failed.Count -gt 0) {
    Write-Host "`nFailed: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "`nAll green." -ForegroundColor Green
