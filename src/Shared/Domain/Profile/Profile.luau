--!strict
--[[
	Profile — the player's saved entity.

	Single source of truth for the shape of persisted data. `migrate` guarantees that
	an old, partial or corrupted save becomes a valid profile again: every persistence
	adapter must go through it.

	Schema v4 — theme-free. The vocabulary is deliberately neutral (speed, coins,
	prestiges, stages) so a theme can rename anything for display without touching a
	single line of code.

	What is NOT stored here: anything that belongs to a single run — the checkpoint
	the player is standing on, the air jumps already spent. Those live in the session.
]]

export type Totals = {
	distance: number,
	playtime: number,
	coinsEarned: number,
	prestiges: number,
	falls: number,
	checkpoints: number,
}

export type Purchases = {
	count: number,
	spentRobux: number,
	order: { string },
	ids: { [string]: boolean },
}

export type Profile = {
	version: number,

	-- Core progression
	speed: number,
	coins: number,
	prestiges: number,
	highestStage: number,
	upgrades: { [string]: number },

	totals: Totals,

	-- Monetization
	boosts: { [string]: number },
	purchases: Purchases,
	daily: { streak: number, lastClaimAt: number },
	timers: { [string]: number },
	codes: { [string]: boolean },
	offers: { seen: { [string]: number }, purchased: { [string]: boolean } },
}

local Profile = {}

Profile.SCHEMA_VERSION = 4

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
		coins = 0,
		prestiges = 0,
		highestStage = 0,
		upgrades = {},

		totals = {
			distance = 0,
			playtime = 0,
			coinsEarned = 0,
			prestiges = 0,
			falls = 0,
			checkpoints = 0,
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

--[[ Normalises any raw data into a valid profile. ]]
function Profile.migrate(raw: any): Profile
	local profile = Profile.create()
	if typeof(raw) ~= "table" then
		return profile
	end

	profile.speed = positiveNumber(raw.speed, 0)
	profile.coins = positiveNumber(raw.coins, 0)
	profile.prestiges = positiveInteger(raw.prestiges, 0, 0)
	profile.highestStage = positiveInteger(raw.highestStage, 0, 0)

	copyNumberMap(raw.upgrades, profile.upgrades, true)

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
