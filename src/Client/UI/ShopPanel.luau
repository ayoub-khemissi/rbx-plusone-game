--!strict
--[[
	ShopPanel — ameliorations achetables en bananes.

	Le cout affiche est calcule avec le MEME module de domaine que le serveur
	(UpgradeCatalog) : aucun risque d'ecart entre le prix montre et le prix debite.
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

local ROW_HEIGHT = 76

function ShopPanel.new(parent: ScreenGui, state, remotes)
	local panel = Panel.new(parent, { name = "Boutique", title = "🛒 Ameliorations" })

	local self = setmetatable({
		panel = panel,
		state = state,
		remotes = remotes,
		catalog = UpgradeCatalog.new(Config.Upgrades),
		rows = {},
	}, ShopPanel)

	local list = Widgets.scroll(panel.content, { name = "Ameliorations" })
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
		size = UDim2.new(1, -8, 0, ROW_HEIGHT),
		color = Theme.color.panelLight,
		transparency = 0.15,
	})
	row.LayoutOrder = order
	Widgets.padding(row, 10)

	local title = Widgets.label(row, {
		size = UDim2.new(0.6, 0, 0, 24),
		font = Theme.font.title,
		text = `{definition.icon} {definition.name}`,
	})

	local description = Widgets.label(row, {
		size = UDim2.new(0.6, 0, 0, 20),
		position = UDim2.fromOffset(0, 26),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		text = definition.description or "",
		textScaled = false,
	})
	description.TextSize = 14

	local level = Widgets.label(row, {
		size = UDim2.new(0.6, 0, 0, 18),
		position = UDim2.fromOffset(0, 46),
		font = Theme.font.number,
		color = Theme.color.accent,
		text = "Niveau 0",
	})

	local buy = Widgets.button(row, {
		text = "🍌 —",
		size = UDim2.new(0.36, 0, 0, 48),
		position = UDim2.fromScale(1, 0.5),
		anchorPoint = Vector2.new(1, 0.5),
		onClick = function()
			self.remotes.events.BuyUpgrade:FireServer(definition.id)
		end,
	})

	return { row = row, title = title, level = level, buy = buy }
end

function ShopPanel.render(self)
	local bananas = self.state:get("Bananas")

	for _, definition in Config.Upgrades do
		local row = self.rows[definition.id]
		local currentLevel = self.state:levelOf(definition.id)

		row.level.Text = if definition.maxLevel > 0
			then `Niveau {currentLevel} / {definition.maxLevel}`
			else `Niveau {currentLevel}`

		if self.catalog:isMaxed(definition.id, currentLevel) then
			row.buy.Text = "MAX"
			row.buy.BackgroundColor3 = Theme.color.locked
		else
			local cost = self.catalog:costFor(definition.id, currentLevel)
			row.buy.Text = `🍌 {Format.abbreviate(cost)}`
			row.buy.BackgroundColor3 = if bananas >= cost then Theme.color.accent else Theme.color.locked
		end
	end
end

function ShopPanel.toggle(self)
	self.panel:toggle()
end

return ShopPanel
