--!strict
--[[
	LevelCurve — turns Speed into a level, and a level back into the Speed it costs.

	The player already had Speed, which is unbounded and quickly becomes a number
	rather than a milestone: 6 214 says nothing about how far along you are. A level
	is the same progress read as a rank, so there is always a next one, it is always
	close, and reaching it is an event.

	The curve is `base * level^exponent`. Multiplying instead — the other obvious
	choice — makes every level cost a fixed multiple of the last, so the early ones
	blur past and the late ones become unreachable. A power keeps the first levels
	quick, stretches the later ones, and never flattens.

	Nothing here decides what a level GRANTS. It does not: the rewards hang off
	Stages, which the map lays out, and a level is a readout. That separation is
	what lets the curve be retuned without touching the economy.
]]

export type Tuning = {
	base: number,
	exponent: number,
}

export type Progress = {
	level: number,
	current: number,
	required: number,
	ratio: number,
}

local LevelCurve = {}
LevelCurve.__index = LevelCurve

export type LevelCurve = typeof(setmetatable({} :: Tuning, LevelCurve))

function LevelCurve.new(tuning: Tuning): LevelCurve
	return setmetatable({ base = tuning.base, exponent = tuning.exponent }, LevelCurve)
end

--[[ The total Speed needed to reach a level. Level 1 is where everyone starts. ]]
function LevelCurve.requirementFor(self: LevelCurve, level: number): number
	if level <= 1 then
		return 0
	end
	return math.floor(self.base * level ^ self.exponent)
end

--[[
	The level a given Speed has reached.

	Inverting the formula lands within one level of the answer but not reliably on
	it: `^(1/exponent)` is a float operation, and at a boundary it can fall a
	fraction either side. The candidate is therefore corrected against
	`requirementFor`, which is the single definition of where a level starts. The
	correction runs at most a step or two — it is not a search.
]]
function LevelCurve.levelFor(self: LevelCurve, speed: number): number
	if speed <= 0 then
		return 1
	end

	local candidate = math.max(math.floor((speed / self.base) ^ (1 / self.exponent)), 1)

	while self:requirementFor(candidate + 1) <= speed do
		candidate += 1
	end
	while candidate > 1 and self:requirementFor(candidate) > speed do
		candidate -= 1
	end

	return candidate
end

--[[ Where a Speed sits inside its level: what the progress bar draws. ]]
function LevelCurve.progressFor(self: LevelCurve, speed: number): Progress
	local level = self:levelFor(speed)
	local floor = self:requirementFor(level)
	local ceiling = self:requirementFor(level + 1)
	local required = math.max(ceiling - floor, 1)
	local current = math.clamp(speed - floor, 0, required)

	return {
		level = level,
		current = current,
		required = required,
		ratio = current / required,
	}
end

return LevelCurve
