--!strict
--[[
	FlightAccounting — turns measured displacement into credited steps.

	This is where the anti-cheat lives: the server measures the dragon itself, then
	clamps the result to what is physically reachable over the interval. A teleport or
	a client-side speed hack earns nothing more than an honest flight.

	Unlike the ground game this measures all three axes: climbing is flying too, and
	altitude is progress.
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

local FlightAccounting = {}
FlightAccounting.__index = FlightAccounting

export type FlightAccounting = typeof(setmetatable({} :: { tuning: Tuning }, FlightAccounting))

local EMPTY: Reading = { steps = 0, distance = 0, clamped = false }

local function isFinite(value: number): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function FlightAccounting.new(tuning: Tuning): FlightAccounting
	return setmetatable({ tuning = tuning }, FlightAccounting)
end

--[[ Full 3D distance: in flight, altitude counts as much as forward travel. ]]
function FlightAccounting.distanceBetween(_self: FlightAccounting, from: Point, to: Point): number
	local dx, dy, dz = to.x - from.x, to.y - from.y, to.z - from.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function FlightAccounting.measure(
	self: FlightAccounting,
	distance: number,
	deltaTime: number,
	currentVelocity: number
): Reading
	local tuning = self.tuning

	if not isFinite(deltaTime) or deltaTime <= 0 then
		return table.clone(EMPTY)
	end
	if typeof(distance) ~= "number" or distance ~= distance or distance <= 0 then
		return table.clone(EMPTY)
	end

	local allowance =
		math.max(if isFinite(currentVelocity) then currentVelocity else 0, tuning.minimumSpeedAllowance)
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

return FlightAccounting
