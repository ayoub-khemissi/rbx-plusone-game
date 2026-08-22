--!strict
--[[
	Profile — entite de sauvegarde du joueur.

	Seule source de verite sur la forme des donnees persistees. `migrate` garantit
	qu'une sauvegarde ancienne, partielle ou corrompue redevient un profil valide :
	c'est le point d'entree oblige de tout adaptateur de persistance.

	Schema v2 : ajout des donnees de monetisation (boosts, achats, quotidien, codes,
	offres). Les profils v1 sont completes automatiquement.
]]

export type Totals = {
	steps: number,
	distance: number,
	playtime: number,
	bananasCollected: number,
	rebirths: number,
}

export type Purchases = {
	count: number,
	spentRobux: number,
	order: { string },
	ids: { [string]: boolean },
}

export type Profile = {
	version: number,
	speed: number,
	bananas: number,
	rebirths: number,
	highestZone: number,
	upgrades: { [string]: number },
	totals: Totals,
	boosts: { [string]: number }, -- [boostId] = horodatage d'expiration
	purchases: Purchases,
	daily: { streak: number, lastClaimAt: number },
	timers: { [string]: number }, -- [cle] = derniere reclamation (coffres periodiques)
	codes: { [string]: boolean },
	offers: { seen: { [string]: number }, purchased: { [string]: boolean } },
}

local Profile = {}

Profile.SCHEMA_VERSION = 2

local function positiveNumber(value: any, default: number): number
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return default
	end
	return math.max(value, 0)
end

local function positiveInteger(value: any, default: number, minimum: number): number
	return math.max(math.floor(positiveNumber(value, default)), minimum)
end

local function copyNumberMap(raw: any, target: { [string]: number })
	if typeof(raw) ~= "table" then
		return
	end
	for key, value in raw do
		if typeof(key) == "string" and typeof(value) == "number" then
			target[key] = positiveNumber(value, 0)
		end
	end
end

local function copyFlagMap(raw: any, target: { [string]: boolean })
	if typeof(raw) ~= "table" then
		return
	end
	for key, value in raw do
		if typeof(key) == "string" and value == true then
			target[key] = true
		end
	end
end

function Profile.create(): Profile
	return {
		version = Profile.SCHEMA_VERSION,
		speed = 0,
		bananas = 0,
		rebirths = 0,
		highestZone = 1,
		upgrades = {},
		totals = {
			steps = 0,
			distance = 0,
			playtime = 0,
			bananasCollected = 0,
			rebirths = 0,
		},
		boosts = {},
		purchases = {
			count = 0,
			spentRobux = 0,
			order = {},
			ids = {},
		},
		daily = { streak = 0, lastClaimAt = 0 },
		timers = {},
		codes = {},
		offers = { seen = {}, purchased = {} },
	}
end

function Profile.levelOf(profile: Profile, upgradeId: string): number
	return profile.upgrades[upgradeId] or 0
end

--[[ Normalise n'importe quelle donnee brute en profil valide. ]]
function Profile.migrate(raw: any): Profile
	local profile = Profile.create()
	if typeof(raw) ~= "table" then
		return profile
	end

	profile.speed = positiveNumber(raw.speed, 0)
	profile.bananas = positiveNumber(raw.bananas, 0)
	profile.rebirths = positiveInteger(raw.rebirths, 0, 0)
	profile.highestZone = positiveInteger(raw.highestZone, 1, 1)

	if typeof(raw.upgrades) == "table" then
		for id, level in raw.upgrades do
			if typeof(id) == "string" and typeof(level) == "number" then
				profile.upgrades[id] = positiveInteger(level, 0, 0)
			end
		end
	end

	if typeof(raw.totals) == "table" then
		for key, default in profile.totals do
			profile.totals[key] = positiveNumber(raw.totals[key], default)
		end
	end

	copyNumberMap(raw.boosts, profile.boosts)
	copyNumberMap(raw.timers, profile.timers)
	copyFlagMap(raw.codes, profile.codes)

	if typeof(raw.purchases) == "table" then
		profile.purchases.count = positiveInteger(raw.purchases.count, 0, 0)
		profile.purchases.spentRobux = positiveInteger(raw.purchases.spentRobux, 0, 0)
		if typeof(raw.purchases.order) == "table" then
			for _, purchaseId in raw.purchases.order do
				if typeof(purchaseId) == "string" then
					table.insert(profile.purchases.order, purchaseId)
					profile.purchases.ids[purchaseId] = true
				end
			end
		end
	end

	if typeof(raw.daily) == "table" then
		profile.daily.streak = positiveInteger(raw.daily.streak, 0, 0)
		profile.daily.lastClaimAt = positiveNumber(raw.daily.lastClaimAt, 0)
	end

	if typeof(raw.offers) == "table" then
		copyNumberMap(raw.offers.seen, profile.offers.seen)
		copyFlagMap(raw.offers.purchased, profile.offers.purchased)
	end

	return profile
end

return Profile
