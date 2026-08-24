--!strict
--[[
	SpeedCurve — turns accumulated speed into the character's actual walk speed.

	Past ~250 studs/s a Roblox character skips through thin floors and misses small
	platforms, which would make an obstacle course unplayable. The curve is therefore
	an inverse exponential: strictly rising, but bounded.

		walkSpeed(s) = base + maxBonus * (1 - e^(-s / softness))

	Jump power is separate and level based: it is bought, not earned by running.
]]

export type Tuning = {
	baseWalkSpeed: number,
	maxBonusWalkSpeed: number,
	softness: number,
	baseJumpPower: number,
	jumpPowerPerLevel: number,
	maxJumpPower: number,
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

--[[ Share of the run towards the ceiling, in [0, 1]. Used by the interface. ]]
function SpeedCurve.saturationFor(self: SpeedCurve, speed: number): number
	return 1 - math.exp(-sanitize(speed) / self.tuning.softness)
end

function SpeedCurve.walkSpeedFor(self: SpeedCurve, speed: number): number
	return self.tuning.baseWalkSpeed + self.tuning.maxBonusWalkSpeed * self:saturationFor(speed)
end

function SpeedCurve.jumpPowerFor(self: SpeedCurve, jumpLevel: number): number
	local level = sanitize(jumpLevel)
	return math.min(
		self.tuning.baseJumpPower + level * self.tuning.jumpPowerPerLevel,
		self.tuning.maxJumpPower
	)
end

return SpeedCurve
