--!strict
--[[
	Grants — application d'une recompense declarative a un profil.

	Une recompense est une simple table de donnees, partagee par TOUTES les sources :
	produit achete, recompense quotidienne, coffre, code promo, offre. Ajouter une
	source de revenus ne demande donc aucune nouvelle logique.

		{ bananas = 5000 }
		{ boost = { id = "speedRush", duration = 1200 } }
		{ rebirths = 1 }
]]

export type Grant = {
	bananas: number?,
	speed: number?,
	boost: { id: string, duration: number }?,
	rebirths: number?,
}

export type Context = {
	profile: any,
	boosts: any?,
	rebirthPolicy: any?,
	now: number,
}

export type Summary = {
	bananas: number?,
	speed: number?,
	boost: { id: string, duration: number }?,
	rebirths: number?,
}

local Grants = {}

function Grants.apply(grant: Grant?, context: Context): Summary
	local summary: Summary = {}
	if typeof(grant) ~= "table" then
		return summary
	end

	local profile = context.profile

	-- Les bananes achetees sont creditees telles quelles : les multiplicateurs
	-- servent a recompenser le JEU, pas a rendre les achats imprevisibles.
	if typeof(grant.bananas) == "number" and grant.bananas > 0 then
		profile.bananas += grant.bananas
		summary.bananas = grant.bananas
	end

	if typeof(grant.speed) == "number" and grant.speed > 0 then
		profile.speed += grant.speed
		summary.speed = grant.speed
	end

	if typeof(grant.boost) == "table" and context.boosts then
		if context.boosts:grant(profile, grant.boost.id, grant.boost.duration, context.now) then
			summary.boost = grant.boost
		end
	end

	-- Renaissance achetee : elle ignore le seuil et, contrairement a la renaissance
	-- gratuite, conserve les ameliorations (c'est la valeur percue du produit).
	if typeof(grant.rebirths) == "number" and grant.rebirths > 0 then
		local count = math.floor(grant.rebirths)
		profile.rebirths += count
		profile.totals.rebirths += count
		profile.speed = 0
		profile.highestZone = 1
		summary.rebirths = count
	end

	return summary
end

return Grants
