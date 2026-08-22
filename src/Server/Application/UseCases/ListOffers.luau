--!strict
--[[
	ListOffers — offres a duree limitee actuellement affichables pour un joueur.

	Le cas d'usage enrichit l'offre avec les donnees produit (nom, prix, identifiant
	Roblox) pour que le client n'ait aucune regle metier a connaitre.
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
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	local visible = self.offers:visibleFor(session.profile, {
		playtime = session.profile.totals.playtime,
		now = self.clock.now(),
	})

	local offers = {}
	for _, offer in visible do
		local product = self.products:get(offer.productKey)
		-- Une offre dont le produit n'est pas configure ne doit jamais s'afficher.
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
