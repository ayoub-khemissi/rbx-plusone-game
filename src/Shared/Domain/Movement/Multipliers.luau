--!strict
--[[
	Multipliers — folds every bonus source into one set of coefficients.

	Sources: upgrades bought with Coins, prestiges, gamepasses, timed boosts, and the
	Stage the player is running through. Bonuses of the same nature add up
	(+20% + 20% = +40%), then the families multiply together — that is what keeps the
	curve readable.

	Deliberately free of any theme: it only knows `speed`, `coins` and flat bonuses.
]]

local Profile = require(script.Parent.Parent.Profile.Profile)

type Profile = Profile.Profile

export type PassEffect = {
	speed: number?,
	coins: number?,
	flat: { [string]: number }?,
}

export type Context = {
	stage: { coinMultiplier: number? }?,
	passes: { [string]: boolean }?,
	boosts: { speed: number?, coins: number? }?,
}

export type Bonuses = {
	speed: number,
	coins: number,
	flat: { [string]: number },
}

local SPEED_EFFECT = "speedMultiplier"
local COIN_EFFECT = "coinMultiplier"

local Multipliers = {}
Multipliers.__index = Multipliers

export type Dependencies = {
	catalog: any,
	prestigePolicy: any,
	passEffects: { [string]: PassEffect }?,
}

export type Multipliers = typeof(setmetatable({} :: Dependencies, Multipliers))

function Multipliers.new(dependencies: Dependencies): Multipliers
	return setmetatable({
		catalog = dependencies.catalog,
		prestigePolicy = dependencies.prestigePolicy,
		passEffects = dependencies.passEffects or {},
	}, Multipliers)
end

function Multipliers.compute(self: Multipliers, profile: Profile, context: Context): Bonuses
	local stage = context.stage or {}
	local passes = context.passes or {}
	local boosts = context.boosts or {}

	local speedBonus, coinBonus = 0, 0
	local flat: { [string]: number } = { jumpPower = 0, jumps = 0, dash = 0, magnet = 0 }

	for _, upgradeId in self.catalog:ids() do
		local level = Profile.levelOf(profile, upgradeId)
		if level > 0 then
			local definition = self.catalog:get(upgradeId)
			local amount = self.catalog:effectFor(upgradeId, level)

			if definition.effect == SPEED_EFFECT then
				speedBonus += amount
			elseif definition.effect == COIN_EFFECT then
				coinBonus += amount
			else
				flat[definition.effect] = (flat[definition.effect] or 0) + amount
			end
		end
	end

	local passSpeed, passCoins = 1, 1
	for passId, owned in passes do
		local effect = owned and self.passEffects[passId]
		if effect then
			passSpeed *= effect.speed or 1
			passCoins *= effect.coins or 1
			for key, amount in effect.flat or {} do
				flat[key] = (flat[key] or 0) + amount
			end
		end
	end

	local prestigeMultiplier = self.prestigePolicy:multiplierFor(profile.prestiges)

	return {
		speed = (1 + speedBonus) * prestigeMultiplier * passSpeed * (boosts.speed or 1),
		coins = (1 + coinBonus)
			* prestigeMultiplier
			* passCoins
			* (boosts.coins or 1)
			* (stage.coinMultiplier or 1),
		flat = flat,
	}
end

return Multipliers
