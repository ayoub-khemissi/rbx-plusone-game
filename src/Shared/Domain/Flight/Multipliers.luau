--!strict
--[[
	Multipliers — folds every bonus source into one set of coefficients.

	Sources: upgrades bought with gold, molts, gamepasses, timed boosts, and the
	dragons in the collection. Bonuses of the same nature add up (+20% + 20% = +40%),
	then the families multiply together — that is what keeps the curve readable.

	The tier's gold multiplier is deliberately NOT applied here: it rewards banking,
	not picking up. Applying it twice would silently double every payout.
]]

local Profile = require(script.Parent.Parent.Profile.Profile)

type Profile = Profile.Profile

export type PassEffect = {
	speed: number?,
	gold: number?,
	flat: { [string]: number }?,
}

export type Context = {
	tier: { goldMultiplier: number? }?,
	passes: { [string]: boolean }?,
	boosts: { speed: number?, gold: number? }?,
	dragons: { speed: number?, gold: number?, agility: number?, hatch: number? }?,
}

export type Bonuses = {
	speed: number,
	gold: number,
	hatch: number,
	flat: { [string]: number },
}

local SPEED_EFFECT = "speedMultiplier"
local GOLD_EFFECT = "goldMultiplier"

local Multipliers = {}
Multipliers.__index = Multipliers

export type Dependencies = {
	catalog: any,
	moltPolicy: any,
	passEffects: { [string]: PassEffect }?,
}

export type Multipliers = typeof(setmetatable({} :: Dependencies, Multipliers))

function Multipliers.new(dependencies: Dependencies): Multipliers
	return setmetatable({
		catalog = dependencies.catalog,
		moltPolicy = dependencies.moltPolicy,
		passEffects = dependencies.passEffects or {},
	}, Multipliers)
end

function Multipliers.compute(self: Multipliers, profile: Profile, context: Context): Bonuses
	local passes = context.passes or {}
	local boosts = context.boosts or {}
	local dragons = context.dragons or {}

	local speedBonus, goldBonus = 0, 0
	local flat: { [string]: number } = { agility = 0, magnet = 0, feathers = 0 }

	for _, upgradeId in self.catalog:ids() do
		local level = Profile.levelOf(profile, upgradeId)
		if level > 0 then
			local definition = self.catalog:get(upgradeId)
			local amount = self.catalog:effectFor(upgradeId, level)

			if definition.effect == SPEED_EFFECT then
				speedBonus += amount
			elseif definition.effect == GOLD_EFFECT then
				goldBonus += amount
			else
				flat[definition.effect] = (flat[definition.effect] or 0) + amount
			end
		end
	end

	local passSpeed, passGold = 1, 1
	for passId, owned in passes do
		local effect = owned and self.passEffects[passId]
		if effect then
			passSpeed *= effect.speed or 1
			passGold *= effect.gold or 1
			for key, amount in effect.flat or {} do
				flat[key] = (flat[key] or 0) + amount
			end
		end
	end

	-- Les dragons apportent des pourcentages additifs, comme les ameliorations.
	flat.agility += dragons.agility or 0

	local moltMultiplier = self.moltPolicy:multiplierFor(profile.molts)

	return {
		speed = (1 + speedBonus + (dragons.speed or 0)) * moltMultiplier * passSpeed * (boosts.speed or 1),
		gold = (1 + goldBonus + (dragons.gold or 0)) * moltMultiplier * passGold * (boosts.gold or 1),
		hatch = 1 + (dragons.hatch or 0),
		flat = flat,
	}
end

return Multipliers
