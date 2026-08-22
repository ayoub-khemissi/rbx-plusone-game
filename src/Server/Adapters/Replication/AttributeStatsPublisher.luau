--!strict
--[[
	AttributeStatsPublisher — port StatsPublisher via les ATTRIBUTS du joueur.

	Choix d'architecture : plutot qu'un flux de RemoteEvents, l'etat est pousse dans
	des attributs repliques automatiquement par Roblox. Le client se contente
	d'ecouter `GetAttributeChangedSignal`. Moins de reseau, aucune desynchronisation
	possible, et l'etat reste inspectable depuis Studio.

	Les valeurs identiques ne sont pas reecrites : pas de replication inutile.
]]

local HttpService = game:GetService("HttpService")

local AttributeStatsPublisher = {}
AttributeStatsPublisher.__index = AttributeStatsPublisher

local SCALARS = {
	Speed = "speed",
	Bananas = "bananas",
	Rebirths = "rebirths",
	ZoneId = "zoneId",
	HighestZone = "highestZone",
	HighestUnlockedZone = "highestUnlockedZone",
	WalkSpeed = "walkSpeed",
	JumpPower = "jumpPower",
	WallGrip = "wallGrip",
	AirDash = "airDash",
	SpeedMultiplier = "speedMultiplier",
	BananaMultiplier = "bananaMultiplier",
	RebirthMultiplier = "rebirthMultiplier",
	RebirthRequirement = "rebirthRequirement",
	RebirthProgress = "rebirthProgress",
	ZoneProgress = "zoneProgress",
	BoostSpeed = "boostSpeed",
	BoostBananas = "boostBananas",
	AfkRemaining = "afkRemaining",
}

local FLAGS = {
	AfkActive = "afkActive",
}

function AttributeStatsPublisher.new()
	return setmetatable({}, AttributeStatsPublisher)
end

local function setIfChanged(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

--[[ Cree les leaderstats visibles dans la liste des joueurs. ]]
function AttributeStatsPublisher.setupPlayer(_self, player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local speed = Instance.new("IntValue")
	speed.Name = "Vitesse"
	speed.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Renaissances"
	rebirths.Parent = leaderstats

	leaderstats.Parent = player
end

function AttributeStatsPublisher.publish(_self, player: Player, snapshot: any)
	if not player or not player.Parent then
		return
	end

	for attribute, field in SCALARS do
		local value = snapshot[field]
		if typeof(value) == "number" then
			setIfChanged(player, attribute, value)
		end
	end

	for attribute, field in FLAGS do
		setIfChanged(player, attribute, snapshot[field] == true)
	end

	for upgradeId, level in snapshot.upgrades do
		setIfChanged(player, `Upg_{upgradeId}`, level)
	end

	for passId, owned in snapshot.passes do
		setIfChanged(player, `Pass_{passId}`, owned == true)
	end

	-- Les attributs ne stockent pas de table : les boosts actifs passent en JSON.
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, snapshot.activeBoosts or {})
	if ok then
		setIfChanged(player, "ActiveBoosts", encoded)
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local speed = leaderstats:FindFirstChild("Vitesse")
		if speed then
			(speed :: IntValue).Value = math.floor(snapshot.speed)
		end
		local rebirths = leaderstats:FindFirstChild("Renaissances")
		if rebirths then
			(rebirths :: IntValue).Value = snapshot.rebirths
		end
	end
end

return AttributeStatsPublisher
