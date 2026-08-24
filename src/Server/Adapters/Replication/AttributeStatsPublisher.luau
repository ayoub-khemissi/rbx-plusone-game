--!strict
--[[
	AttributeStatsPublisher — port StatsPublisher, backed by player ATTRIBUTES.

	Architectural choice: instead of a stream of RemoteEvents, the state is pushed
	into attributes that Roblox replicates on its own. The client just listens on
	`GetAttributeChangedSignal`. Less network, no possible desynchronisation, and the
	state stays inspectable from Studio.

	Identical values are not rewritten, so nothing replicates for nothing.
]]

local HttpService = game:GetService("HttpService")

local AttributeStatsPublisher = {}
AttributeStatsPublisher.__index = AttributeStatsPublisher

local NUMBERS = {
	Speed = "speed",
	Gold = "gold",
	Molts = "molts",
	DeepestTier = "deepestTier",
	ReachedTier = "reachedTier",
	TierId = "tierId",
	Feathers = "feathers",
	InsuredFlights = "insuredFlights",
	PouchGold = "pouchGold",
	PouchEggs = "pouchEggs",
	PouchTier = "pouchTier",
	Velocity = "velocity",
	Agility = "agility",
	Magnet = "magnet",
	Saturation = "saturation",
	SpeedMultiplier = "speedMultiplier",
	GoldMultiplier = "goldMultiplier",
	BoostSpeed = "boostSpeed",
	BoostGold = "boostGold",
	MoltMultiplier = "moltMultiplier",
	MoltRequirement = "moltRequirement",
	MoltProgress = "moltProgress",
	TierProgress = "tierProgress",
	NextTierRequirement = "nextTierRequirement",
}

local FLAGS = {
	Flying = "flying",
	Insured = "insured",
}

-- Attributes cannot hold tables: these travel as JSON.
local TABLES = {
	Hatchery = "hatchery",
	Eggs = "eggs",
	Dragons = "dragons",
	ActiveBoosts = "activeBoosts",
	Collection = "collection",
}

function AttributeStatsPublisher.new()
	return setmetatable({}, AttributeStatsPublisher)
end

local function setIfChanged(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

--[[ Builds the leaderstats shown in the player list. ]]
function AttributeStatsPublisher.setupPlayer(_self, player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local speed = Instance.new("IntValue")
	speed.Name = "Speed"
	speed.Parent = leaderstats

	local molts = Instance.new("IntValue")
	molts.Name = "Molts"
	molts.Parent = leaderstats

	leaderstats.Parent = player
end

function AttributeStatsPublisher.publish(_self, player: Player, snapshot: any)
	if not player or not player.Parent then
		return
	end

	for attribute, field in NUMBERS do
		local value = snapshot[field]
		if typeof(value) == "number" then
			setIfChanged(player, attribute, value)
		end
	end

	for attribute, field in FLAGS do
		setIfChanged(player, attribute, snapshot[field] == true)
	end

	for attribute, field in TABLES do
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, snapshot[field] or {})
		if ok then
			setIfChanged(player, attribute, encoded)
		end
	end

	for upgradeId, level in snapshot.upgrades do
		setIfChanged(player, `Upg_{upgradeId}`, level)
	end

	for passId, owned in snapshot.passes do
		setIfChanged(player, `Pass_{passId}`, owned == true)
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local speed = leaderstats:FindFirstChild("Speed")
		if speed then
			(speed :: IntValue).Value = math.floor(snapshot.speed)
		end
		local molts = leaderstats:FindFirstChild("Molts")
		if molts then
			(molts :: IntValue).Value = snapshot.molts
		end
	end
end

return AttributeStatsPublisher
