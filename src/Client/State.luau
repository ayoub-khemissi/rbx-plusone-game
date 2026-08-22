--!strict
--[[
	State — miroir local de l'etat repliqué par le serveur.

	Le serveur pousse tout via des attributs joueur ; ce module les lit, les met en
	forme et previent l'interface. Aucune vue ne lit d'attribut directement : elles
	consomment cet objet, ce qui rend le remplacement du transport transparent.
]]

local HttpService = game:GetService("HttpService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Signal = require(Shared.Signal)

local State = {}
State.__index = State

local NUMBERS = {
	"Speed",
	"Bananas",
	"Rebirths",
	"ZoneId",
	"HighestZone",
	"HighestUnlockedZone",
	"WalkSpeed",
	"JumpPower",
	"WallGrip",
	"AirDash",
	"SpeedMultiplier",
	"BananaMultiplier",
	"RebirthMultiplier",
	"RebirthRequirement",
	"RebirthProgress",
	"ZoneProgress",
	"BoostSpeed",
	"BoostBananas",
}

function State.new(player: Player)
	local self = setmetatable({
		player = player,
		values = {},
		upgrades = {},
		passes = {},
		boosts = {},
		changed = Signal.new(),
	}, State)

	self:_refresh()
	player.AttributeChanged:Connect(function()
		self:_refresh()
	end)

	return self
end

function State._refresh(self)
	for _, name in NUMBERS do
		self.values[name] = self.player:GetAttribute(name) or 0
	end

	self.upgrades = {}
	self.passes = {}
	for name, value in self.player:GetAttributes() do
		local upgradeId = string.match(name, "^Upg_(.+)$")
		if upgradeId then
			self.upgrades[upgradeId] = value
		end
		local passId = string.match(name, "^Pass_(.+)$")
		if passId then
			self.passes[passId] = value == true
		end
	end

	local encoded = self.player:GetAttribute("ActiveBoosts")
	if typeof(encoded) == "string" then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, encoded)
		self.boosts = if ok and typeof(decoded) == "table" then decoded else {}
	end

	self.changed:fire(self)
end

function State.get(self, name: string): number
	return self.values[name] or 0
end

function State.levelOf(self, upgradeId: string): number
	return self.upgrades[upgradeId] or 0
end

function State.owns(self, passId: string): boolean
	return self.passes[passId] == true
end

return State
