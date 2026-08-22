<#
    Installe la chaine d'outils locale (Lune, Selene, StyLua) dans .tools/
    et genere la definition standard Roblox pour Selene.

    Usage :  ./scripts/setup.ps1
#>
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root ".tools"
New-Item -ItemType Directory -Force $tools | Out-Null

$downloads = @(
    @{ Name = "lune";   Url = "https://github.com/lune-org/lune/releases/download/v0.10.5/lune-0.10.5-windows-x86_64.zip" },
    @{ Name = "selene"; Url = "https://github.com/Kampfkarren/selene/releases/download/0.31.0/selene-0.31.0-windows.zip" },
    @{ Name = "stylua"; Url = "https://github.com/JohnnyMorganz/StyLua/releases/download/v2.5.2/stylua-windows-x86_64.zip" }
)

foreach ($item in $downloads) {
    $exe = Join-Path $tools "$($item.Name).exe"
    if (Test-Path $exe) { Write-Host "$($item.Name) deja installe"; continue }
    $zip = Join-Path $tools "$($item.Name).zip"
    Write-Host "Telechargement de $($item.Name)..."
    Invoke-WebRequest -Uri $item.Url -OutFile $zip -TimeoutSec 300
    Expand-Archive -Path $zip -DestinationPath $tools -Force
    Remove-Item $zip
}

Push-Location $root
try {
    if (-not (Test-Path (Join-Path $root "roblox.yml"))) {
        Write-Host "Generation de la std Roblox pour Selene..."
        & (Join-Path $tools "selene.exe") generate-roblox-std
    }
} finally {
    Pop-Location
}

Write-Host "Chaine d'outils prete. Lance ./scripts/check.ps1"
