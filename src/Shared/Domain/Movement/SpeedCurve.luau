--!strict
--[[
	SpeedCurve — turns a LEVEL into the character's actual walk speed.

	Every level makes the character faster. It reads from the level rather than from
	the raw speed count on purpose: the level is what the player sees rise, so the
	reward is legible — a bar fills, a number goes up, running feels different.
	Driving it from an unbounded counter instead makes the same acceleration happen
	without anything on screen accounting for it.

	Past ~250 studs/s a Roblox character skips through thin floors and misses small
	platforms, which makes an obstacle course unplayable. The curve is therefore an
	inverse exponential: strictly rising, so no level is ever worthless, but bounded.

		walkSpeed(level) = base + maxBonus * (1 - e^(-(level - 1) / softness))

	Level 1 is the base walk speed, which is why the exponent counts levels GAINED.

	Jump power is separate and bought, not earned by running.
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

--[[ Share of the way to the ceiling, in [0, 1]. Used by the interface. ]]
function SpeedCurve.saturationFor(self: SpeedCurve, level: number): number
	local gained = math.max(sanitize(level) - 1, 0)
	return 1 - math.exp(-gained / self.tuning.softness)
end

function SpeedCurve.walkSpeedFor(self: SpeedCurve, level: number): number
	return self.tuning.baseWalkSpeed + self.tuning.maxBonusWalkSpeed * self:saturationFor(level)
end

function SpeedCurve.jumpPowerFor(self: SpeedCurve, jumpLevel: number): number
	local level = sanitize(jumpLevel)
	return math.min(
		self.tuning.baseJumpPower + level * self.tuning.jumpPowerPerLevel,
		self.tuning.maxJumpPower
	)
end

return SpeedCurve
