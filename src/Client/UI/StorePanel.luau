--!strict
--[[
	StorePanel — the Robux store: gamepasses and consumable products.

	Items that are not configured (id left at 0) are never listed, so the store stays
	clean until the products exist on the Roblox site.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local StorePanel = {}
StorePanel.__index = StorePanel

function StorePanel.new(parent: ScreenGui, state, remotes)
	local panel =
		Panel.new(parent, { name = "Store", title = "💎 Store", size = UDim2.fromOffset(580, 470) })
	local self = setmetatable({ panel = panel, state = state, remotes = remotes, passRows = {} }, StorePanel)

	local list = Widgets.scroll(panel.content, { name = "Items" })
	Widgets.list(list, { padding = 8 })

	local order = 0

	for _, pass in Config.Passes do
		if pass.assetId ~= 0 then
			order += 1
			self.passRows[pass.id] = self:_row(list, {
				icon = pass.icon,
				name = pass.name,
				description = pass.description,
				action = "BUY",
				order = order,
				onClick = function()
					self.remotes.events.PromptPurchase:FireServer("pass", pass.id)
				end,
			})
		end
	end

	for _, product in Config.Products do
		if product.productId ~= 0 then
			order += 1
			self:_row(list, {
				icon = product.icon,
				name = product.name,
				description = product.description,
				badge = product.badge,
				action = if product.robux then `R$ {product.robux}` else "BUY",
				order = order,
				onClick = function()
					self.remotes.events.PromptPurchase:FireServer("product", product.id)
				end,
			})
		end
	end

	if order == 0 then
		Widgets.label(list, {
			size = UDim2.new(1, 0, 0, 60),
			font = Theme.font.body,
			color = Theme.color.textMuted,
			wrapped = true,
			text = "Store opening soon: items appear here as soon as they are created on Roblox.",
		})
	end

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function StorePanel._row(_self, parent: Instance, options)
	local row = Widgets.card(parent, {
		name = options.name,
		size = UDim2.new(1, -8, 0, 78),
		color = Theme.color.panelLight,
		transparency = 0.15,
	})
	row.LayoutOrder = options.order
	Widgets.padding(row, 10)

	Widgets.label(row, {
		size = UDim2.new(0.62, 0, 0, 24),
		font = Theme.font.title,
		text = `{options.icon or "💠"} {options.name}`,
	})

	local description = Widgets.label(row, {
		size = UDim2.new(0.62, 0, 0, 36),
		position = UDim2.fromOffset(0, 28),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		wrapped = true,
		text = options.description or "",
		textScaled = false,
	})
	description.TextSize = 14

	if options.badge then
		local badge = Widgets.label(row, {
			size = UDim2.new(0.34, 0, 0, 16),
			position = UDim2.fromScale(1, 0),
			anchorPoint = Vector2.new(1, 0),
			font = Theme.font.number,
			color = Theme.color.accent,
			align = Enum.TextXAlignment.Right,
			text = string.upper(options.badge),
			textScaled = false,
		})
		badge.TextSize = 13
	end

	local button = Widgets.button(row, {
		text = options.action,
		size = UDim2.new(0.32, 0, 0, 44),
		position = UDim2.fromScale(1, 1),
		anchorPoint = Vector2.new(1, 1),
		color = Theme.color.positive,
		onClick = options.onClick,
	})

	return { row = row, button = button }
end

function StorePanel.render(self)
	for passId, row in self.passRows do
		if self.state:owns(passId) then
			row.button.Text = "✔ OWNED"
			row.button.BackgroundColor3 = Theme.color.locked
			row.button.Active = false
		end
	end
end

function StorePanel.toggle(self)
	self.panel:toggle()
end

return StorePanel
