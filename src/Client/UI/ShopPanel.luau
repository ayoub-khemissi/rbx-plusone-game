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

local ShopPanel = {}
ShopPanel.__index = ShopPanel

function ShopPanel.new(parent: ScreenGui, state, remotes)
	local panel = Panel.new(parent, { name = "Shop", title = "🪙 Upgrades" })

	local self = setmetatable({
		panel = panel,
		state = state,
		remotes = remotes,
		catalog = UpgradeCatalog.new(Config.Upgrades),
		rows = {},
	}, ShopPanel)

	local list = Widgets.scroll(panel.content, { name = "Upgrades" })
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
		size = UDim2.new(1, -8, 0, 78),
		color = Theme.color.panelLight,
		transparency = 0.15,
	})
	row.LayoutOrder = order
	Widgets.padding(row, 10)

	Widgets.icon(row, {
		image = definition.image,
		fallback = definition.icon,
		size = UDim2.fromOffset(30, 30),
		position = UDim2.fromScale(0, 0),
	})

	Widgets.label(row, {
		size = UDim2.new(0.6, -38, 0, 26),
		position = UDim2.fromOffset(38, 0),
		font = Theme.font.title,
		text = definition.name,
	})

	local description = Widgets.label(row, {
		size = UDim2.new(0.6, 0, 0, 20),
		position = UDim2.fromOffset(0, 28),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		text = definition.description or "",
		textScaled = false,
	})
	description.TextSize = 14

	local level = Widgets.label(row, {
		size = UDim2.new(0.6, 0, 0, 18),
		position = UDim2.fromOffset(0, 48),
		font = Theme.font.number,
		color = Theme.color.accent,
		text = "Level 0",
	})

	local buy = Widgets.button(row, {
		text = "🪙 —",
		size = UDim2.new(0.36, 0, 0, 48),
		position = UDim2.fromScale(1, 0.5),
		anchorPoint = Vector2.new(1, 0.5),
		onClick = function()
			self.remotes.events.BuyUpgrade:FireServer(definition.id)
		end,
	})

	return { row = row, level = level, buy = buy }
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
		else
			local cost = self.catalog:costFor(definition.id, currentLevel)
			row.buy.Text = `🪙 {Format.abbreviate(cost)}`
			row.buy.BackgroundColor3 = if coins >= cost then Theme.color.accent else Theme.color.locked
		end
	end
end

function ShopPanel.toggle(self)
	self.panel:toggle()
end

return ShopPanel
