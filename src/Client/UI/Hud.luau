--!strict
--[[
	Hud — what stays on screen.

	Laid out the way a simulator player already reads a screen: the counters float
	top left with no panel behind them, the run progress sits centre bottom, and the
	abilities sit just above it, where the eyes already are mid jump.

	Nothing here draws a box around a number. A panel would eat the world; a thick
	black stroke on the glyphs keeps the number readable over anything the map puts
	behind it, and costs no screen space at all.

	Every word and every icon comes from the theme: this file hardcodes no noun and
	no asset id.
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
local ICONS = Config.Theme.icons

local function stageName(stageId: number): string
	local stage = Config.Stages[stageId]
	return if stage then stage.name else LABELS.hub.name
end

--[[ One ability readout: a rounded chip with its icon and its state. ]]
local function abilityChip(parent: Instance, options)
	local chip = Widgets.card(parent, {
		name = options.name,
		size = UDim2.fromOffset(124, 46),
		position = options.position,
		anchorPoint = options.anchorPoint,
		color = Theme.color.panel,
		transparency = 0.12,
		radius = Theme.radius.chip,
	})

	Widgets.icon(chip, {
		image = options.image,
		fallback = options.fallback,
		size = UDim2.fromOffset(30, 30),
		position = UDim2.fromOffset(10, 23),
		anchorPoint = Vector2.new(0, 0.5),
	})

	local value = Widgets.label(chip, {
		name = "Value",
		size = UDim2.new(1, -50, 1, 0),
		position = UDim2.fromOffset(46, 0),
		font = Theme.font.number,
		textSize = Theme.text.big,
		align = Enum.TextXAlignment.Center,
		color = Theme.color.text,
	})

	return value
end

function Hud.new(parent: Instance, state)
	local self = setmetatable({ state = state }, Hud)

	-- The counters, stacked top left, biggest first.
	local counters = Instance.new("Frame")
	counters.Name = "Counters"
	counters.Size = UDim2.fromOffset(320, 130)
	counters.Position = UDim2.fromOffset(18, 18)
	counters.BackgroundTransparency = 1
	counters.Parent = parent
	Widgets.list(counters, { padding = 4 })

	self.speedRow = Widgets.statRow(counters, {
		name = "Speed",
		image = LABELS.speed.image,
		fallback = LABELS.speed.icon,
		size = UDim2.new(1, 0, 0, 48),
		iconSize = 44,
		font = Theme.font.title,
		textSize = Theme.text.hero,
		color = Theme.color.accent,
		layoutOrder = 1,
	})

	self.coinRow = Widgets.statRow(counters, {
		name = "Coins",
		image = LABELS.coins.image,
		fallback = LABELS.coins.icon,
		size = UDim2.new(1, 0, 0, 40),
		iconSize = 36,
		font = Theme.font.title,
		textSize = Theme.text.title,
		layoutOrder = 2,
	})

	self.prestigeRow = Widgets.statRow(counters, {
		name = "Prestige",
		image = LABELS.prestige.image,
		fallback = LABELS.prestige.icon,
		size = UDim2.new(1, 0, 0, 30),
		iconSize = 26,
		textSize = Theme.text.body,
		layoutOrder = 3,
	})

	-- The run, centre bottom: the bar the player watches fill.
	self.stageBar = Widgets.bar(parent, {
		name = "StageProgress",
		size = UDim2.fromOffset(460, 38),
		position = UDim2.new(0.5, 0, 1, -18),
		anchorPoint = Vector2.new(0.5, 1),
		color = Theme.color.info,
	})

	self.stageLabel = Widgets.label(self.stageBar.instance, {
		name = "Stage",
		-- Clear of the rounded cap: the track clips its children now.
		size = UDim2.new(0.6, -20, 1, 0),
		position = UDim2.fromOffset(20, 0),
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.textOnColor,
		outline = true,
	})
	self.stageLabel.ZIndex = 3

	self.stageValue = Widgets.label(self.stageBar.instance, {
		name = "Progress",
		size = UDim2.new(0.4, -20, 1, 0),
		position = UDim2.fromScale(0.6, 0),
		font = Theme.font.number,
		textSize = Theme.text.body,
		align = Enum.TextXAlignment.Right,
		color = Theme.color.textOnColor,
		outline = true,
	})
	self.stageValue.ZIndex = 3

	-- The abilities, just above the bar: what the hands are doing.
	self.jumpValue = abilityChip(parent, {
		name = "Jump",
		image = ICONS.jump,
		fallback = "^",
		position = UDim2.new(0.5, -66, 1, -66),
		anchorPoint = Vector2.new(0.5, 1),
	})

	self.dashValue = abilityChip(parent, {
		name = "Dash",
		image = ICONS.dash,
		fallback = ">>",
		position = UDim2.new(0.5, 66, 1, -66),
		anchorPoint = Vector2.new(0.5, 1),
	})

	self.statusCard = Widgets.card(parent, {
		name = "Status",
		size = UDim2.fromOffset(220, 40),
		position = UDim2.new(1, -18, 0, 18),
		anchorPoint = Vector2.new(1, 0),
		radius = Theme.radius.chip,
		visible = false,
	})
	self.statusLabel = Widgets.label(self.statusCard, {
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.text,
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

	self.speedRow.value.Text = Format.abbreviate(state:get("Speed"))
	self.coinRow.value.Text = Format.abbreviate(state:get("Coins"))
	self.prestigeRow.value.Text =
		`{state:get("Prestiges")} — {Format.multiplier(state:get("SpeedMultiplier"))}`

	local reached = math.max(state:get("ReachedStage"), 1)
	local nextRequirement = state:get("NextStageRequirement")
	self.stageLabel.Text = stageName(reached)
	self.stageValue.Text = if nextRequirement > 0
		then `{Format.abbreviate(state:get("Speed"))} / {Format.abbreviate(nextRequirement)}`
		else `last {LABELS.stage.name}`
	self.stageBar.set(state:get("StageProgress"))

	-- Jump level 1 has no air jump: showing "0/0" would only puzzle the player.
	local jumpLevel = math.max(state:get("JumpLevel"), 1)
	if jumpLevel > 1 then
		self.jumpValue.Text = `{state:get("JumpsLeft")}/{jumpLevel - 1}`
		self.jumpValue.TextColor3 = Theme.color.text
	else
		self.jumpValue.Text = "—"
		self.jumpValue.TextColor3 = Theme.color.locked
	end

	local dashLevel = state:get("DashLevel")
	local cooldown = state:get("DashCooldown")
	if dashLevel <= 0 then
		self.dashValue.Text = "—"
		self.dashValue.TextColor3 = Theme.color.locked
	elseif cooldown > 0 then
		self.dashValue.Text = string.format("%.1fs", cooldown)
		self.dashValue.TextColor3 = Theme.color.locked
	else
		self.dashValue.Text = `Lv {dashLevel}`
		self.dashValue.TextColor3 = Theme.color.positive
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
