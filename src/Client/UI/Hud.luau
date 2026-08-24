--!strict
--[[
	Hud — what stays on screen.

	NOTHING IS DRAWN IN THE TOP LEFT. That corner belongs to Roblox: the menu, the
	chat and the voice controls live there, and anything of ours put behind them is
	either hidden or in the way. Everything gathers at the bottom instead, in one
	cluster the eye finds once and never has to search for again.

	No counter sits in a panel of its own. A panel would eat the world; a thick
	black stroke on the glyphs keeps a number readable over anything the map puts
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

local BAR_INSET = 20

local function stageName(stageId: number): string
	local stage = Config.Stages[stageId]
	return if stage then stage.name else LABELS.hub.name
end

--[[
	One readout: a rounded chip carrying an icon and a value.

	It has no position and no width of its own. The row lays it out, and it grows
	to fit its content, so a six figure Coin count does not overflow a box sized
	for three. A chip hidden because the thing it reports does not exist yet leaves
	the layout entirely and the row recentres itself.
]]
local function chip(parent: Instance, options)
	local frame = Widgets.card(parent, {
		name = options.name,
		size = UDim2.fromOffset(0, 46),
		color = Theme.color.panel,
		transparency = 0.12,
		radius = Theme.radius.chip,
		pattern = false,
		visible = false,
	})
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.LayoutOrder = options.layoutOrder or 0

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = frame

	Widgets.list(frame, {
		direction = Enum.FillDirection.Horizontal,
		padding = 8,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	Widgets.icon(frame, {
		image = options.image,
		fallback = options.fallback,
		size = UDim2.fromOffset(28, 28),
		layoutOrder = 1,
	})

	local value = Widgets.label(frame, {
		name = "Value",
		size = UDim2.fromOffset(0, 30),
		font = Theme.font.number,
		textSize = Theme.text.big,
		align = Enum.TextXAlignment.Left,
		color = Theme.color.text,
		layoutOrder = 2,
	})
	value.AutomaticSize = Enum.AutomaticSize.X

	return { frame = frame, value = value }
end

function Hud.new(parent: Instance, state)
	local self = setmetatable({ state = state }, Hud)

	-- The run, centre bottom: the bar the player watches fill.
	self.stageBar = Widgets.bar(parent, {
		name = "StageProgress",
		size = UDim2.fromOffset(480, 40),
		position = UDim2.new(0.5, 0, 1, -18),
		anchorPoint = Vector2.new(0.5, 1),
		color = Theme.color.info,
	})

	self.stageLabel = Widgets.label(self.stageBar.instance, {
		name = "Stage",
		-- Clear of the rounded cap: the glyphs must stay in the middle band, where
		-- the shape is at full width.
		size = UDim2.new(0.5, -BAR_INSET, 1, 0),
		position = UDim2.fromOffset(BAR_INSET, 0),
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.textOnColor,
		outline = true,
	})
	self.stageLabel.ZIndex = 3

	-- Progress reads "331/1K" followed by the speed icon: the unit is shown, never
	-- spelled. The pair hangs from a right anchor and grows leftwards, so a long
	-- number reaches into the bar instead of off the end of it.
	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.Size = UDim2.fromOffset(0, 30)
	progress.AutomaticSize = Enum.AutomaticSize.X
	progress.Position = UDim2.new(1, -BAR_INSET, 0.5, 0)
	progress.AnchorPoint = Vector2.new(1, 0.5)
	progress.BackgroundTransparency = 1
	progress.ZIndex = 3
	progress.Parent = self.stageBar.instance
	Widgets.list(progress, {
		direction = Enum.FillDirection.Horizontal,
		padding = 6,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	self.stageValue = Widgets.label(progress, {
		name = "Value",
		size = UDim2.fromOffset(0, 30),
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.textOnColor,
		outline = true,
		layoutOrder = 1,
	})
	self.stageValue.AutomaticSize = Enum.AutomaticSize.X
	self.stageValue.ZIndex = 3

	local speedIcon = Widgets.icon(progress, {
		name = "SpeedIcon",
		image = LABELS.speed.image,
		fallback = LABELS.speed.icon,
		size = UDim2.fromOffset(26, 26),
		layoutOrder = 2,
	})
	speedIcon.ZIndex = 3

	-- Everything else, in one centred row just above the bar.
	local row = Instance.new("Frame")
	row.Name = "Status"
	row.Size = UDim2.fromOffset(0, 46)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Position = UDim2.new(0.5, 0, 1, -68)
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.BackgroundTransparency = 1
	row.Parent = parent
	Widgets.list(row, {
		direction = Enum.FillDirection.Horizontal,
		padding = 8,
		horizontalAlignment = Enum.HorizontalAlignment.Center,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	self.coins = chip(row, {
		name = "Coins",
		image = LABELS.coins.image,
		fallback = LABELS.coins.icon,
		layoutOrder = 1,
	})

	self.prestige = chip(row, {
		name = "Prestige",
		image = LABELS.prestige.image,
		fallback = LABELS.prestige.icon,
		layoutOrder = 2,
	})

	self.jump = chip(row, {
		name = "Jump",
		image = ICONS.jump,
		fallback = "^",
		layoutOrder = 3,
	})

	self.dash = chip(row, {
		name = "Dash",
		image = ICONS.dash,
		fallback = ">>",
		layoutOrder = 4,
	})

	self.boosts = chip(row, {
		name = "Boosts",
		image = ICONS.boost,
		fallback = "*",
		layoutOrder = 5,
	})

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function Hud.render(self)
	local state = self.state

	local reached = math.max(state:get("ReachedStage"), 1)
	local nextRequirement = state:get("NextStageRequirement")
	self.stageLabel.Text = stageName(reached)
	self.stageValue.Text = if nextRequirement > 0
		then `{Format.abbreviate(state:get("Speed"))}/{Format.abbreviate(nextRequirement)}`
		else Format.abbreviate(state:get("Speed"))
	self.stageBar.set(state:get("StageProgress"))

	self.coins.frame.Visible = true
	self.coins.value.Text = Format.abbreviate(state:get("Coins"))

	-- A player who has never prestiged has nothing to read here, and a "0" only
	-- raises the question of what it is for.
	local prestiges = state:get("Prestiges")
	self.prestige.frame.Visible = prestiges > 0
	if self.prestige.frame.Visible then
		self.prestige.value.Text = `{prestiges}  {Format.multiplier(state:get("SpeedMultiplier"))}`
	end

	-- Level 1 is the jump everybody already has: there is no air jump to count.
	local jumpLevel = math.max(state:get("JumpLevel"), 1)
	self.jump.frame.Visible = jumpLevel > 1
	if self.jump.frame.Visible then
		self.jump.value.Text = `{state:get("JumpsLeft")}/{jumpLevel - 1}`
		self.jump.value.TextColor3 = Theme.color.text
	end

	local dashLevel = state:get("DashLevel")
	local cooldown = state:get("DashCooldown")
	self.dash.frame.Visible = dashLevel > 0
	if self.dash.frame.Visible then
		if cooldown > 0 then
			self.dash.value.Text = string.format("%.1fs", cooldown)
			self.dash.value.TextColor3 = Theme.color.locked
		else
			self.dash.value.Text = `Lv {dashLevel}`
			self.dash.value.TextColor3 = Theme.color.positive
		end
	end

	local parts = {}
	for _, boost in state:list("ActiveBoosts") do
		table.insert(parts, `{math.ceil((boost.remaining or 0) / 60)}m`)
	end
	if state:flag("IdleActive") then
		table.insert(parts, "AFK")
	end

	self.boosts.frame.Visible = #parts > 0
	self.boosts.value.Text = table.concat(parts, " ")
end

return Hud
