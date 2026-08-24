--!strict
--[[
	OfferPopup — a limited-time offer, tucked in the bottom right corner.

	One offer at a time, with an honest countdown: the server stays the source of
	truth, the client only shows what it is given. No modal window ever interrupts a
	flight.
]]

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local OfferPopup = {}
OfferPopup.__index = OfferPopup

local POLL_INTERVAL = 10

function OfferPopup.new(parent: Instance, remotes)
	local card = Widgets.card(parent, {
		name = "Offer",
		size = UDim2.fromOffset(280, 152),
		position = UDim2.new(1, -18, 1, -18),
		anchorPoint = Vector2.new(1, 1),
		visible = false,
	})
	Widgets.padding(card, 12)

	local self = setmetatable({ card = card, remotes = remotes, current = nil }, OfferPopup)

	self.title = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 26),
		font = Theme.font.title,
		textSize = Theme.text.big,
		color = Theme.color.accentDark,
	})

	self.description = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 36),
		position = UDim2.fromOffset(0, 28),
		font = Theme.font.body,
		textSize = Theme.text.small,
		color = Theme.color.textMuted,
		wrapped = true,
		verticalAlign = Enum.TextYAlignment.Top,
	})

	self.countdown = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 68),
		font = Theme.font.number,
		textSize = Theme.text.small,
		color = Theme.color.negative,
	})

	self.action = Widgets.button(card, {
		text = "VIEW",
		size = UDim2.new(1, 0, 0, 46),
		position = UDim2.fromScale(0, 1),
		anchorPoint = Vector2.new(0, 1),
		textSize = Theme.text.big,
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
	self.action.Text = if offer.robux then `R$ {offer.robux}` else "VIEW"
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
