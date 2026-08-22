--!strict
--[[
	Multipliers — agrege toutes les sources de bonus en un seul jeu de coefficients.

	Sources : ameliorations achetees, renaissances, zone courante, gamepasses.
	Les bonus de meme nature s'additionnent (+20% + 20% = +40%) puis les familles
	se multiplient entre elles : c'est ce qui rend la courbe lisible pour le joueur.
]]

local Profile = require(script.Parent.Parent.Profile.Profile)

type Profile = Profile.Profile

export type PassEffect = {
	speed: number?,
	bananas: number?,
	flat: { [string]: number }?,
}

export type Context = {
	zone: { stepMultiplier: number?, bananaMultiplier: number? }?,
	passes: { [string]: boolean }?,
}

export type Bonuses = {
	speed: number,
	bananas: number,
	flat: { [string]: number },
}

local SPEED_EFFECT = "speedMultiplier"
local BANANA_EFFECT = "bananaMultiplier"

local Multipliers = {}
Multipliers.__index = Multipliers

export type Dependencies = {
	catalog: any,
	rebirthPolicy: any,
	passEffects: { [string]: PassEffect }?,
}

export type Multipliers = typeof(setmetatable({} :: Dependencies, Multipliers))

function Multipliers.new(dependencies: Dependencies): Multipliers
	return setmetatable({
		catalog = dependencies.catalog,
		rebirthPolicy = dependencies.rebirthPolicy,
		passEffects = dependencies.passEffects or {},
	}, Multipliers)
end

function Multipliers.compute(self: Multipliers, profile: Profile, context: Context): Bonuses
	local zone = context.zone or {}
	local passes = context.passes or {}

	local speedBonus, bananaBonus = 0, 0
	local flat: { [string]: number } = { jumpPower = 0, wallGrip = 0, airDash = 0 }

	for _, upgradeId in self.catalog:ids() do
		local level = Profile.levelOf(profile, upgradeId)
		if level > 0 then
			local definition = self.catalog:get(upgradeId)
			local amount = self.catalog:effectFor(upgradeId, level)

			if definition.effect == SPEED_EFFECT then
				speedBonus += amount
			elseif definition.effect == BANANA_EFFECT then
				bananaBonus += amount
			else
				flat[definition.effect] = (flat[definition.effect] or 0) + amount
			end
		end
	end

	local passSpeed, passBananas = 1, 1
	for passId, owned in passes do
		local effect = owned and self.passEffects[passId]
		if effect then
			passSpeed *= effect.speed or 1
			passBananas *= effect.bananas or 1
			for key, amount in effect.flat or {} do
				flat[key] = (flat[key] or 0) + amount
			end
		end
	end

	local rebirthMultiplier = self.rebirthPolicy:multiplierFor(profile.rebirths)

	return {
		speed = (1 + speedBonus) * rebirthMultiplier * (zone.stepMultiplier or 1) * passSpeed,
		bananas = (1 + bananaBonus) * rebirthMultiplier * (zone.bananaMultiplier or 1) * passBananas,
		flat = flat,
	}
end

return Multipliers
