<#
    Serves the project to Roblox Studio.

    1. Run this script
    2. In Studio: Rojo plugin -> Connect
    3. The code syncs live on every file save

    Open the place holding your map: the server reads it through tags, and builds
    nothing of its own.
#>
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    & (Join-Path $root ".tools/rojo.exe") serve default.project.json
} finally {
    Pop-Location
}
