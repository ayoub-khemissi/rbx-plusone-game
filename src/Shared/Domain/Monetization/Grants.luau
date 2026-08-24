--!strict
--[[
	Grants — applies a declarative reward to a profile.

	A reward is a plain data table shared by EVERY source: purchased product, daily
	reward, chest, promo code, limited offer. Adding a revenue source therefore needs
	no new logic at all.

		{ gold = 5000 }
		{ eggs = { rarity = "rare", amount = 3 } }
		{ boost = { id = "swiftRush", duration = 1200 } }
		{ molts = 1 }
]]

export type Grant = {
	gold: number?,
	speed: number?,
	eggs: { rarity: string, amount: number }?,
	boost: { id: string, duration: number }?,
	molts: number?,
}

export type Context = {
	profile: any,
	boosts: any?,
	moltPolicy: any?,
	now: number,
}

export type Summary = {
	gold: number?,
	speed: number?,
	eggs: { rarity: string, amount: number }?,
	boost: { id: string, duration: number }?,
	molts: number?,
}

local Profile = require(script.Parent.Parent.Profile.Profile)

local Grants = {}

function Grants.apply(grant: Grant?, context: Context): Summary
	local summary: Summary = {}
	if typeof(grant) ~= "table" then
		return summary
	end

	local profile = context.profile

	-- Purchased gold is credited as-is: multipliers reward PLAYING, they must not
	-- make a purchase unpredictable.
	if typeof(grant.gold) == "number" and grant.gold > 0 then
		profile.gold += grant.gold
		profile.totals.goldEarned += grant.gold
		summary.gold = grant.gold
	end

	if typeof(grant.eggs) == "table" and typeof(grant.eggs.rarity) == "string" then
		Profile.addEggs(profile, grant.eggs.rarity, grant.eggs.amount or 0)
		summary.eggs = grant.eggs
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

	-- A purchased molt skips the speed requirement and, unlike the free one, keeps
	-- the upgrades: that is exactly what the player is paying for.
	if typeof(grant.molts) == "number" and grant.molts > 0 then
		local count = math.floor(grant.molts)
		profile.molts += count
		profile.totals.molts += count
		profile.speed = 0
		profile.deepestTier = 0
		summary.molts = count
	end

	return summary
end

return Grants
