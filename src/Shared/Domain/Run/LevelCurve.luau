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
	-- What a level already reached costs to reach again. See requirementFor.
	knownDiscount: number?,
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
	return setmetatable({
		base = tuning.base,
		exponent = tuning.exponent,
		knownDiscount = tuning.knownDiscount or 1,
	}, LevelCurve)
end

--[[
	The total experience needed to reach a level, given the best already reached.

	GROUND ALREADY COVERED IS CHEAP TO COVER AGAIN. With an exponent near two, nine
	tenths of a world's experience sits in the last tenth of its levels, so after a
	rebirth a player spends most of the cycle re-walking what they had already done.
	Multiplying the gain cannot fix that — the gain is not what is expensive, the
	price is. So the price of a known level is a fraction of what it first cost, and
	anything past the best is full price.

	This deliberately does NOT shorten a world. Only the climb back is compressed;
	reaching genuinely new levels costs exactly what it did before, and a world is
	made of new levels.

	Level 1 is where everyone starts and costs nothing.
]]
function LevelCurve.requirementFor(self: LevelCurve, level: number, best: number?): number
	if level <= 1 then
		return 0
	end

	local full = self.base * level ^ self.exponent
	local covered = math.max(math.floor(best or 0), 0)
	if covered <= 1 then
		return math.floor(full)
	end

	if level <= covered then
		return math.floor(full * self.knownDiscount)
	end

	local known = self.base * covered ^ self.exponent
	return math.floor(known * self.knownDiscount + (full - known))
end

--[[
	The level a given Speed has reached.

	Inverting the formula lands within one level of the answer but not reliably on
	it: `^(1/exponent)` is a float operation, and at a boundary it can fall a
	fraction either side. The candidate is therefore corrected against
	`requirementFor`, which is the single definition of where a level starts. The
	correction runs at most a step or two — it is not a search.
]]
function LevelCurve.levelFor(self: LevelCurve, speed: number, best: number?): number
	if speed <= 0 then
		return 1
	end

	-- Inverting is no longer a closed form once a discount is in play, so the
	-- candidate comes from the undiscounted formula and is corrected against
	-- requirementFor, which stays the single definition of where a level starts.
	local candidate = math.max(math.floor((speed / self.base) ^ (1 / self.exponent)), 1)

	while self:requirementFor(candidate + 1, best) <= speed do
		candidate += 1
	end
	while candidate > 1 and self:requirementFor(candidate, best) > speed do
		candidate -= 1
	end

	return candidate
end

--[[ Where a Speed sits inside its level: what the progress bar draws. ]]
function LevelCurve.progressFor(self: LevelCurve, speed: number, best: number?): Progress
	local level = self:levelFor(speed, best)
	local floor = self:requirementFor(level, best)
	local ceiling = self:requirementFor(level + 1, best)
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
