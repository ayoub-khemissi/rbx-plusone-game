--!strict
--[[ ZonesPanel — carte des zones : ce qui est ouvert, ce qui reste a meriter. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local ZonesPanel = {}
ZonesPanel.__index = ZonesPanel

function ZonesPanel.new(parent: ScreenGui, state, remotes)
	local panel = Panel.new(parent, { name = "Zones", title = "🗺️ Zones" })

	local self = setmetatable({ panel = panel, state = state, remotes = remotes, rows = {} }, ZonesPanel)

	local list = Widgets.scroll(panel.content, { name = "ListeZones" })
	Widgets.list(list, { padding = 6 })

	for _, zone in Config.Zones do
		self.rows[zone.id] = self:_row(list, zone)
	end

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function ZonesPanel._row(self, parent: Instance, zone)
	local row = Widgets.card(parent, {
		name = `Zone{zone.id}`,
		size = UDim2.new(1, -8, 0, 62),
		color = Theme.color.panelLight,
		transparency = 0.15,
	})
	row.LayoutOrder = zone.id
	Widgets.padding(row, 10)

	Widgets.label(row, {
		size = UDim2.new(0.62, 0, 0, 22),
		font = Theme.font.title,
		text = `{zone.id}. {zone.name}`,
	})

	local detail = Widgets.label(row, {
		size = UDim2.new(0.62, 0, 0, 18),
		position = UDim2.fromOffset(0, 26),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		text = `⚡ {Format.abbreviate(zone.requiredSpeed)} — gains {Format.multiplier(zone.stepMultiplier)}`,
		textScaled = false,
	})
	detail.TextSize = 14

	local travel = Widgets.button(row, {
		text = "ALLER",
		size = UDim2.new(0.32, 0, 0, 40),
		position = UDim2.fromScale(1, 0.5),
		anchorPoint = Vector2.new(1, 0.5),
		onClick = function()
			self.remotes.events.TravelZone:FireServer(zone.id)
		end,
	})

	return { row = row, travel = travel }
end

function ZonesPanel.render(self)
	local unlocked = self.state:get("HighestUnlockedZone")

	for _, zone in Config.Zones do
		local row = self.rows[zone.id]
		local isOpen = zone.id <= unlocked
		row.travel.BackgroundColor3 = if isOpen then Theme.color.accent else Theme.color.locked
		row.travel.Text = if isOpen then "ALLER" else "🔒"
	end
end

function ZonesPanel.toggle(self)
	self.panel:toggle()
end

return ZonesPanel
