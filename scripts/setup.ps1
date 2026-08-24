<#
    Installs the local toolchain (Rojo, Lune, Selene, StyLua) into .tools/
    and generates the standard Roblox definition Selene needs.

    Usage:  ./scripts/setup.ps1
#>
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root ".tools"
New-Item -ItemType Directory -Force $tools | Out-Null

$downloads = @(
    @{ Name = "rojo";   Url = "https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-windows-x86_64.zip" },
    @{ Name = "lune";   Url = "https://github.com/lune-org/lune/releases/download/v0.10.5/lune-0.10.5-windows-x86_64.zip" },
    @{ Name = "selene"; Url = "https://github.com/Kampfkarren/selene/releases/download/0.31.0/selene-0.31.0-windows.zip" },
    @{ Name = "stylua"; Url = "https://github.com/JohnnyMorganz/StyLua/releases/download/v2.5.2/stylua-windows-x86_64.zip" }
)

foreach ($item in $downloads) {
    $exe = Join-Path $tools "$($item.Name).exe"
    if (Test-Path $exe) { Write-Host "$($item.Name) already installed"; continue }
    $zip = Join-Path $tools "$($item.Name).zip"
    Write-Host "Downloading $($item.Name)..."
    Invoke-WebRequest -Uri $item.Url -OutFile $zip -TimeoutSec 300
    Expand-Archive -Path $zip -DestinationPath $tools -Force
    Remove-Item $zip
}

Push-Location $root
try {
    if (-not (Test-Path (Join-Path $root "roblox.yml"))) {
        Write-Host "Generating the Roblox std for Selene..."
        & (Join-Path $tools "selene.exe") generate-roblox-std
    }
} finally {
    Pop-Location
}

# The sourcemap is what gives luau-lsp autocompletion and types in the editor.
Push-Location $root
try {
    & (Join-Path $tools "rojo.exe") sourcemap default.project.json --output sourcemap.json
    Write-Host "sourcemap.json generated"
} finally {
    Pop-Location
}

Write-Host "Toolchain ready."
Write-Host "  ./scripts/check.ps1   checks everything"
Write-Host "  ./scripts/serve.ps1   serves the project to Roblox Studio"
