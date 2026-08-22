<#
    Sert le projet vers Roblox Studio.

    1. Lance ce script
    2. Dans Studio : plugin Rojo -> Connect
    3. Le code se synchronise en direct a chaque sauvegarde de fichier

    La carte est generee par le serveur au demarrage : rien a construire a la main.
#>
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    & (Join-Path $root ".tools/rojo.exe") serve default.project.json
} finally {
    Pop-Location
}
