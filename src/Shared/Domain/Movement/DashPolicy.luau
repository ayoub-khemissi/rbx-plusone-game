--!strict
--[[
	DashPolicy — the burst of speed, and how hard it hits.

	UNLOCKING AND POWER ARE TWO PURCHASES, like the jump: one upgrade grants the
	dash at all, another buys how hard it hits. Selling them together makes the
	first level of a milestone carry a stat increase, and neither reads clearly.

	POWER IS A MULTIPLE OF THE RUN SPEED, not a fixed impulse. A fixed one is a
	rocket at walking pace and a nudge once the character is quick: the same button
	stops meaning the same thing halfway through the game. A multiple keeps a dash a
	dash from the first minute to the last, and the levels are stated in the terms
	the player reads on the shop row — x2 through x6.

	A cooldown, not a charge count, is what keeps it in check: a dash has to be a
	decision made at the right moment, not a resource to dump. It also means the
	mechanic never needs to know whether the character is on the ground.

	Like the jump budget, the state lives in the session: a cooldown is not something
	to persist.
]]

export type Tuning = {
	maxLevel: number,
	-- Multiple of the walk speed with the dash unlocked and no power bought.
	baseMultiplier: number,
	multiplierPerLevel: number,
	-- What one point of multiplier is worth as impulse. The shop shows the
	-- multiplier; this turns it into something the physics engine notices.
	powerScale: number,
	maxPower: number,
	cooldown: number,
}

export type State = {
	lastDashAt: number,
}

local DashPolicy = {}
DashPolicy.__index = DashPolicy

export type DashPolicy = typeof(setmetatable({} :: Tuning, DashPolicy))

local function isUsableTime(value: number): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function DashPolicy.new(tuning: Tuning): DashPolicy
	return setmetatable({
		maxLevel = tuning.maxLevel,
		baseMultiplier = tuning.baseMultiplier,
		multiplierPerLevel = tuning.multiplierPerLevel,
		powerScale = tuning.powerScale,
		maxPower = tuning.maxPower,
		cooldown = tuning.cooldown,
	}, DashPolicy)
end

function DashPolicy.newState(): State
	return { lastDashAt = -math.huge }
end

--[[ Whether the dash exists for this player at all. ]]
function DashPolicy.isUnlocked(_self: DashPolicy, bonuses: any): boolean
	local bought = (bonuses and bonuses.flat and bonuses.flat.dash) or 0
	return bought >= 1
end

--[[ How many power levels have been bought, capped by the design limit. ]]
function DashPolicy.powerLevelFor(self: DashPolicy, bonuses: any): number
	local bought = (bonuses and bonuses.flat and bonuses.flat.dashPower) or 0
	return math.clamp(math.floor(bought), 0, self.maxLevel)
end

--[[ The multiple of the run speed a dash is worth. This is what the shop sells. ]]
function DashPolicy.multiplierFor(self: DashPolicy, powerLevel: number): number
	local level = math.clamp(math.floor(powerLevel or 0), 0, self.maxLevel)
	return self.baseMultiplier + level * self.multiplierPerLevel
end

--[[
	Impulse of a dash for a character running at that speed.

	The multiplier is what the shop advertises; `powerScale` is what makes the
	engine feel it. Setting the velocity to exactly the run speed does nothing at
	all — the character was already moving that fast — so the impulse has to
	overshoot by a wide margin before a dash reads as a dash.

	Capped, for the reason the walk speed is capped rather than for balance: a body
	moving fast enough crosses a thin platform between two frames. At these values
	the ceiling is doing real work, and a map built from thin walls will want it
	lower.
]]
function DashPolicy.powerFor(self: DashPolicy, powerLevel: number, walkSpeed: number?): number
	local speed = if typeof(walkSpeed) == "number" and walkSpeed > 0 then walkSpeed else 0
	if speed <= 0 then
		return 0
	end
	return math.min(speed * self:multiplierFor(powerLevel) * self.powerScale, self.maxPower)
end

function DashPolicy.remainingCooldown(self: DashPolicy, state: State, now: number): number
	if not isUsableTime(now) or state.lastDashAt == -math.huge then
		return 0
	end
	return math.max(self.cooldown - (now - state.lastDashAt), 0)
end

--[[ Spends a dash. Returns the power granted, or 0 when it is refused. ]]
function DashPolicy.tryConsume(
	self: DashPolicy,
	state: State,
	powerLevel: number,
	walkSpeed: number,
	now: number
): number
	if not isUsableTime(now) then
		return 0
	end
	if self:remainingCooldown(state, now) > 0 then
		return 0
	end

	local power = self:powerFor(powerLevel, walkSpeed)
	if power <= 0 then
		return 0
	end

	state.lastDashAt = now
	return power
end

return DashPolicy
