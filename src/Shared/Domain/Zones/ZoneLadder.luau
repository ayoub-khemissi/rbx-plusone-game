--!strict
--[[
	ZoneLadder — l'echelle de zones : seuil d'entree et multiplicateurs de gains.

	L'echelle doit etre strictement croissante en vitesse requise ; la construction
	echoue sinon, pour qu'une erreur d'equilibrage soit detectee au demarrage et non
	en production.
]]

export type Zone = {
	id: number,
	name: string?,
	requiredSpeed: number,
	stepMultiplier: number,
	bananaMultiplier: number,
	length: number?,
	color: { number }?,
}

local ZoneLadder = {}
ZoneLadder.__index = ZoneLadder

export type ZoneLadder = typeof(setmetatable(
	{} :: { _zones: { Zone }, _byId: { [number]: Zone }, _indexById: { [number]: number } },
	ZoneLadder
))

function ZoneLadder.new(zones: { Zone }): ZoneLadder
	local byId, indexById = {}, {}
	local previousRequirement = -math.huge

	for index, zone in zones do
		if zone.requiredSpeed <= previousRequirement then
			error(`Echelle de zones invalide : le seuil de la zone {zone.id} doit etre croissant`, 2)
		end
		previousRequirement = zone.requiredSpeed
		byId[zone.id] = zone
		indexById[zone.id] = index
	end

	return setmetatable({ _zones = zones, _byId = byId, _indexById = indexById }, ZoneLadder)
end

function ZoneLadder.count(self: ZoneLadder): number
	return #self._zones
end

function ZoneLadder.all(self: ZoneLadder): { Zone }
	return self._zones
end

function ZoneLadder.get(self: ZoneLadder, zoneId: number): Zone?
	return self._byId[zoneId]
end

function ZoneLadder.requirementOf(self: ZoneLadder, zoneId: number): number?
	local zone = self._byId[zoneId]
	return zone and zone.requiredSpeed
end

function ZoneLadder.nextOf(self: ZoneLadder, zoneId: number): Zone?
	local index = self._indexById[zoneId]
	return if index then self._zones[index + 1] else nil
end

function ZoneLadder.isUnlocked(self: ZoneLadder, zoneId: number, speed: number): boolean
	local zone = self._byId[zoneId]
	return zone ~= nil and speed >= zone.requiredSpeed
end

--[[ Identifiant de la zone la plus avancee accessible a cette vitesse. ]]
function ZoneLadder.highestUnlocked(self: ZoneLadder, speed: number): number
	local highest = self._zones[1].id
	for _, zone in self._zones do
		if speed >= zone.requiredSpeed then
			highest = zone.id
		else
			break
		end
	end
	return highest
end

--[[ Avancement dans [0, 1] entre le seuil de cette zone et celui de la suivante. ]]
function ZoneLadder.progressToNext(self: ZoneLadder, zoneId: number, speed: number): number
	local zone = self._byId[zoneId]
	local nextZone = self:nextOf(zoneId)
	if not zone or not nextZone then
		return 1
	end

	local span = nextZone.requiredSpeed - zone.requiredSpeed
	if span <= 0 then
		return 1
	end
	return math.clamp((speed - zone.requiredSpeed) / span, 0, 1)
end

return ZoneLadder
