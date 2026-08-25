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

function StorePanel.new(parent: Instance, state, remotes)
	local panel = Panel.new(parent, { name = "Store", title = "STORE", size = UDim2.fromOffset(620, 500) })
	local self = setmetatable({ panel = panel, state = state, remotes = remotes, passRows = {} }, StorePanel)

	local list = Widgets.scroll(panel.content, { name = "Items", inset = 8 })
	Widgets.list(list, { padding = 8 })

	local order = 0

	for _, pass in Config.Passes do
		if pass.assetId ~= 0 then
			order += 1
			self.passRows[pass.id] = self:_row(list, {
				icon = pass.icon,
				image = pass.image,
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
				image = product.image,
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
			textSize = Theme.text.body,
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
		size = UDim2.new(1, -8, 0, 100),
		-- Near-white on near-white, separated by the outline: a grey card dims
		-- everything printed on it, and the icon and the price are the row.
		color = Theme.color.panel,
		radius = Theme.radius.button,
	})
	row.LayoutOrder = options.order
	Widgets.padding(row, 16)

	Widgets.icon(row, {
		image = options.image,
		fallback = options.icon or "💠",
		size = UDim2.fromOffset(52, 52),
		position = UDim2.fromScale(0, 0),
	})

	Widgets.label(row, {
		size = UDim2.new(0.62, -68, 0, 26),
		position = UDim2.fromOffset(68, 0),
		font = Theme.font.number,
		textSize = Theme.text.big,
		text = options.name,
	})

	Widgets.label(row, {
		size = UDim2.new(0.62, -68, 0, 40),
		position = UDim2.fromOffset(68, 28),
		font = Theme.font.body,
		textSize = Theme.text.small,
		color = Theme.color.textMuted,
		wrapped = true,
		verticalAlign = Enum.TextYAlignment.Top,
		text = options.description or "",
	})

	if options.badge then
		Widgets.label(row, {
			size = UDim2.new(0.34, 0, 0, 18),
			position = UDim2.fromScale(1, 0),
			anchorPoint = Vector2.new(1, 0),
			font = Theme.font.number,
			textSize = Theme.text.small,
			color = Theme.color.accentDark,
			align = Enum.TextXAlignment.Right,
			text = string.upper(options.badge),
		})
	end

	local button = Widgets.button(row, {
		text = options.action,
		size = UDim2.new(0.32, 0, 0, 50),
		position = UDim2.fromScale(1, 1),
		anchorPoint = Vector2.new(1, 1),
		textSize = Theme.text.big,
		color = Theme.color.positive,
		onClick = options.onClick,
	})

	return { row = row, button = button }
end

function StorePanel.render(self)
	for passId, row in self.passRows do
		if self.state:owns(passId) then
			row.button.Text = "OWNED"
			row.button.BackgroundColor3 = Theme.color.locked
			row.button.Active = false
		end
	end
end

function StorePanel.toggle(self)
	self.panel:toggle()
end

return StorePanel
