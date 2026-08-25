--!strict
--[[
	ShopPanel — upgrades bought with Coins.

	The displayed price is computed with the SAME domain module as the server
	(UpgradeCatalog), so the price shown and the price charged can never drift apart.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local UpgradeCatalog = require(Shared.Domain.Economy.UpgradeCatalog)
local Format = require(Shared.Domain.Support.Format)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Requirements = require(Shared.Domain.Progression.Requirements)

local LABELS = Config.Theme.labels
local REQUIREMENTS = Requirements.new()

local ROW_HEIGHT = 100
local ROW_PADDING = 16
local TEXT_LEFT = 68 -- clear of the 52px icon, with air between the two

local ShopPanel = {}
ShopPanel.__index = ShopPanel

function ShopPanel.new(parent: Instance, state, remotes)
	local panel = Panel.new(parent, { name = "Shop", title = "UPGRADES", size = UDim2.fromOffset(600, 480) })

	local self = setmetatable({
		panel = panel,
		state = state,
		remotes = remotes,
		catalog = UpgradeCatalog.new(Config.Upgrades, {
			priceGrowthPerPrestige = Config.Balance.prestige.multiplierGrowth,
		}),
		rows = {},
	}, ShopPanel)

	local list = Widgets.scroll(panel.content, { name = "Upgrades", inset = 8 })
	Widgets.list(list, { padding = 8 })

	for index, definition in Config.Upgrades do
		self.rows[definition.id] = self:_row(list, definition, index)
	end

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function ShopPanel._row(self, parent: Instance, definition, order: number)
	--[[
		A near-white card on a near-white panel, separated by its outline rather
		than by a shade. Tinting the card grey to tell it apart dims everything
		printed on it, and the icons and the price are the whole point of the row.
	]]
	local row = Widgets.card(parent, {
		name = definition.id,
		size = UDim2.new(1, -8, 0, ROW_HEIGHT),
		color = Theme.color.panel,
		radius = Theme.radius.button,
	})
	row.LayoutOrder = order
	Widgets.padding(row, ROW_PADDING)

	local icon = Widgets.icon(row, {
		image = definition.image,
		fallback = definition.icon,
		size = UDim2.fromOffset(52, 52),
		position = UDim2.fromScale(0, 0.5),
		anchorPoint = Vector2.new(0, 0.5),
	})

	local name = Widgets.label(row, {
		size = UDim2.new(0.58, -TEXT_LEFT, 0, 26),
		position = UDim2.fromOffset(TEXT_LEFT, 0),
		font = Theme.font.title,
		textSize = Theme.text.big,
		text = definition.name,
	})

	Widgets.label(row, {
		size = UDim2.new(0.58, -TEXT_LEFT, 0, 20),
		position = UDim2.fromOffset(TEXT_LEFT, 28),
		font = Theme.font.body,
		textSize = Theme.text.small,
		color = Theme.color.textMuted,
		text = definition.description or "",
	})

	local level = Widgets.label(row, {
		size = UDim2.new(0.58, -TEXT_LEFT, 0, 18),
		position = UDim2.fromOffset(TEXT_LEFT, 48),
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.accentDark,
		text = "Level 0",
	})

	local buy = Widgets.button(row, {
		text = "-",
		size = UDim2.new(0.34, 0, 0, 56),
		position = UDim2.fromScale(1, 0.5),
		anchorPoint = Vector2.new(1, 0.5),
		textSize = Theme.text.big,
		color = Theme.color.positive,
		-- Given to the button rather than added afterwards: a padding added later
		-- shrinks the grain it carries and leaves a bare margin around it.
		paddingRight = 14,
		onClick = function()
			self.remotes.events.BuyUpgrade:FireServer(definition.id)
		end,
	})

	-- The currency is shown, not spelled: an emoji would need a font the button does
	-- not have, and the pack already has the very icon the counter uses. Only the
	-- RIGHT side is padded: padding the left would push this icon along with the
	-- text, and it reads as a price tag exactly where it was put.
	local price = Widgets.icon(buy, {
		name = "Currency",
		image = LABELS.coins.image,
		fallback = LABELS.coins.icon,
		size = UDim2.fromOffset(26, 26),
		position = UDim2.fromOffset(12, 28),
		anchorPoint = Vector2.new(0, 0.5),
	});
	(price :: any).Active = false

	return { row = row, name = name, icon = icon, level = level, buy = buy, price = price }
end

--[[
	Turns an unmet condition into something a player can act on.

	"Locked" is a dead end; "Needs Dash" is a next step. The catalogue is consulted
	for names so a renamed upgrade renames itself here too.
]]
function ShopPanel._explain(self, condition): string
	if condition.kind == "upgrade" then
		local needed = self.catalog:get(condition.id)
		local name = (needed and needed.name) or condition.id
		return if (condition.level or 1) > 1 then `Needs {name} {condition.level}` else `Needs {name}`
	elseif condition.kind == "level" then
		return `Needs {LABELS.level.name} {condition.value}`
	elseif condition.kind == "prestiges" then
		return `Needs {condition.value} {LABELS.prestige.name}`
	elseif condition.kind == "stage" then
		return `Needs {LABELS.stage.name} {condition.value}`
	elseif condition.kind == "pass" then
		return `Needs the {condition.id} pass`
	end
	return "Locked"
end

--[[
	The same requirement rule the server enforces, run locally to draw the row.

	The profile is rebuilt from the replicated state rather than sent whole: the
	client never sees the save, and the three fields a condition can ask about are
	already on screen.
]]
function ShopPanel._gateFor(self, definition)
	return REQUIREMENTS:evaluate(definition.requires, {
		profile = {
			upgrades = self.state.upgrades,
			prestiges = self.state:get("Prestiges"),
			highestStage = self.state:get("HighestStage"),
		},
		level = self.state:get("Level"),
		passes = self.state.passes,
	})
end

function ShopPanel.render(self)
	local coins = self.state:get("Coins")

	for _, definition in Config.Upgrades do
		local row = self.rows[definition.id]
		local currentLevel = self.state:levelOf(definition.id)
		local gate = self:_gateFor(definition)

		row.level.Text = if definition.maxLevel > 0
			then `Level {currentLevel} / {definition.maxLevel}`
			else `Level {currentLevel}`
		row.level.TextColor3 = Theme.color.accentDark

		-- A locked row dims its CONTENT, never its card. Repainting the card was
		-- the wrong lever and it came out backwards: locked rows read brighter than
		-- the ones you could actually buy.
		local dimmed = if gate.met then 0 else 0.55
		if row.icon:IsA("ImageLabel") then
			row.icon.ImageTransparency = dimmed
		end
		row.name.TextTransparency = dimmed

		if not gate.met then
			row.level.Text = self:_explain(gate.unmet[1])
			row.level.TextColor3 = Theme.color.negative
			row.buy.Text = "LOCKED"
			row.buy.BackgroundColor3 = Theme.color.locked
			row.buy.TextXAlignment = Enum.TextXAlignment.Center
			row.price.Visible = false
			continue
		end

		if self.catalog:isMaxed(definition.id, currentLevel) then
			row.buy.Text = "MAX"
			row.buy.BackgroundColor3 = Theme.color.locked
			row.buy.TextXAlignment = Enum.TextXAlignment.Center
			row.price.Visible = false
		else
			local cost = self.catalog:costFor(definition.id, currentLevel, self.state:get("Prestiges"))
			row.buy.Text = Format.abbreviate(cost)
			row.buy.BackgroundColor3 = if coins >= cost then Theme.color.positive else Theme.color.locked
			row.buy.TextXAlignment = Enum.TextXAlignment.Right
			row.price.Visible = true
		end
	end
end

function ShopPanel.toggle(self)
	self.panel:toggle()
end

return ShopPanel
