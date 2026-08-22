--!strict
--[[
	Hud — affichage permanent : vitesse, bananes, renaissances, zone et boosts.

	Trois informations doivent etre lisibles en une seconde de course : ce que je
	gagne (vitesse), ce que je peux depenser (bananes), et ce qui me separe de la
	prochaine zone.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Hud = {}
Hud.__index = Hud

local function zoneName(zoneId: number): string
	local zone = Config.Zones[zoneId]
	return if zone then zone.name else "Jungle"
end

function Hud.new(parent: ScreenGui, state)
	local self = setmetatable({ state = state }, Hud)

	local card = Widgets.card(parent, {
		name = "Statistiques",
		size = UDim2.fromOffset(260, 148),
		position = UDim2.fromOffset(14, 14),
	})
	Widgets.padding(card, 12)

	self.speedLabel = Widgets.label(card, {
		name = "Vitesse",
		size = UDim2.new(1, 0, 0, 44),
		font = Theme.font.title,
		color = Theme.color.accent,
		text = "⚡ 0",
	})

	self.bananaLabel = Widgets.label(card, {
		name = "Bananes",
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 48),
		font = Theme.font.number,
		text = "🍌 0",
	})

	self.rebirthLabel = Widgets.label(card, {
		name = "Renaissances",
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 76),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		text = "🔥 0 — gains x1",
	})

	self.zoneLabel = Widgets.label(card, {
		name = "Zone",
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 100),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		text = zoneName(1),
	})

	self.zoneBar = Widgets.bar(card, {
		name = "ProgressionZone",
		size = UDim2.new(1, 0, 0, 10),
		position = UDim2.fromOffset(0, 124),
	})

	-- Bandeau des boosts actifs, en haut a droite.
	self.boostBar = Widgets.card(parent, {
		name = "Boosts",
		size = UDim2.fromOffset(210, 34),
		position = UDim2.new(1, -14, 0, 14),
		anchorPoint = Vector2.new(1, 0),
		visible = false,
	})
	Widgets.padding(self.boostBar, 8)
	self.boostLabel = Widgets.label(self.boostBar, {
		name = "BoostActifs",
		font = Theme.font.number,
		color = Theme.color.positive,
		align = Enum.TextXAlignment.Center,
	})

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function Hud.render(self)
	local state = self.state

	self.speedLabel.Text = `⚡ {Format.abbreviate(state:get("Speed"))}`
	self.bananaLabel.Text = `🍌 {Format.abbreviate(state:get("Bananas"))}`
	self.rebirthLabel.Text =
		`🔥 {state:get("Rebirths")} — gains {Format.multiplier(state:get("SpeedMultiplier"))}`

	local zoneId = math.max(state:get("ZoneId"), 1)
	local nextZone = Config.Zones[zoneId + 1]
	self.zoneLabel.Text = if nextZone
		then `{zoneName(zoneId)} → {nextZone.name} ({Format.abbreviate(nextZone.requiredSpeed)})`
		else `{zoneName(zoneId)} — zone finale`
	self.zoneBar.set(state:get("ZoneProgress"))

	local boosts = state.boosts
	if #boosts > 0 then
		local parts = {}
		for _, boost in boosts do
			table.insert(parts, `{boost.icon or "⏱"} {math.ceil(boost.remaining / 60)}min`)
		end
		self.boostLabel.Text = table.concat(parts, "  ")
		self.boostBar.Visible = true
	else
		self.boostBar.Visible = false
	end
end

return Hud
