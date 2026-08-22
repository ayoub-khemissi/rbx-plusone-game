<#
    Verification complete : format, lint, tests.
    Usage :  ./scripts/check.ps1  [-Fix]
#>
param([switch]$Fix)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root ".tools"
Push-Location $root

$failed = @()

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
    # Valide default.project.json et l'arborescence sans ouvrir Studio.
    & (Join-Path $tools "rojo.exe") build default.project.json --output "$env:TEMP\singe-check.rbxl"
    if ($LASTEXITCODE -ne 0) { $failed += "rojo build" }

    Write-Host "`n== Tests ==" -ForegroundColor Cyan
    & (Join-Path $tools "lune.exe") run tests/run
    if ($LASTEXITCODE -ne 0) { $failed += "tests" }
} finally {
    Pop-Location
}

if ($failed.Count -gt 0) {
    Write-Host "`nEchec : $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "`nTout est vert." -ForegroundColor Green
