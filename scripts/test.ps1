<#
    Runs the test suite, with an optional filter on the spec path.
    Usage:  ./scripts/test.ps1            |  ./scripts/test.ps1 economy
#>
param([string]$Filter)
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    if ($Filter) {
        & (Join-Path $root ".tools/lune.exe") run tests/run $Filter
    } else {
        & (Join-Path $root ".tools/lune.exe") run tests/run
    }
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
