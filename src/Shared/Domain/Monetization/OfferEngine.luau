--!strict
--[[
	OfferEngine — offres a duree limitee, presentees au bon moment.

	Deux declencheurs :
	  - `triggerAfterSeconds` : apres N secondes de jeu (pack de bienvenue) ;
	  - `trigger` : sur evenement metier (le joueur bute sur une barriere de zone).

	Regle produit : une seule offre visible a la fois (`maxVisible`), la plus
	ancienne d'abord. Empiler les fenetres d'achat fait fuir les joueurs.
]]

export type Definition = {
	id: string,
	productKey: string,
	triggerAfterSeconds: number?,
	trigger: string?,
	durationSeconds: number,
	oncePerProfile: boolean?,
	title: string?,
	description: string?,
}

export type VisibleOffer = {
	id: string,
	productKey: string,
	secondsRemaining: number,
	definition: Definition,
}

export type Context = {
	playtime: number,
	now: number,
}

local OfferEngine = {}
OfferEngine.__index = OfferEngine

export type OfferEngine = typeof(setmetatable(
	{} :: { _definitions: { Definition }, maxVisible: number },
	OfferEngine
))

function OfferEngine.new(definitions: { Definition }, maxVisible: number?): OfferEngine
	return setmetatable({ _definitions = definitions, maxVisible = maxVisible or 1 }, OfferEngine)
end

function OfferEngine.definitions(self: OfferEngine): { Definition }
	return self._definitions
end

local function isExhausted(profile: any, definition: Definition): boolean
	return definition.oncePerProfile == true and profile.offers.purchased[definition.id] == true
end

--[[ Declenche une offre contextuelle (ex : "zoneBlocked"). ]]
function OfferEngine.trigger(self: OfferEngine, profile: any, event: string, now: number): boolean
	local triggered = false
	for _, definition in self._definitions do
		if definition.trigger == event and not isExhausted(profile, definition) then
			local startedAt = profile.offers.seen[definition.id]
			-- On ne relance pas une offre deja affichee et encore valide.
			if not startedAt or now > startedAt + definition.durationSeconds then
				profile.offers.seen[definition.id] = now
				triggered = true
			end
		end
	end
	return triggered
end

function OfferEngine.markPurchased(_self: OfferEngine, profile: any, offerId: string)
	profile.offers.purchased[offerId] = true
end

--[[ Marque comme consommees toutes les offres qui vendaient ce produit. ]]
function OfferEngine.markPurchasedByProduct(self: OfferEngine, profile: any, productKey: string)
	for _, definition in self._definitions do
		if definition.productKey == productKey then
			profile.offers.purchased[definition.id] = true
		end
	end
end

--[[ Offres actuellement affichables. Peut demarrer une offre passive au passage. ]]
function OfferEngine.visibleFor(self: OfferEngine, profile: any, context: Context): { VisibleOffer }
	local candidates = {}

	for _, definition in self._definitions do
		if not isExhausted(profile, definition) then
			local startedAt = profile.offers.seen[definition.id]

			if
				not startedAt
				and definition.triggerAfterSeconds
				and context.playtime >= definition.triggerAfterSeconds
			then
				startedAt = context.now
				profile.offers.seen[definition.id] = startedAt
			end

			if startedAt then
				local remaining = startedAt + definition.durationSeconds - context.now
				if remaining > 0 then
					table.insert(candidates, {
						id = definition.id,
						productKey = definition.productKey,
						secondsRemaining = remaining,
						definition = definition,
						_startedAt = startedAt,
					})
				end
			end
		end
	end

	table.sort(candidates, function(left, right)
		return left._startedAt < right._startedAt
	end)

	local visible = {}
	for index = 1, math.min(#candidates, self.maxVisible) do
		local candidate = candidates[index]
		table.insert(visible, {
			id = candidate.id,
			productKey = candidate.productKey,
			secondsRemaining = candidate.secondsRemaining,
			definition = candidate.definition,
		})
	end

	return visible
end

return OfferEngine
