--!strict
--[[
	NestPanel — the hatchery and the collection.

	This is the screen players come back for. It shows what is warming up, what is
	ready, what is waiting in stock, and how far the dragon book is from complete.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local NestPanel = {}
NestPanel.__index = NestPanel

local REFRESH_INTERVAL = 1

function NestPanel.new(parent: ScreenGui, state, remotes)
	local panel = Panel.new(parent, { name = "Nest", title = "🪺 Nest", size = UDim2.fromOffset(560, 460) })
	local self =
		setmetatable({ panel = panel, state = state, remotes = remotes, slots = {}, stock = {} }, NestPanel)

	Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 22),
		font = Theme.font.title,
		text = "Hatching",
	})

	self.slotList = Instance.new("Frame")
	self.slotList.Name = "Slots"
	self.slotList.Size = UDim2.new(1, 0, 0, 130)
	self.slotList.Position = UDim2.fromOffset(0, 26)
	self.slotList.BackgroundTransparency = 1
	self.slotList.Parent = panel.content
	Widgets.list(self.slotList, { padding = 6 })

	Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 164),
		font = Theme.font.title,
		text = "Eggs in stock",
	})

	self.stockList = Instance.new("Frame")
	self.stockList.Name = "Stock"
	self.stockList.Size = UDim2.new(1, 0, 0, 56)
	self.stockList.Position = UDim2.fromOffset(0, 190)
	self.stockList.BackgroundTransparency = 1
	self.stockList.Parent = panel.content
	Widgets.list(self.stockList, { padding = 6, direction = Enum.FillDirection.Horizontal })

	self.collectionLabel = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 24),
		position = UDim2.fromOffset(0, 254),
		font = Theme.font.title,
		text = "Collection",
	})

	self.collectionList = Widgets.scroll(panel.content, {
		name = "Dragons",
		size = UDim2.new(1, 0, 1, -284),
		position = UDim2.fromOffset(0, 282),
	})
	Widgets.list(self.collectionList, { padding = 6, direction = Enum.FillDirection.Horizontal })
	self:_buildCollection()

	state.changed:connect(function()
		self:render()
	end)

	-- The countdown has to tick even when nothing else changes.
	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			if panel.isOpen then
				self:render()
			end
		end
	end)

	self:render()
	return self
end

function NestPanel._buildCollection(self)
	self.dragonCards = {}

	for index, species in Config.Dragons do
		local card = Widgets.card(self.collectionList, {
			name = species.id,
			size = UDim2.fromOffset(96, 96),
			color = Theme.color.panelLight,
			transparency = 0.2,
		})
		card.LayoutOrder = index
		Widgets.padding(card, 6)

		local name = Widgets.label(card, {
			size = UDim2.new(1, 0, 0, 30),
			font = Theme.font.number,
			align = Enum.TextXAlignment.Center,
			wrapped = true,
			text = species.name,
			textScaled = false,
		})
		name.TextSize = 13

		local count = Widgets.label(card, {
			size = UDim2.new(1, 0, 0, 26),
			position = UDim2.new(0, 0, 1, -26),
			font = Theme.font.title,
			align = Enum.TextXAlignment.Center,
			color = Theme.rarity[species.rarity] or Theme.color.text,
			text = "—",
		})

		self.dragonCards[species.id] = { card = card, count = count, name = name }
	end
end

function NestPanel._slotRow(self, index: number, status)
	local row = Widgets.card(self.slotList, {
		name = `Slot{index}`,
		size = UDim2.new(1, -8, 0, 38),
		color = Theme.color.panelLight,
		transparency = 0.2,
	})
	row.LayoutOrder = index
	Widgets.padding(row, 8)

	Widgets.label(row, {
		size = UDim2.fromScale(0.55, 1),
		font = Theme.font.number,
		color = Theme.rarity[status.rarity] or Theme.color.text,
		text = `🥚 {status.rarity}`,
	})

	Widgets.button(row, {
		text = if status.ready then "COLLECT" else Format.duration(status.remaining),
		size = UDim2.new(0.4, 0, 0, 28),
		position = UDim2.fromScale(1, 0.5),
		anchorPoint = Vector2.new(1, 0.5),
		color = if status.ready then Theme.color.positive else Theme.color.locked,
		onClick = function()
			if status.ready then
				self.remotes.events.CollectHatchling:FireServer(index)
			end
		end,
	})
end

function NestPanel.render(self)
	for _, child in self.slotList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, child in self.stockList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local hatchery = self.state:list("Hatchery")
	if #hatchery == 0 then
		Widgets.label(self.slotList, {
			size = UDim2.new(1, -8, 0, 34),
			font = Theme.font.body,
			color = Theme.color.textMuted,
			text = "No egg warming up. Bank a flight to bring some home.",
		})
	else
		for index, status in hatchery do
			self:_slotRow(index, status)
		end
	end

	local order = 0
	for rarity, count in self.state:list("Eggs") do
		if count > 0 then
			order += 1
			local card = Widgets.card(self.stockList, {
				name = rarity,
				size = UDim2.fromOffset(110, 48),
				color = Theme.color.panelLight,
				transparency = 0.2,
			})
			card.LayoutOrder = order
			Widgets.padding(card, 6)

			Widgets.label(card, {
				size = UDim2.new(1, 0, 0, 16),
				font = Theme.font.number,
				color = Theme.rarity[rarity] or Theme.color.text,
				text = `{rarity} x{count}`,
				textScaled = false,
			}).TextSize =
				13

			Widgets.button(card, {
				text = "PUT IN NEST",
				size = UDim2.new(1, 0, 0, 20),
				position = UDim2.fromScale(0, 1),
				anchorPoint = Vector2.new(0, 1),
				onClick = function()
					self.remotes.events.PlaceEgg:FireServer(rarity)
				end,
			})
		end
	end

	local dragons = self.state:list("Dragons")
	local collection = self.state:list("Collection")
	self.collectionLabel.Text =
		`Collection — {collection.owned or 0} / {collection.total or #Config.Dragons}`

	for id, entry in self.dragonCards do
		local count = dragons[id] or 0
		entry.count.Text = if count > 0 then `x{count}` else "—"
		entry.card.BackgroundTransparency = if count > 0 then 0.2 else 0.6
		entry.name.TextColor3 = if count > 0 then Theme.color.text else Theme.color.locked
	end
end

function NestPanel.toggle(self)
	self.panel:toggle()
end

return NestPanel
