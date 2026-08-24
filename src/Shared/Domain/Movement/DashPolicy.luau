--!strict
--[[
	DashPolicy — the burst of speed, and how hard it hits.

	Here the LEVEL IS THE POWER: that is what the player buys. Level 0 means no dash
	at all, and each level adds a fixed amount of impulse.

	A cooldown, not a charge count, is what keeps it in check: a dash has to be a
	decision made at the right moment, not a resource to dump. It also means the
	mechanic never needs to know whether the character is on the ground.

	Like the jump budget, the state lives in the session: a cooldown is not something
	to persist.
]]

export type Tuning = {
	maxLevel: number,
	basePower: number,
	powerPerLevel: number,
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
		basePower = tuning.basePower,
		powerPerLevel = tuning.powerPerLevel,
		cooldown = tuning.cooldown,
	}, DashPolicy)
end

function DashPolicy.newState(): State
	return { lastDashAt = -math.huge }
end

--[[ Dash level actually granted, capped by the design limit. ]]
function DashPolicy.levelFor(self: DashPolicy, bonuses: any): number
	local bought = (bonuses and bonuses.flat and bonuses.flat.dash) or 0
	return math.clamp(math.floor(bought), 0, self.maxLevel)
end

--[[ Impulse of a dash at that level. Level 0 has no dash at all. ]]
function DashPolicy.powerFor(self: DashPolicy, level: number): number
	if level <= 0 then
		return 0
	end
	return self.basePower + (math.min(level, self.maxLevel) - 1) * self.powerPerLevel
end

function DashPolicy.remainingCooldown(self: DashPolicy, state: State, now: number): number
	if not isUsableTime(now) or state.lastDashAt == -math.huge then
		return 0
	end
	return math.max(self.cooldown - (now - state.lastDashAt), 0)
end

--[[ Spends a dash. Returns the power granted, or 0 when it is refused. ]]
function DashPolicy.tryConsume(self: DashPolicy, state: State, level: number, now: number): number
	if level <= 0 or not isUsableTime(now) then
		return 0
	end
	if self:remainingCooldown(state, now) > 0 then
		return 0
	end

	state.lastDashAt = now
	return self:powerFor(level)
end

return DashPolicy
