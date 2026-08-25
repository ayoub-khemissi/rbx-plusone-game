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

	EVERY MEASUREMENT IS ABSOLUTE, top to bottom, and the window is sized from the
	same numbers. Anchoring the buttons to the bottom of the window instead is how
	they came to sit on top of the progress bar: two things measured from opposite
	ends of a box meet in the middle the moment the box changes.

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

local WIDTH = 700
local COLUMN_GAP = 56 -- room for the arrow between the two columns
local ROW_HEIGHT = 62
local ROW_GAP = 12
local ROWS = 3

-- The layout, measured once from the top. Every band knows where it starts and how
-- tall it is, and the window is exactly as tall as the last one ends.
local HEADERS_Y = 0
local HEADERS_H = 26
local ROWS_Y = HEADERS_Y + HEADERS_H + 10
local ROWS_H = ROWS * ROW_HEIGHT + (ROWS - 1) * ROW_GAP
local WARNING_Y = ROWS_Y + ROWS_H + 16
local WARNING_H = 26
local BAR_Y = WARNING_Y + WARNING_H + 14
local BAR_H = 48
local BUTTONS_Y = BAR_Y + BAR_H + 20
local BUTTONS_H = 74
local CONTENT_H = BUTTONS_Y + BUTTONS_H

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
	which column it sits in, so the eye finds the cost without reading a word. The
	icon is nearly as tall as the pill and the value wears a heavy stroke, because
	this is the part of the window a player is meant to read from across the room.
]]
local function pill(parent: Instance, options)
	local frame = Widgets.card(parent, {
		name = options.name,
		size = UDim2.new(0.5, -COLUMN_GAP / 2, 0, ROW_HEIGHT),
		position = options.position,
		anchorPoint = options.anchorPoint,
		color = options.color,
		radius = Theme.radius.button,
		edgeThickness = Theme.stroke.panel,
	})
	frame.ZIndex = 7
	Widgets.gradient(frame, 0.34)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = frame

	Widgets.list(frame, {
		direction = Enum.FillDirection.Horizontal,
		padding = 12,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	local icon = Widgets.icon(frame, {
		image = options.image,
		fallback = options.fallback,
		size = UDim2.fromOffset(ROW_HEIGHT - 12, ROW_HEIGHT - 12),
		layoutOrder = 1,
	})
	icon.ZIndex = 8

	local value = Widgets.label(frame, {
		name = "Value",
		size = UDim2.new(1, -(ROW_HEIGHT + 14), 1, 0),
		font = Theme.font.title,
		textSize = Theme.text.big,
		align = Enum.TextXAlignment.Left,
		color = Theme.color.textOnColor,
		outline = Theme.stroke.textHeavy,
		layoutOrder = 2,
	})
	value.ZIndex = 8

	return value
end

--[[
	The arrow between the two columns: this becomes that.

	GothamBold rather than the title face, which carries no arrow glyph and would
	draw nothing at all — the same trap that once left the close button an empty red
	circle.
]]
local function arrow(parent: Instance, y: number)
	local mark = Widgets.label(parent, {
		name = "Arrow",
		size = UDim2.fromOffset(COLUMN_GAP, ROW_HEIGHT),
		position = UDim2.new(0.5, 0, 0, y),
		anchorPoint = Vector2.new(0.5, 0),
		font = Theme.font.number,
		textSize = Theme.text.title,
		color = Theme.color.panelSoft,
		outline = Theme.stroke.text,
		text = "▶",
	})
	mark.ZIndex = 7
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
		anchorPoint = Vector2.new(1, 0),
		color = options.after or options.color,
		image = options.image,
		fallback = options.fallback,
	})

	return { before = before, after = after }
end

function PrestigePanel.new(parent: Instance, state, remotes)
	local panel = Panel.new(parent, {
		name = "Prestige",
		title = string.upper(LABELS.prestige.name),
		titleSize = Theme.text.hero,
		size = UDim2.fromOffset(WIDTH, CONTENT_H + 82),
	})
	local self = setmetatable({ panel = panel, state = state, remotes = remotes }, PrestigePanel)

	local function header(text: string, position: UDim2, anchor: Vector2)
		local label = Widgets.label(panel.content, {
			size = UDim2.new(0.5, -COLUMN_GAP / 2, 0, HEADERS_H),
			position = position,
			anchorPoint = anchor,
			font = Theme.font.title,
			textSize = Theme.text.body,
			color = Theme.color.textMuted,
			text = text,
		})
		label.ZIndex = 7
		return label
	end

	header("BEFORE", UDim2.fromOffset(0, HEADERS_Y), Vector2.zero)
	header("AFTER", UDim2.new(1, 0, 0, HEADERS_Y), Vector2.new(1, 0))

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
		size = UDim2.new(1, 0, 0, WARNING_H),
		position = UDim2.fromOffset(0, WARNING_Y),
		font = Theme.font.title,
		textSize = Theme.text.body,
		color = Theme.color.negative,
		outline = Theme.stroke.text,
		text = `A {LABELS.prestige.name} clears your {LABELS.speed.name}, your {LABELS.coins.plural} and your upgrades.`,
	})
	self.warning.ZIndex = 7

	-- The same bar the HUD wears, so the number a player is chasing looks the same
	-- wherever they read it.
	self.bar = Widgets.bar(panel.content, {
		size = UDim2.new(1, 0, 0, BAR_H),
		position = UDim2.fromOffset(0, BAR_Y),
		color = Theme.color.positive,
		sheen = true,
	})
	self.bar.instance.ZIndex = 7

	local function barText(name: string, position: UDim2, anchor: Vector2, align: Enum.TextXAlignment)
		local label = Widgets.label(self.bar.instance, {
			name = name,
			size = UDim2.new(0.5, -20, 1, 0),
			position = position,
			anchorPoint = anchor,
			font = Theme.font.number,
			textSize = Theme.text.big,
			align = align,
			color = Theme.color.textOnColor,
			outline = Theme.stroke.textHeavy,
		})
		label.ZIndex = 9
		return label
	end

	self.barLabel = barText("Level", UDim2.fromOffset(18, 0), Vector2.zero, Enum.TextXAlignment.Left)
	self.barValue = barText("Value", UDim2.new(1, -18, 0, 0), Vector2.new(1, 0), Enum.TextXAlignment.Right)

	local product = instantProduct()
	local width = if product then UDim2.new(0.5, -8, 0, BUTTONS_H) else UDim2.new(1, 0, 0, BUTTONS_H)

	self.action = Widgets.button(panel.content, {
		text = string.upper(LABELS.prestige.verb or LABELS.prestige.name),
		size = width,
		position = UDim2.fromOffset(0, BUTTONS_Y),
		color = Theme.color.special,
		textSize = Theme.text.big,
		onClick = function()
			self.remotes.events.Prestige:FireServer()
		end,
	})
	self.action.ZIndex = 7

	--[[
		The paid way out, when the place has published the product. It skips the
		cost rather than the wait: the upgrades survive, which is the whole of what
		is being sold — see docs/MONETISATION.md.
	]]
	if product then
		self.skip = Widgets.button(panel.content, {
			name = "Skip",
			text = string.upper(product.name),
			size = UDim2.new(0.5, -8, 0, BUTTONS_H),
			position = UDim2.new(1, 0, 0, BUTTONS_Y),
			anchorPoint = Vector2.new(1, 0),
			color = Theme.color.accentDark,
			textSize = Theme.text.body,
			padding = 12,
			onClick = function()
				self.remotes.events.PromptPurchase:FireServer("product", product.id)
			end,
		})
		self.skip.ZIndex = 7
		-- The name sits high so the price line underneath has room of its own.
		self.skip.TextYAlignment = Enum.TextYAlignment.Top

		local note = Widgets.label(self.skip, {
			name = "Note",
			size = UDim2.new(1, -16, 0, 20),
			position = UDim2.new(0.5, 0, 1, -10),
			anchorPoint = Vector2.new(0.5, 1),
			font = Theme.font.number,
			textSize = Theme.text.small,
			color = Theme.color.textOnColor,
			outline = Theme.stroke.text,
			text = if product.robux
				then `R$ {product.robux} — KEEP YOUR UPGRADES`
				else "KEEP YOUR UPGRADES",
		})
		note.ZIndex = 8
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

	--[[
		Off until it is earned, and off properly: a grey button that still grows
		under the pointer and still fires is worse than no state at all. The share
		done replaces the verb, so it still answers "how close am I" — it simply
		cannot be pressed to find out.
	]]
	local ready = progress >= 1
	Widgets.setEnabled(self.action, ready)
	self.action.Text = if ready
		then string.upper(LABELS.prestige.verb or LABELS.prestige.name)
		else Format.percent(progress)
end

function PrestigePanel.toggle(self)
	self.panel:toggle()
end

return PrestigePanel
