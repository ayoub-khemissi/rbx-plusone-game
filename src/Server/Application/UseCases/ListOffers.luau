--!strict
--[[
	ListOffers — the limited-time offers a player can currently see.

	The use case enriches the offer with its product data so the client holds no
	business rule of its own.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local ListOffers = {}
ListOffers.__index = ListOffers

function ListOffers.new(dependencies)
	return setmetatable(table.clone(dependencies), ListOffers)
end

function ListOffers.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local visible = self.offers:visibleFor(session.profile, {
		playtime = session.profile.totals.playtime,
		now = self.clock.now(),
	})

	local offers = {}
	for _, offer in visible do
		local product = self.products:get(offer.productKey)
		-- An offer whose product is not configured must never show up.
		if product and self.products:isConfigured(offer.productKey) then
			table.insert(offers, {
				id = offer.id,
				title = offer.definition.title or product.name,
				description = offer.definition.description or product.description,
				secondsRemaining = offer.secondsRemaining,
				productKey = offer.productKey,
				productId = product.productId,
				robux = product.robux,
				icon = product.icon,
			})
		end
	end

	return Result.ok({ offers = offers })
end

return ListOffers
