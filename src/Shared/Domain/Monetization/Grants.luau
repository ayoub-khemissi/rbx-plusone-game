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

	AMOUNTS ARE QUOTED AT THE FIRST REBIRTH and paid in the money of the day. Income
	and shop prices are both multiplied by every rebirth taken, so a grant of a fixed
	5 000 buys a shop row on day one and nothing at all two worlds later — the
	product would quietly stop being worth its price. Scaling it keeps what the
	player receives worth exactly what it was worth when the price was set.
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

	--[[
		The rate everything is quoted at. It is the rebirth multiplier and nothing
		else: the player's own upgrades and boosts reward PLAYING and must not make a
		purchase unpredictable, but the rebirth count is what moves the whole economy
		underneath the price list.
	]]
	local rate = if context.prestigePolicy then context.prestigePolicy:multiplierFor(profile.prestiges) else 1

	if typeof(grant.coins) == "number" and grant.coins > 0 then
		local coins = math.floor(grant.coins * rate)
		profile.coins += coins
		profile.totals.coinsEarned += coins
		summary.coins = coins
	end

	if typeof(grant.speed) == "number" and grant.speed > 0 then
		local speed = math.floor(grant.speed * rate)
		profile.speed += speed
		summary.speed = speed
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
