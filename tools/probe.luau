--[[
	probe — audit a map offline, without opening Studio.

	Reads a .rbxl and reports what the server would find at start-up: the tagged
	parts, their attributes, the SpawnLocation, and the void level. Running it
	before a play test turns "nothing happens when I touch it" into a one-line
	answer: the tag is missing.

	Usage: ./.tools/lune.exe run tools/probe [path/to/place.rbxl]
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local PLACE = process.args[1] or "maps/Place1.rbxl"

-- Mirrors MapBindings: the tags the server actually looks for.
local TAGS = {
	"Checkpoint",
	"TrapPart",
	"Killzone",
	"Conveyor",
	"BouncePad",
	"Coin",
	"SpeedGate",
	"ShopPad",
	"PrestigePad",
	"AfkPad",
}

local VOID_MARGIN = 80

local place = roblox.deserializePlace(fs.readFile(PLACE))
local world = place:GetService("Workspace")

local function attributesOf(instance): string
	local pairsOut = {}
	local ok, attributes = pcall(function()
		return instance:GetAttributes()
	end)
	if ok and attributes then
		for key, value in attributes do
			table.insert(pairsOut, `{key}={tostring(value)}`)
		end
	end
	table.sort(pairsOut)
	return table.concat(pairsOut, " ")
end

-- Lune exposes what the file stores: a BasePart has a CFrame, not a Position.
local function pointOf(instance): Vector3?
	local ok, cframe = pcall(function()
		return instance.CFrame
	end)
	return if ok and cframe then cframe.Position else nil
end

local function positionOf(instance): string
	local point = pointOf(instance)
	if not point then
		return "-"
	end
	return string.format("%.0f,%.0f,%.0f", point.X, point.Y, point.Z)
end

-- One pass over the map: tags, spawn and lowest part all come from the same walk.
local tagged = {}
for _, tag in TAGS do
	tagged[tag] = {}
end

local spawn = nil
local lowest = math.huge

for _, descendant in world:GetDescendants() do
	local ok, tags = pcall(function()
		return descendant:GetTags()
	end)
	if ok then
		for _, tag in tags do
			if tagged[tag] then
				table.insert(tagged[tag], descendant)
			end
		end
	end

	if not spawn and descendant.ClassName == "SpawnLocation" then
		spawn = descendant
	end

	local point = pointOf(descendant)
	if point then
		local ok, size = pcall(function()
			return descendant.Size
		end)
		local bottom = point.Y - (if ok and size then size.Y / 2 else 0)
		if bottom < lowest then
			lowest = bottom
		end
	end
end

print(`=== {PLACE} ===`)

for _, tag in TAGS do
	local instances = tagged[tag]
	if #instances > 0 then
		print(`\n[{tag}] {#instances}`)
		for _, instance in instances do
			print(
				string.format(
					"  %-24s %-12s pos %-18s %s",
					instance.Name,
					instance.ClassName,
					positionOf(instance),
					attributesOf(instance)
				)
			)
		end
	end
end

print("\n[SpawnLocation]")
if spawn then
	print(`  {spawn.Name} at {positionOf(spawn)}`)
else
	print("  MISSING — falls with no checkpoint will land at the origin")
end

print("\n[Void level]")
if lowest < math.huge then
	print(`  lowest part at {math.floor(lowest)}, void at {math.floor(lowest - VOID_MARGIN)}`)
else
	print("  empty map, falls will not be detected")
end

-- Scripts that would fight the server for the same tags.
local server = place:GetService("ServerScriptService")
local scripts = {}
for _, descendant in server:GetDescendants() do
	if descendant.ClassName == "Script" or descendant.ClassName == "ModuleScript" then
		table.insert(scripts, descendant.Name)
	end
end

if #scripts > 0 then
	print("\n[ServerScriptService] scripts shipped inside the place, they run alongside the server")
	for _, name in scripts do
		print(`  {name}`)
	end
end
