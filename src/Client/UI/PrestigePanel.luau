--!strict
--[[
	PrestigePanel — the trade, laid out side by side.

	A Rebirth takes everything the player has and gives back a number. Written as a
	sentence that is a paragraph nobody reads while standing on a pad; laid out as
	BEFORE and AFTER, on one row per thing that changes, it is read in a glance and
	argued with immediately — which is the point. The player should be able to see
	what they are about to lose without doing arithmetic.

	Green rows are what grows, red rows are what goes. That colouring is the whole
	explanation, and it is why the warning underneath can be one short line instead
	of the paragraph this panel used to open with.

	Nothing here decides anything. It reads state and fires the same remote the pad
	used to fire on contact — the difference being that a player pressed it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local PrestigePanel = {}
PrestigePanel.__index = PrestigePanel

local LABELS = Config.Theme.labels
local GROWTH = Config.Balance.prestige.multiplierGrowth

local ROW_HEIGHT = 52
local ROW_GAP = 10
local COLUMN_GAP = 44 -- room for the arrow between the two columns
local HEADER_Y = 4
local ROWS_Y = 38

--[[ The product that skips the cost, if the place has one published. ]]
local function instantProduct()
	for _, product in Config.Products do
		if product.id == "instantPrestige" then
			return product
		end
	end
	return nil
end

--[[
	One side of one comparison: a filled pill carrying an icon and a value.

	The pill is coloured by what the row MEANS — growth or loss — rather than by
	which column it sits in, so the eye finds the cost without reading a word.
]]
local function pill(parent: Instance, options)
	local frame = Widgets.card(parent, {
		name = options.name,
		size = UDim2.new(0.5, -COLUMN_GAP / 2, 0, ROW_HEIGHT),
		position = options.position,
		color = options.color,
		radius = Theme.radius.button,
	})
	Widgets.gradient(frame, 0.3)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = frame

	Widgets.list(frame, {
		direction = Enum.FillDirection.Horizontal,
		padding = 10,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	Widgets.icon(frame, {
		image = options.image,
		fallback = options.fallback,
		size = UDim2.fromOffset(30, 30),
		layoutOrder = 1,
	})

	local value = Widgets.label(frame, {
		name = "Value",
		size = UDim2.new(1, -42, 1, 0),
		font = Theme.font.title,
		textSize = Theme.text.body,
		align = Enum.TextXAlignment.Left,
		color = Theme.color.textOnColor,
		outline = Theme.stroke.text,
		layoutOrder = 2,
	})

	return value
end

--[[ The arrow between the two columns: this becomes that. ]]
local function arrow(parent: Instance, y: number)
	local mark = Widgets.label(parent, {
		name = "Arrow",
		size = UDim2.fromOffset(COLUMN_GAP, ROW_HEIGHT),
		position = UDim2.new(0.5, 0, 0, y),
		anchorPoint = Vector2.new(0.5, 0),
		font = Theme.font.title,
		textSize = Theme.text.title,
		color = Theme.color.textMuted,
		text = "▶",
	})
	return mark
end

--[[ A whole comparison line: before, arrow, after. ]]
local function comparison(parent: Instance, index: number, options)
	local y = ROWS_Y + (index - 1) * (ROW_HEIGHT + ROW_GAP)

	local before = pill(parent, {
		name = `{options.name}Before`,
		position = UDim2.fromOffset(0, y),
		color = options.color,
		image = options.image,
		fallback = options.fallback,
	})
	arrow(parent, y)
	local after = pill(parent, {
		name = `{options.name}After`,
		position = UDim2.new(1, 0, 0, y),
		color = options.after or options.color,
		image = options.image,
		fallback = options.fallback,
	})
	after.Parent.AnchorPoint = Vector2.new(1, 0)

	return { before = before, after = after }
end

function PrestigePanel.new(parent: Instance, state, remotes)
	local rows = 3
	local barY = ROWS_Y + rows * (ROW_HEIGHT + ROW_GAP) + 34
	local panel = Panel.new(parent, {
		name = "Prestige",
		title = string.upper(LABELS.prestige.name),
		size = UDim2.fromOffset(620, barY + 160),
	})
	local self = setmetatable({ panel = panel, state = state, remotes = remotes }, PrestigePanel)

	local function header(text: string, position: UDim2, anchor: Vector2)
		local label = Widgets.label(panel.content, {
			size = UDim2.new(0.5, -COLUMN_GAP / 2, 0, 26),
			position = position,
			anchorPoint = anchor,
			font = Theme.font.title,
			textSize = Theme.text.body,
			color = Theme.color.textMuted,
			text = text,
		})
		return label
	end

	header("BEFORE", UDim2.fromOffset(0, HEADER_Y), Vector2.zero)
	header("AFTER", UDim2.new(1, 0, 0, HEADER_Y), Vector2.new(1, 0))

	-- What grows, then what goes. The order is the argument.
	self.multiplier = comparison(panel.content, 1, {
		name = "Multiplier",
		color = Theme.color.positive,
		image = LABELS.prestige.image,
		fallback = LABELS.prestige.icon,
	})
	self.level = comparison(panel.content, 2, {
		name = "Level",
		color = Theme.color.info,
		after = Theme.color.negative,
		image = LABELS.level.image,
		fallback = LABELS.level.icon,
	})
	self.coins = comparison(panel.content, 3, {
		name = "Coins",
		color = Theme.color.accentDark,
		after = Theme.color.negative,
		image = LABELS.coins.image,
		fallback = LABELS.coins.icon,
	})

	self.warning = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 24),
		position = UDim2.fromOffset(0, barY - 30),
		font = Theme.font.title,
		textSize = Theme.text.small,
		color = Theme.color.negative,
		text = `A {LABELS.prestige.name} clears your {LABELS.speed.name}, your {LABELS.coins.plural} and your upgrades.`,
	})

	-- The same bar the HUD wears, so the number a player is chasing looks the same
	-- wherever they read it.
	self.bar = Widgets.bar(panel.content, {
		size = UDim2.new(1, 0, 0, 40),
		position = UDim2.fromOffset(0, barY),
		color = Theme.color.positive,
		sheen = true,
	})

	self.barLabel = Widgets.label(self.bar.instance, {
		name = "Level",
		size = UDim2.new(0.6, -20, 1, 0),
		position = UDim2.fromOffset(18, 0),
		font = Theme.font.number,
		textSize = Theme.text.body,
		align = Enum.TextXAlignment.Left,
		color = Theme.color.textOnColor,
		outline = true,
	})
	self.barLabel.ZIndex = 3

	self.barValue = Widgets.label(self.bar.instance, {
		name = "Value",
		size = UDim2.new(0.4, -20, 1, 0),
		position = UDim2.new(1, -18, 0, 0),
		anchorPoint = Vector2.new(1, 0),
		font = Theme.font.number,
		textSize = Theme.text.body,
		align = Enum.TextXAlignment.Right,
		color = Theme.color.textOnColor,
		outline = true,
	})
	self.barValue.ZIndex = 3

	local product = instantProduct()
	local buttonWidth = if product then UDim2.new(0.5, -8, 0, 62) else UDim2.new(1, 0, 0, 62)

	self.action = Widgets.button(panel.content, {
		text = string.upper(LABELS.prestige.verb or LABELS.prestige.name),
		size = buttonWidth,
		position = UDim2.fromScale(0, 1),
		anchorPoint = Vector2.new(0, 1),
		color = Theme.color.special,
		textSize = Theme.text.big,
		onClick = function()
			self.remotes.events.Prestige:FireServer()
		end,
	})

	--[[
		The paid way out, when the place has published the product. It skips the
		cost rather than the wait: the upgrades survive, which is the whole of what
		is being sold — see docs/MONETISATION.md.
	]]
	if product then
		self.skip = Widgets.button(panel.content, {
			name = "Skip",
			text = string.upper(product.name),
			size = UDim2.new(0.5, -8, 0, 62),
			position = UDim2.fromScale(1, 1),
			anchorPoint = Vector2.new(1, 1),
			color = Theme.color.accentDark,
			textSize = Theme.text.body,
			onClick = function()
				self.remotes.events.PromptPurchase:FireServer("product", product.id)
			end,
		})

		Widgets.label(self.skip, {
			name = "Note",
			size = UDim2.new(1, -16, 0, 18),
			position = UDim2.new(0.5, 0, 1, -8),
			anchorPoint = Vector2.new(0.5, 1),
			font = Theme.font.body,
			textSize = Theme.text.small,
			color = Theme.color.textOnColor,
			outline = true,
			text = if product.robux
				then `R$ {product.robux} — KEEP YOUR UPGRADES`
				else "KEEP YOUR UPGRADES",
		}).ZIndex =
			3
	end

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function PrestigePanel.render(self)
	local state = self.state
	local multiplier = state:get("PrestigeMultiplier")

	self.multiplier.before.Text = Format.multiplier(multiplier)
	self.multiplier.after.Text = Format.multiplier(multiplier * GROWTH)

	-- Everything below the multiplier goes back to where a new player starts, which
	-- is the honest way to write it: not "reset", the actual number.
	self.level.before.Text = `{LABELS.level.name} {math.max(state:get("Level"), 1)}`
	self.level.after.Text = `{LABELS.level.name} 1`

	self.coins.before.Text = Format.abbreviate(state:get("Coins"))
	self.coins.after.Text = "0"

	local progress = state:get("PrestigeProgress")
	self.bar.set(progress)
	self.barLabel.Text = `{LABELS.prestige.name} {state:get("Prestiges") + 1}`
	self.barValue.Text =
		`{Format.abbreviate(state:get("Speed"))}/{Format.abbreviate(state:get("PrestigeRequirement"))}`

	local ready = progress >= 1
	self.action.BackgroundColor3 = if ready then Theme.color.special else Theme.color.locked
	self.action.Text = if ready
		then string.upper(LABELS.prestige.verb or LABELS.prestige.name)
		else `{Format.percent(1 - progress)} TO GO`
end

function PrestigePanel.toggle(self)
	self.panel:toggle()
end

return PrestigePanel
