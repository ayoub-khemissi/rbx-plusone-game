--!strict
--[[
	SkyLayout — the geometry of the sky, expressed as plain numbers.

	No Roblox type (Vector3 / CFrame) appears here: adapters convert. That is what
	makes the level topology testable outside Studio.

	Each tier is a corridor stacked further along +X and higher than the previous one,
	so altitude reads as progress at a glance.
]]

export type Tuning = {
	launchX: number,
	corridorWidth: number,
	corridorHeight: number,
	baseAltitude: number,
	altitudeStep: number,
	altarOffset: number,
	ringSpacing: number,
	ringWeave: number,
}

export type Point = { x: number, y: number, z: number }

export type Bounds = {
	startX: number,
	endX: number,
	length: number,
	altitude: number,
	width: number,
	height: number,
}

local SkyLayout = {}
SkyLayout.__index = SkyLayout

export type SkyLayout = typeof(setmetatable(
	{} :: { tuning: Tuning, _bounds: { [number]: Bounds }, _order: { number } },
	SkyLayout
))

local DEFAULT_LENGTH = 500
local LAUNCH_SETBACK = 120

function SkyLayout.new(tuning: Tuning, tiers: { { id: number, length: number? } }): SkyLayout
	local bounds, order = {}, {}
	local cursor = tuning.launchX

	for index, tier in tiers do
		local length = tier.length or DEFAULT_LENGTH
		bounds[tier.id] = {
			startX = cursor,
			endX = cursor + length,
			length = length,
			altitude = tuning.baseAltitude + tuning.altitudeStep * (index - 1),
			width = tuning.corridorWidth,
			height = tuning.corridorHeight,
		}
		table.insert(order, tier.id)
		cursor += length
	end

	return setmetatable({ tuning = tuning, _bounds = bounds, _order = order }, SkyLayout)
end

function SkyLayout.boundsOf(self: SkyLayout, tierId: number): Bounds?
	return self._bounds[tierId]
end

function SkyLayout.totalLength(self: SkyLayout): number
	local total = 0
	for _, tierId in self._order do
		total += self._bounds[tierId].length
	end
	return total
end

--[[ Where the dragon takes off, just short of the first barrier. ]]
function SkyLayout.launchPoint(self: SkyLayout): Point
	local first = self._bounds[self._order[1]]
	return {
		x = first.startX - LAUNCH_SETBACK,
		y = first.altitude,
		z = 0,
	}
end

--[[ The wind barrier: dead centre of the fast line, impossible to miss. ]]
function SkyLayout.gateOf(self: SkyLayout, tierId: number): Point?
	local bounds = self._bounds[tierId]
	if not bounds then
		return nil
	end
	return { x = bounds.startX, y = bounds.altitude, z = 0 }
end

--[[
	The Altar: deliberately off the fast line.

	Banking has to cost a detour, otherwise the player cashes out by accident instead
	of choosing to. The side alternates so the detour never becomes muscle memory.
]]
function SkyLayout.altarOf(self: SkyLayout, tierId: number): Point?
	local bounds = self._bounds[tierId]
	if not bounds then
		return nil
	end

	local side = if tierId % 2 == 0 then 1 else -1
	return {
		x = bounds.startX + bounds.length * 0.75,
		y = bounds.altitude,
		z = side * self.tuning.altarOffset,
	}
end

function SkyLayout.tierAt(self: SkyLayout, x: number): number?
	if typeof(x) ~= "number" or x ~= x or x < self.tuning.launchX then
		return nil
	end

	for _, tierId in self._order do
		if x < self._bounds[tierId].endX then
			return tierId
		end
	end

	return self._order[#self._order]
end

--[[ The ring line — the readable ideal trajectory, woven so it is not a straight tunnel. ]]
function SkyLayout.ringPositions(self: SkyLayout, tierId: number): { Point }
	local bounds = self._bounds[tierId]
	if not bounds then
		return {}
	end

	local positions = {}
	local count = math.floor(bounds.length / self.tuning.ringSpacing)

	for index = 1, count do
		local x = bounds.startX + index * self.tuning.ringSpacing
		if x < bounds.endX then
			table.insert(positions, {
				x = x,
				y = bounds.altitude,
				z = math.sin(index * 0.7) * self.tuning.ringWeave,
			})
		end
	end

	return positions
end

return SkyLayout
