--!strict
--[[
	State — local mirror of the state replicated by the server.

	The server pushes everything through player attributes; this module reads them,
	decodes the JSON ones and tells the interface. No view ever reads an attribute
	directly, so replacing the transport would be invisible to them.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Signal = require(Shared.Signal)

local State = {}
State.__index = State

local NUMBERS = {
	"Speed",
	"Coins",
	"Prestiges",
	"Level",
	"LevelCurrent",
	"LevelRequired",
	"LevelProgress",
	"HighestStage",
	"ReachedStage",
	"StageId",
	"WalkSpeed",
	"JumpPower",
	"JumpLevel",
	"JumpsLeft",
	"DashLevel",
	"DashMultiplier",
	"DashPower",
	"DashCooldown",
	"Magnet",
	"Saturation",
	"SpeedMultiplier",
	"CoinMultiplier",
	"BoostSpeed",
	"BoostCoins",
	"PrestigeMultiplier",
	"PrestigeRequirement",
	"PrestigeProgress",
	"StageProgress",
	"NextStageRequirement",
	"IdleRemaining",
}

local FLAGS = { "HasCheckpoint", "IdleActive", "DashUnlocked" }

local TABLES = { "ActiveBoosts" }

function State.new(player: Player)
	local self = setmetatable({
		player = player,
		values = {},
		flags = {},
		tables = {},
		upgrades = {},
		passes = {},
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

	for _, name in FLAGS do
		self.flags[name] = self.player:GetAttribute(name) == true
	end

	for _, name in TABLES do
		local encoded = self.player:GetAttribute(name)
		if typeof(encoded) == "string" then
			local ok, decoded = pcall(HttpService.JSONDecode, HttpService, encoded)
			self.tables[name] = if ok and typeof(decoded) == "table" then decoded else {}
		else
			self.tables[name] = self.tables[name] or {}
		end
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

	self.changed:fire(self)
end

function State.get(self, name: string): number
	return self.values[name] or 0
end

function State.flag(self, name: string): boolean
	return self.flags[name] == true
end

function State.list(self, name: string)
	return self.tables[name] or {}
end

function State.levelOf(self, upgradeId: string): number
	return self.upgrades[upgradeId] or 0
end

function State.owns(self, passId: string): boolean
	return self.passes[passId] == true
end

return State
