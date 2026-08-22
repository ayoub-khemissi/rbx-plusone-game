--!strict
--[[
	OfferPopup — offre a duree limitee, affichee discretement en bas a droite.

	Une seule offre a la fois, avec un compte a rebours honnete : le serveur reste
	la source de verite, le client ne fait qu'afficher ce qu'il recoit.
]]

-- Pas de fenetre modale : une offre ne doit jamais interrompre la course.
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local OfferPopup = {}
OfferPopup.__index = OfferPopup

local POLL_INTERVAL = 10

function OfferPopup.new(parent: ScreenGui, remotes)
	local card = Widgets.card(parent, {
		name = "Offre",
		size = UDim2.fromOffset(250, 132),
		position = UDim2.new(1, -14, 1, -14),
		anchorPoint = Vector2.new(1, 1),
		color = Theme.color.panelLight,
		visible = false,
	})
	Widgets.padding(card, 10)

	local self = setmetatable({ card = card, remotes = remotes, current = nil }, OfferPopup)

	self.title = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 24),
		font = Theme.font.title,
		color = Theme.color.accent,
		text = "",
	})

	self.description = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 32),
		position = UDim2.fromOffset(0, 26),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		wrapped = true,
		text = "",
		textScaled = false,
	})
	self.description.TextSize = 14

	self.countdown = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 18),
		position = UDim2.fromOffset(0, 60),
		font = Theme.font.number,
		color = Theme.color.negative,
		text = "",
		textScaled = false,
	})
	self.countdown.TextSize = 14

	self.action = Widgets.button(card, {
		text = "VOIR",
		size = UDim2.new(1, 0, 0, 40),
		position = UDim2.fromScale(0, 1),
		anchorPoint = Vector2.new(0, 1),
		color = Theme.color.positive,
		onClick = function()
			if self.current then
				self.remotes.events.PromptPurchase:FireServer("product", self.current.productKey)
			end
		end,
	})

	task.spawn(function()
		while true do
			self:refresh()
			task.wait(POLL_INTERVAL)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			self:tick()
		end
	end)

	return self
end

function OfferPopup.refresh(self)
	local ok, offers = pcall(function()
		return self.remotes.functions.GetOffers:InvokeServer()
	end)

	if not ok or typeof(offers) ~= "table" or #offers == 0 then
		self.current = nil
		self.card.Visible = false
		return
	end

	local offer = offers[1]
	self.current = offer
	self.title.Text = `{offer.icon or "🎁"} {offer.title}`
	self.description.Text = offer.description or ""
	self.action.Text = if offer.robux then `R$ {offer.robux}` else "VOIR"
	self.card.Visible = true
end

function OfferPopup.tick(self)
	if not self.current then
		return
	end

	self.current.secondsRemaining -= 1
	if self.current.secondsRemaining <= 0 then
		self.current = nil
		self.card.Visible = false
		return
	end

	local minutes = math.floor(self.current.secondsRemaining / 60)
	local seconds = math.floor(self.current.secondsRemaining % 60)
	self.countdown.Text = string.format("⏳ %d:%02d", minutes, seconds)
end

return OfferPopup
