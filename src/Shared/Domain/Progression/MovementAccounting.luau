--!strict
--[[
	MovementAccounting — convertit un deplacement mesure en "pas" credites.

	C'est ici que vit l'anti-triche : le serveur mesure lui-meme le deplacement, puis
	le plafonne a ce qui est physiquement atteignable sur l'intervalle. Un teleport ou
	un multiplicateur de vitesse client ne rapporte donc rien de plus qu'une course
	honnete.
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

--[[ Distance au sol entre deux points : les sauts et les chutes ne rapportent rien. ]]
function MovementAccounting.horizontalDistance(_self: MovementAccounting, from: Point, to: Point): number
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

	local speedAllowance =
		math.max(if isFinite(currentWalkSpeed) then currentWalkSpeed else 0, tuning.minimumSpeedAllowance)
	local maxDistance = speedAllowance * tuning.toleranceFactor * deltaTime
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
