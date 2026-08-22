--!strict
--[[
	BoostStack — boosts temporaires (x2 vitesse pendant 20 min, fete du serveur...).

	Deux proprietes importantes pour le modele economique :
	  1. les boosts sont PERSISTES dans le profil : un joueur qui achete puis se
	     deconnecte ne perd pas ce qu'il a paye (confiance = rachat) ;
	  2. les achats successifs du meme boost s'ADDITIONNENT en duree, avec un
	     plafond, ce qui encourage l'achat repete sans casser l'equilibrage.
]]

export type Definition = {
	name: string?,
	icon: string?,
	speed: number?,
	bananas: number?,
}

export type Tuning = {
	definitions: { [string]: Definition },
	maxStackedDuration: number,
}

export type ActiveBoost = {
	id: string,
	name: string,
	icon: string?,
	remaining: number,
	speed: number,
	bananas: number,
}

local BoostStack = {}
BoostStack.__index = BoostStack

export type BoostStack = typeof(setmetatable({} :: Tuning, BoostStack))

function BoostStack.new(tuning: Tuning): BoostStack
	return setmetatable({
		definitions = tuning.definitions,
		maxStackedDuration = tuning.maxStackedDuration,
	}, BoostStack)
end

function BoostStack.definitionOf(self: BoostStack, boostId: string): Definition?
	return self.definitions[boostId]
end

function BoostStack.remainingFor(_self: BoostStack, profile: any, boostId: string, now: number): number
	local expiresAt = profile.boosts[boostId]
	if not expiresAt then
		return 0
	end
	return math.max(expiresAt - now, 0)
end

function BoostStack.isActive(self: BoostStack, profile: any, boostId: string, now: number): boolean
	return self:remainingFor(profile, boostId, now) > 0
end

--[[ Ajoute du temps a un boost. Renvoie false si le boost n'existe pas. ]]
function BoostStack.grant(
	self: BoostStack,
	profile: any,
	boostId: string,
	duration: number,
	now: number
): boolean
	if not self.definitions[boostId] or typeof(duration) ~= "number" or duration <= 0 then
		return false
	end

	local remaining = self:remainingFor(profile, boostId, now)
	local total = math.min(remaining + duration, self.maxStackedDuration)
	profile.boosts[boostId] = now + total
	return true
end

--[[ Retire du profil les boosts arrives a expiration (garde la sauvegarde propre). ]]
function BoostStack.prune(_self: BoostStack, profile: any, now: number)
	for boostId, expiresAt in profile.boosts do
		if expiresAt <= now then
			profile.boosts[boostId] = nil
		end
	end
end

function BoostStack.activeFor(self: BoostStack, profile: any, now: number): { ActiveBoost }
	local active: { ActiveBoost } = {}

	for boostId, expiresAt in profile.boosts do
		local definition = self.definitions[boostId]
		if definition and expiresAt > now then
			table.insert(active, {
				id = boostId,
				name = definition.name or boostId,
				icon = definition.icon,
				remaining = expiresAt - now,
				speed = definition.speed or 1,
				bananas = definition.bananas or 1,
			})
		end
	end

	table.sort(active, function(left, right)
		return left.id < right.id
	end)

	return active
end

--[[ Multiplicateurs cumules des boosts actifs (multiplicatifs entre eux). ]]
function BoostStack.multipliersFor(
	self: BoostStack,
	profile: any,
	now: number
): { speed: number, bananas: number }
	local speed, bananas = 1, 1

	for _, boost in self:activeFor(profile, now) do
		speed *= boost.speed
		bananas *= boost.bananas
	end

	return { speed = speed, bananas = bananas }
end

return BoostStack
