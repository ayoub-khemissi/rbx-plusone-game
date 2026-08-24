--!strict
--[[
	MovementAccounting — turns measured displacement into credited steps.

	This is where the anti-cheat lives: the server measures the character itself, then
	clamps the result to what is physically reachable over the interval. A teleport or
	a client-side speed hack earns nothing more than an honest run.

	Only ground distance counts. Jumping up and down on the spot is not running, and
	must never pay.
]]

export type Tuning = {
	studsPerStep: number,
	deadzone: number,
	toleranceFactor: number,
	minimumSpeedAllowance: number,
}

export type Reading = {
	steps: number,
	distance: number,
	clamped: boolean,
}

export type Point = { x: number, y: number, z: number }

local MovementAccounting = {}
MovementAccounting.__index = MovementAccounting

export type MovementAccounting = typeof(setmetatable({} :: { tuning: Tuning }, MovementAccounting))

local EMPTY: Reading = { steps = 0, distance = 0, clamped = false }

local function isFinite(value: number): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function MovementAccounting.new(tuning: Tuning): MovementAccounting
	return setmetatable({ tuning = tuning }, MovementAccounting)
end

--[[ Ground distance between two points: the vertical axis is ignored. ]]
function MovementAccounting.distanceBetween(_self: MovementAccounting, from: Point, to: Point): number
	local dx, dz = to.x - from.x, to.z - from.z
	return math.sqrt(dx * dx + dz * dz)
end

function MovementAccounting.measure(
	self: MovementAccounting,
	distance: number,
	deltaTime: number,
	currentWalkSpeed: number
): Reading
	local tuning = self.tuning

	if not isFinite(deltaTime) or deltaTime <= 0 then
		return table.clone(EMPTY)
	end
	if typeof(distance) ~= "number" or distance ~= distance or distance <= 0 then
		return table.clone(EMPTY)
	end

	local allowance =
		math.max(if isFinite(currentWalkSpeed) then currentWalkSpeed else 0, tuning.minimumSpeedAllowance)
	local maxDistance = allowance * tuning.toleranceFactor * deltaTime
	local clamped = distance > maxDistance
	local effective = math.min(distance, maxDistance)

	if effective < tuning.deadzone then
		return table.clone(EMPTY)
	end

	return {
		steps = effective / tuning.studsPerStep,
		distance = effective,
		clamped = clamped,
	}
end

return MovementAccounting
