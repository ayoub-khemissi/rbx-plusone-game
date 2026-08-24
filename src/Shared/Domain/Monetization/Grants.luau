--!strict
--[[
	Grants — applies a declarative reward to a profile.

	A reward is a plain data table shared by EVERY source: purchased product, daily
	reward, chest, promo code, limited offer. Adding a revenue source therefore needs
	no new logic at all.

		{ coins = 5000 }
		{ speed = 250 }
		{ boost = { id = "speedRush", duration = 1200 } }
		{ prestiges = 1 }
]]

export type Grant = {
	coins: number?,
	speed: number?,
	boost: { id: string, duration: number }?,
	prestiges: number?,
}

export type Context = {
	profile: any,
	boosts: any?,
	prestigePolicy: any?,
	now: number,
}

export type Summary = {
	coins: number?,
	speed: number?,
	boost: { id: string, duration: number }?,
	prestiges: number?,
}

local Grants = {}

function Grants.apply(grant: Grant?, context: Context): Summary
	local summary: Summary = {}
	if typeof(grant) ~= "table" then
		return summary
	end

	local profile = context.profile

	-- Purchased Coins are credited as-is: multipliers reward PLAYING, they must not
	-- make a purchase unpredictable.
	if typeof(grant.coins) == "number" and grant.coins > 0 then
		profile.coins += grant.coins
		profile.totals.coinsEarned += grant.coins
		summary.coins = grant.coins
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

	-- A purchased prestige skips the speed requirement and, unlike the free one,
	-- keeps the upgrades: that is exactly what the player is paying for.
	if typeof(grant.prestiges) == "number" and grant.prestiges > 0 then
		local count = math.floor(grant.prestiges)
		profile.prestiges += count
		profile.totals.prestiges += count
		profile.speed = 0
		profile.highestStage = 0
		summary.prestiges = count
	end

	return summary
end

return Grants
