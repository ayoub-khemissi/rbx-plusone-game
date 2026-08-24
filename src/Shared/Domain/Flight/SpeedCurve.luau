--!strict
--[[
	SpeedCurve — turns accumulated speed into the dragon's actual flight velocity.

	Roblox physics stops being reliable past ~300 studs/s: a fast body can cross a thin
	wall between two frames and the collision is never seen. The curve is therefore an
	inverse exponential — strictly rising, but bounded. The counter can explode while
	the game stays fair.

		velocity(s) = base + maxBonus * (1 - e^(-s / softness))

	Agility is separate on purpose: it is the counterweight the player buys to stay
	able to steer as velocity climbs.
]]

export type Tuning = {
	baseVelocity: number,
	maxBonusVelocity: number,
	softness: number,
	baseAgility: number,
	agilityPerLevel: number,
	maxAgility: number,
}

local SpeedCurve = {}
SpeedCurve.__index = SpeedCurve

export type SpeedCurve = typeof(setmetatable({} :: { tuning: Tuning }, SpeedCurve))

local function sanitize(value: number): number
	if typeof(value) ~= "number" or value ~= value or value < 0 then
		return 0
	end
	return value
end

function SpeedCurve.new(tuning: Tuning): SpeedCurve
	return setmetatable({ tuning = tuning }, SpeedCurve)
end

--[[ Share of the run towards the ceiling, in [0, 1]. ]]
function SpeedCurve.saturationFor(self: SpeedCurve, speed: number): number
	return 1 - math.exp(-sanitize(speed) / self.tuning.softness)
end

function SpeedCurve.velocityFor(self: SpeedCurve, speed: number): number
	return self.tuning.baseVelocity + self.tuning.maxBonusVelocity * self:saturationFor(speed)
end

function SpeedCurve.agilityFor(self: SpeedCurve, agilityLevel: number): number
	local level = sanitize(agilityLevel)
	return math.min(self.tuning.baseAgility + level * self.tuning.agilityPerLevel, self.tuning.maxAgility)
end

return SpeedCurve
