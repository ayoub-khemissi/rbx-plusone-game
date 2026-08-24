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

local LABELS = Config.Theme.labels

local ShopPanel = {}
ShopPanel.__index = ShopPanel

function ShopPanel.new(parent: Instance, state, remotes)
	local panel = Panel.new(parent, { name = "Shop", title = "UPGRADES", size = UDim2.fromOffset(600, 480) })

	local self = setmetatable({
		panel = panel,
		state = state,
		remotes = remotes,
		catalog = UpgradeCatalog.new(Config.Upgrades),
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
	local row = Widgets.card(parent, {
		name = definition.id,
		size = UDim2.new(1, -8, 0, 88),
		color = Theme.color.panelSoft,
		radius = Theme.radius.button,
	})
	row.LayoutOrder = order
	Widgets.padding(row, 12)

	Widgets.icon(row, {
		image = definition.image,
		fallback = definition.icon,
		size = UDim2.fromOffset(52, 52),
		position = UDim2.fromScale(0, 0.5),
		anchorPoint = Vector2.new(0, 0.5),
	})

	Widgets.label(row, {
		size = UDim2.new(0.58, -64, 0, 26),
		position = UDim2.fromOffset(64, 0),
		font = Theme.font.title,
		textSize = Theme.text.big,
		text = definition.name,
	})

	Widgets.label(row, {
		size = UDim2.new(0.58, -64, 0, 20),
		position = UDim2.fromOffset(64, 26),
		font = Theme.font.body,
		textSize = Theme.text.small,
		color = Theme.color.textMuted,
		text = definition.description or "",
	})

	local level = Widgets.label(row, {
		size = UDim2.new(0.58, -64, 0, 20),
		position = UDim2.fromOffset(64, 46),
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
		textColor = Theme.color.background,
		onClick = function()
			self.remotes.events.BuyUpgrade:FireServer(definition.id)
		end,
	})

	-- The currency is shown, not spelled: an emoji would need a font the button does
	-- not have, and the pack already has the very icon the counter uses.
	local price = Widgets.icon(buy, {
		name = "Currency",
		image = LABELS.coins.image,
		fallback = LABELS.coins.icon,
		size = UDim2.fromOffset(26, 26),
		position = UDim2.fromOffset(12, 28),
		anchorPoint = Vector2.new(0, 0.5),
	});
	(price :: any).Active = false

	-- Padding on the LEFT would push the icon along with the text, since it insets
	-- every child. The price is pushed to the right edge instead, which leaves the
	-- icon where it was put and reads as a price tag.
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = buy

	return { row = row, level = level, buy = buy, price = price }
end

function ShopPanel.render(self)
	local coins = self.state:get("Coins")

	for _, definition in Config.Upgrades do
		local row = self.rows[definition.id]
		local currentLevel = self.state:levelOf(definition.id)

		row.level.Text = if definition.maxLevel > 0
			then `Level {currentLevel} / {definition.maxLevel}`
			else `Level {currentLevel}`

		if self.catalog:isMaxed(definition.id, currentLevel) then
			row.buy.Text = "MAX"
			row.buy.BackgroundColor3 = Theme.color.locked
			row.buy.TextXAlignment = Enum.TextXAlignment.Center
			row.price.Visible = false
		else
			local cost = self.catalog:costFor(definition.id, currentLevel)
			row.buy.Text = Format.abbreviate(cost)
			row.buy.BackgroundColor3 = if coins >= cost then Theme.color.accent else Theme.color.locked
			row.buy.TextXAlignment = Enum.TextXAlignment.Right
			row.price.Visible = true
		end
	end
end

function ShopPanel.toggle(self)
	self.panel:toggle()
end

return ShopPanel
