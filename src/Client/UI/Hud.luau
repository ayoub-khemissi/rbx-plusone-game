--!strict
--[[
	Hud — what stays on screen.

	Three things must be readable in one second of running: how fast I am, how much I
	can spend, and how far the next gate is. The jump and dash indicators sit low and
	centre, where the eyes already are during a jump.

	Every word comes from the theme: this file never hardcodes a noun.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Hud = {}
Hud.__index = Hud

local LABELS = Config.Theme.labels

local function stageName(stageId: number): string
	local stage = Config.Stages[stageId]
	return if stage then stage.name else LABELS.hub.name
end

function Hud.new(parent: ScreenGui, state)
	local self = setmetatable({ state = state }, Hud)

	local card = Widgets.card(parent, {
		name = "Stats",
		size = UDim2.fromOffset(268, 146),
		position = UDim2.fromOffset(14, 14),
	})
	Widgets.padding(card, 12)

	self.speedLabel = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 42),
		font = Theme.font.title,
		color = Theme.color.accent,
		text = `{LABELS.speed.icon} 0`,
	})

	self.coinLabel = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 46),
		font = Theme.font.number,
		text = `{LABELS.coins.icon} 0`,
	})

	self.prestigeLabel = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 74),
		font = Theme.font.body,
		color = Theme.color.textMuted,
	})

	self.stageLabel = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 98),
		font = Theme.font.body,
		color = Theme.color.textMuted,
	})

	self.stageBar = Widgets.bar(card, {
		size = UDim2.new(1, 0, 0, 10),
		position = UDim2.fromOffset(0, 122),
	})

	-- Jump and dash, bottom centre: what the hands are doing.
	self.abilityCard = Widgets.card(parent, {
		name = "Abilities",
		size = UDim2.fromOffset(230, 52),
		position = UDim2.new(0.5, 0, 1, -18),
		anchorPoint = Vector2.new(0.5, 1),
		transparency = 0.2,
	})
	Widgets.padding(self.abilityCard, 8)

	self.jumpLabel = Widgets.label(self.abilityCard, {
		size = UDim2.fromScale(0.5, 1),
		font = Theme.font.number,
		align = Enum.TextXAlignment.Center,
	})

	self.dashLabel = Widgets.label(self.abilityCard, {
		size = UDim2.fromScale(0.5, 1),
		position = UDim2.fromScale(0.5, 0),
		font = Theme.font.number,
		align = Enum.TextXAlignment.Center,
	})

	self.statusCard = Widgets.card(parent, {
		name = "Status",
		size = UDim2.fromOffset(210, 34),
		position = UDim2.new(1, -14, 0, 14),
		anchorPoint = Vector2.new(1, 0),
		visible = false,
	})
	Widgets.padding(self.statusCard, 8)
	self.statusLabel = Widgets.label(self.statusCard, {
		font = Theme.font.number,
		color = Theme.color.positive,
		align = Enum.TextXAlignment.Center,
	})

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function Hud.render(self)
	local state = self.state

	self.speedLabel.Text = `{LABELS.speed.icon} {Format.abbreviate(state:get("Speed"))}`
	self.coinLabel.Text = `{LABELS.coins.icon} {Format.abbreviate(state:get("Coins"))}`
	self.prestigeLabel.Text = `{LABELS.prestige.icon} {state:get("Prestiges")} — {Format.multiplier(
		state:get("SpeedMultiplier")
	)}`

	local reached = math.max(state:get("ReachedStage"), 1)
	local nextRequirement = state:get("NextStageRequirement")
	self.stageLabel.Text = if nextRequirement > 0
		then `{stageName(reached)} → {Format.abbreviate(nextRequirement)}`
		else `{stageName(reached)} — last {LABELS.stage.name}`
	self.stageBar.set(state:get("StageProgress"))

	-- Jump level 1 has no air jump: showing "0/0" would only puzzle the player.
	local jumpLevel = math.max(state:get("JumpLevel"), 1)
	self.jumpLabel.Text = if jumpLevel > 1
		then `🪽 {state:get("JumpsLeft")}/{jumpLevel - 1}`
		else "🪽 —"

	local dashLevel = state:get("DashLevel")
	local cooldown = state:get("DashCooldown")
	if dashLevel <= 0 then
		self.dashLabel.Text = "💨 —"
		self.dashLabel.TextColor3 = Theme.color.locked
	elseif cooldown > 0 then
		self.dashLabel.Text = string.format("💨 %.1fs", cooldown)
		self.dashLabel.TextColor3 = Theme.color.locked
	else
		self.dashLabel.Text = `💨 {dashLevel}`
		self.dashLabel.TextColor3 = Theme.color.positive
	end

	local parts = {}
	for _, boost in state:list("ActiveBoosts") do
		table.insert(parts, `{boost.icon or "⏱"} {math.ceil((boost.remaining or 0) / 60)}m`)
	end
	if state:flag("IdleActive") then
		table.insert(parts, "💤")
	end

	self.statusLabel.Text = table.concat(parts, "  ")
	self.statusCard.Visible = #parts > 0
end

return Hud
