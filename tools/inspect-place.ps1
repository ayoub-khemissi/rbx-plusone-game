<#
    Asks the LIVE place what it contains, through Open Cloud.

    It answers the questions that otherwise need somebody in front of Studio
    reading a properties panel out loud: what is in the Workspace, which tags the
    map actually declares, and how many of each. "The model is there but is it
    tagged" is a five second question here and a five message conversation
    otherwise.

    It runs against the PUBLISHED place, in a sandbox of Roblox's own: the script
    cannot change anything and nothing it does reaches players.

    Needs an API key with two scopes, both on the universe you are asking about:
      * `universe:read`
      * `universe.place.luau-execution-session:write`
    The second is the one an upload-only key will be missing; add it at
    create.roblox.com -> Settings -> Credentials -> API Keys.

    The key is read from icons/api-key.txt or the ROBLOX_API_KEY environment
    variable. It is never printed.

    Usage:  ./tools/inspect-place.ps1 -UniverseId 10759854888
            ./tools/inspect-place.ps1 -UniverseId 10759854888 -Script ./my.luau
#>
param(
    [Parameter(Mandatory = $true)][string]$UniverseId,
    [string]$PlaceId,
    [string]$Script,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

# --- the key ---------------------------------------------------------------
$key = $env:ROBLOX_API_KEY
$keyFile = Join-Path $root "icons/api-key.txt"
if (-not $key -and (Test-Path $keyFile)) {
    $key = (Get-Content $keyFile -Raw).Trim()
}
if (-not $key) {
    Write-Host "No API key. Put it in icons/api-key.txt or set ROBLOX_API_KEY." -ForegroundColor Red
    exit 1
}
$headers = @{ "x-api-key" = $key }

function Invoke-Cloud {
    param([string]$Method, [string]$Url, [string]$Body)
    try {
        if ($Body) {
            return Invoke-RestMethod -Method $Method -Uri $Url -Headers $headers -ContentType "application/json" -Body $Body
        }
        return Invoke-RestMethod -Method $Method -Uri $Url -Headers $headers
    }
    catch {
        Write-Host "$Method $Url" -ForegroundColor DarkGray
        # ErrorDetails holds the response body on 5.1; the stream is the fallback,
        # and is already consumed often enough to be worth having both.
        $text = $_.ErrorDetails.Message
        if (-not $text -and $_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $text = $reader.ReadToEnd()
        }
        if (-not $text) { $text = $_.Exception.Message }
        Write-Host $text -ForegroundColor Red
        if ($text -match "luau-execution-session") {
            Write-Host ""
            Write-Host "The key cannot run scripts in this universe. Add the scope" -ForegroundColor Yellow
            Write-Host "  Luau Execution -> write, on universe $UniverseId" -ForegroundColor Yellow
            Write-Host "at create.roblox.com -> Settings -> Credentials -> API Keys." -ForegroundColor Yellow
        }
        exit 1
    }
}

# --- which place ------------------------------------------------------------
$universe = Invoke-Cloud "GET" "https://apis.roblox.com/cloud/v2/universes/$UniverseId"
Write-Host "$($universe.displayName) - $($universe.visibility)" -ForegroundColor Cyan

if (-not $PlaceId) {
    # rootPlace reads "universes/<u>/places/<p>"; only the last piece is the id.
    $PlaceId = ($universe.rootPlace -split "/")[-1]
}
Write-Host "place $PlaceId" -ForegroundColor DarkGray

# --- what to ask ------------------------------------------------------------
$defaultScript = @'
local CollectionService = game:GetService("CollectionService")

local tags = {}
for _, tag in CollectionService:GetAllTags() do
	table.insert(tags, `{tag} x{#CollectionService:GetTagged(tag)}`)
end
table.sort(tags)
print(`TAGS: {if #tags > 0 then table.concat(tags, ", ") else "none declared"}`)

local children = {}
for _, child in workspace:GetChildren() do
	table.insert(children, `{child.Name} ({child.ClassName})`)
end
table.sort(children)
print(`WORKSPACE: {table.concat(children, ", ")}`)

local sandbox = workspace:GetAttribute("Sandbox")
print(`SANDBOX ATTRIBUTE: {tostring(sandbox)}`)
'@

$source = if ($Script) { Get-Content $Script -Raw } else { $defaultScript }
$body = @{ script = $source } | ConvertTo-Json -Depth 4 -Compress

$base = "https://apis.roblox.com/cloud/v2/universes/$UniverseId/places/$PlaceId"
$task = Invoke-Cloud "POST" "$base/luau-execution-session-tasks" $body

# --- wait for it ------------------------------------------------------------
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ($task.state -in @("STATE_UNSPECIFIED", "QUEUED", "PROCESSING")) {
    if ((Get-Date) -gt $deadline) {
        Write-Host "Timed out after $TimeoutSeconds s (state $($task.state))." -ForegroundColor Red
        exit 1
    }
    Start-Sleep -Milliseconds 1200
    $task = Invoke-Cloud "GET" "https://apis.roblox.com/cloud/v2/$($task.path)"
}

if ($task.state -ne "COMPLETE") {
    Write-Host "Task $($task.state)." -ForegroundColor Red
    if ($task.error) { Write-Host $task.error.message -ForegroundColor Red }
    exit 1
}

# --- what it said -----------------------------------------------------------
$logs = Invoke-Cloud "GET" "https://apis.roblox.com/cloud/v2/$($task.path)/logs"
foreach ($page in $logs.luauExecutionSessionTaskLogs) {
    foreach ($line in $page.messages) {
        Write-Host $line
    }
}
