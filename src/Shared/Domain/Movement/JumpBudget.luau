--!strict
--[[
	JumpBudget — how many jumps the character has, and how many are left in the air.

	The domain speaks in LEVELS, exactly like the player: level 1 is a single jump,
	level 2 the double jump, level 3 the triple. "Air jumps" is only the subtraction
	the physics needs.

	The hard cap matters for level design. A player who could chain jumps forever
	would make every gap meaningless, and the maps would stop being obstacle courses.
	Upgrades and gamepasses may claim anything; this module decides what is honoured.

	The state belongs to the session, never to the save: being mid-air is not
	something that should survive a reconnection.
]]

export type Tuning = {
	maxJumpLevel: number,
}

export type State = {
	airJumpsUsed: number,
}

local JumpBudget = {}
JumpBudget.__index = JumpBudget

export type JumpBudget = typeof(setmetatable({} :: Tuning, JumpBudget))

function JumpBudget.new(tuning: Tuning): JumpBudget
	return setmetatable({ maxJumpLevel = tuning.maxJumpLevel }, JumpBudget)
end

function JumpBudget.newState(): State
	return { airJumpsUsed = 0 }
end

--[[ Jump level actually granted: 1 by default, capped by the design limit. ]]
function JumpBudget.levelFor(self: JumpBudget, bonuses: any): number
	local bought = (bonuses and bonuses.flat and bonuses.flat.jumps) or 0
	return math.clamp(1 + math.floor(bought), 1, self.maxJumpLevel)
end

--[[ Jumps available once already airborne — one less than the level. ]]
function JumpBudget.capacityFor(self: JumpBudget, bonuses: any): number
	return self:levelFor(bonuses) - 1
end

function JumpBudget.remaining(_self: JumpBudget, state: State, capacity: number): number
	return math.max(capacity - state.airJumpsUsed, 0)
end

--[[ Spends one air jump. Returns false when there is nothing left. ]]
function JumpBudget.tryConsume(self: JumpBudget, state: State, capacity: number): boolean
	if self:remaining(state, capacity) <= 0 then
		return false
	end
	state.airJumpsUsed += 1
	return true
end

function JumpBudget.land(_self: JumpBudget, state: State)
	state.airJumpsUsed = 0
end

return JumpBudget
