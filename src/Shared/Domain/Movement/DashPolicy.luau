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
	--[[
		What a dash is worth, as a multiple of the run speed, by power level. Index 1
		is the dash with nothing bought; each one after it is a level in the shop.

		A table rather than a formula because these are chosen numbers, not a curve:
		reading the list tells you exactly what the shop sells, and changing one
		level does not move the others.
	]]
	multipliers: { number },
	-- Seconds the dash is HELD. See powerFor for why this matters more than speed.
	duration: number,
	-- The slowest run speed the multiplier is allowed to apply to. See powerFor.
	floorSpeed: number,
	maxSpeed: number,
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
		multipliers = tuning.multipliers,
		maxLevel = #tuning.multipliers - 1,
		duration = tuning.duration,
		floorSpeed = tuning.floorSpeed,
		maxSpeed = tuning.maxSpeed,
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
	return self.multipliers[level + 1]
end

--[[
	Speed of a dash for a character running at that speed.

	IT IS A SPEED HELD FOR A WHILE, not an impulse. A single write to the velocity
	is undone by the Humanoid within two or three frames, which is why the first
	attempt needed absurd numbers to be felt at all and then crossed walls. Holding
	a modest speed for a fraction of a second travels much further, at a velocity
	the collision solver can still see.

	IT ALSO HAS A FLOOR. A multiple of the run speed is a small number while the run
	speed is small, so a level 1 character got a dash barely quicker than walking —
	the upgrade they had just bought did nothing they could see. The multiplier
	applies to whichever is greater, the run speed or the floor, so a dash is a
	burst from the first minute and only starts scaling once running has caught up.

	Capped at the other end for physics and no other reason: past the ceiling the
	character skips between two frames. A map built from thin walls will want it
	lower.
]]
function DashPolicy.powerFor(self: DashPolicy, powerLevel: number, walkSpeed: number?): number
	local speed = if typeof(walkSpeed) == "number" and walkSpeed > 0 then walkSpeed else 0
	if speed <= 0 then
		return 0
	end
	return math.min(math.max(speed, self.floorSpeed) * self:multiplierFor(powerLevel), self.maxSpeed)
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
