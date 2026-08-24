--!strict
--[[
	Profile — the player's saved entity.

	Single source of truth for the shape of persisted data. `migrate` guarantees that
	an old, partial or corrupted save becomes a valid profile again: every persistence
	adapter must go through it.

	Schema v3 — dragon flight. Speed and gold replace the previous run currencies,
	eggs and dragons back the collection loop, and the monetization fields from v2 are
	kept untouched.

	What is NOT stored here: anything that belongs to a single flight (the pouch, the
	idle counter). A run must never survive a reconnection.
]]

export type Totals = {
	distance: number,
	flights: number,
	playtime: number,
	goldEarned: number,
	eggsHatched: number,
	molts: number,
	walls: number,
}

export type Purchases = {
	count: number,
	spentRobux: number,
	order: { string },
	ids: { [string]: boolean },
}

export type Egg = {
	rarity: string,
	readyAt: number?, -- nil while still in stock, set once placed in the hatchery
}

export type Profile = {
	version: number,

	-- Flight progression
	speed: number,
	gold: number,
	molts: number,
	deepestTier: number,
	upgrades: { [string]: number },

	-- Paid safety net: flights that still refund half the pouch on a wall.
	insuredFlights: number,

	-- Collection
	eggs: { [string]: number }, -- stock waiting for a hatchery slot, keyed by rarity
	hatchery: { Egg }, -- eggs currently incubating
	dragons: { [string]: number }, -- owned species and how many of each

	totals: Totals,

	-- Monetization (unchanged since v2)
	boosts: { [string]: number },
	purchases: Purchases,
	daily: { streak: number, lastClaimAt: number },
	timers: { [string]: number },
	codes: { [string]: boolean },
	offers: { seen: { [string]: number }, purchased: { [string]: boolean } },
}

local Profile = {}

Profile.SCHEMA_VERSION = 3

local function positiveNumber(value: any, default: number): number
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return default
	end
	return math.max(value, 0)
end

local function positiveInteger(value: any, default: number, minimum: number): number
	return math.max(math.floor(positiveNumber(value, default)), minimum)
end

local function copyNumberMap(raw: any, target: { [string]: number }, integer: boolean?)
	if typeof(raw) ~= "table" then
		return
	end
	for key, value in raw do
		if typeof(key) == "string" and typeof(value) == "number" then
			target[key] = if integer then positiveInteger(value, 0, 0) else positiveNumber(value, 0)
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
		gold = 0,
		molts = 0,
		deepestTier = 0,
		upgrades = {},

		insuredFlights = 0,

		eggs = {},
		hatchery = {},
		dragons = {},

		totals = {
			distance = 0,
			flights = 0,
			playtime = 0,
			goldEarned = 0,
			eggsHatched = 0,
			molts = 0,
			walls = 0,
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

function Profile.eggsOf(profile: Profile, rarity: string): number
	return profile.eggs[rarity] or 0
end

function Profile.addEggs(profile: Profile, rarity: string, amount: number)
	profile.eggs[rarity] = Profile.eggsOf(profile, rarity) + math.max(math.floor(amount), 0)
end

--[[ Normalises any raw data into a valid profile. ]]
function Profile.migrate(raw: any): Profile
	local profile = Profile.create()
	if typeof(raw) ~= "table" then
		return profile
	end

	profile.speed = positiveNumber(raw.speed, 0)
	profile.gold = positiveNumber(raw.gold, 0)
	profile.molts = positiveInteger(raw.molts, 0, 0)
	profile.deepestTier = positiveInteger(raw.deepestTier, 0, 0)
	profile.insuredFlights = positiveInteger(raw.insuredFlights, 0, 0)

	copyNumberMap(raw.upgrades, profile.upgrades, true)
	copyNumberMap(raw.eggs, profile.eggs, true)
	copyNumberMap(raw.dragons, profile.dragons, true)

	if typeof(raw.hatchery) == "table" then
		for _, egg in raw.hatchery do
			if typeof(egg) == "table" and typeof(egg.rarity) == "string" then
				table.insert(profile.hatchery, {
					rarity = egg.rarity,
					readyAt = if typeof(egg.readyAt) == "number" then positiveNumber(egg.readyAt, 0) else nil,
				})
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
