--!strict
--[[
	TrackLayout — geometrie de la piste, exprimee en nombres purs.

	Aucun type Roblox (Vector3 / CFrame) n'apparait ici : les adaptateurs convertissent.
	C'est ce qui permet de tester la topologie du niveau hors de Studio.
]]

export type Tuning = {
	trackStartX: number,
	trackWidth: number,
	groundY: number,
	spawnInset: number,
}

export type Point = { x: number, y: number, z: number }
export type Bounds = { startX: number, endX: number, length: number, width: number }

local TrackLayout = {}
TrackLayout.__index = TrackLayout

export type TrackLayout = typeof(setmetatable(
	{} :: { tuning: Tuning, _bounds: { [number]: Bounds }, _order: { number } },
	TrackLayout
))

local DEFAULT_LENGTH = 420

function TrackLayout.new(tuning: Tuning, zones: { { id: number, length: number? } }): TrackLayout
	local bounds, order = {}, {}
	local cursor = tuning.trackStartX

	for _, zone in zones do
		local length = zone.length or DEFAULT_LENGTH
		bounds[zone.id] = {
			startX = cursor,
			endX = cursor + length,
			length = length,
			width = tuning.trackWidth,
		}
		table.insert(order, zone.id)
		cursor += length
	end

	return setmetatable({ tuning = tuning, _bounds = bounds, _order = order }, TrackLayout)
end

function TrackLayout.boundsOf(self: TrackLayout, zoneId: number): Bounds?
	return self._bounds[zoneId]
end

function TrackLayout.totalLength(self: TrackLayout): number
	local total = 0
	for _, zoneId in self._order do
		total += self._bounds[zoneId].length
	end
	return total
end

--[[ Point d'apparition d'une zone, juste apres sa barriere d'entree. ]]
function TrackLayout.spawnOf(self: TrackLayout, zoneId: number): Point?
	local bounds = self._bounds[zoneId]
	if not bounds then
		return nil
	end
	return {
		x = bounds.startX + self.tuning.spawnInset,
		y = self.tuning.groundY + 5,
		z = 0,
	}
end

function TrackLayout.gateOf(self: TrackLayout, zoneId: number): Point?
	local bounds = self._bounds[zoneId]
	if not bounds then
		return nil
	end
	return { x = bounds.startX, y = self.tuning.groundY, z = 0 }
end

--[[ Zone occupee par une abscisse, ou nil si le joueur est encore dans le hub. ]]
function TrackLayout.zoneAt(self: TrackLayout, x: number): number?
	if typeof(x) ~= "number" or x ~= x or x < self.tuning.trackStartX then
		return nil
	end

	for _, zoneId in self._order do
		if x < self._bounds[zoneId].endX then
			return zoneId
		end
	end

	return self._order[#self._order]
end

return TrackLayout
