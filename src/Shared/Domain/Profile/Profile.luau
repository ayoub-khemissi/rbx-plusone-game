--!strict
--[[
	Profile — entite de sauvegarde du joueur.

	Seule source de verite sur la forme des donnees persistees. `migrate` garantit
	qu'une sauvegarde ancienne, partielle ou corrompue redevient un profil valide :
	c'est le point d'entree oblige de tout adaptateur de persistance.
]]

export type Totals = {
	steps: number,
	distance: number,
	playtime: number,
	bananasCollected: number,
	rebirths: number,
}

export type Profile = {
	version: number,
	speed: number,
	bananas: number,
	rebirths: number,
	highestZone: number,
	upgrades: { [string]: number },
	totals: Totals,
}

local Profile = {}

Profile.SCHEMA_VERSION = 1

local function positiveNumber(value: any, default: number): number
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return default
	end
	return math.max(value, 0)
end

local function positiveInteger(value: any, default: number, minimum: number): number
	return math.max(math.floor(positiveNumber(value, default)), minimum)
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

	return profile
end

return Profile
