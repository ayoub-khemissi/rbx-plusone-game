--!strict
--[[ TravelToZone — voyage rapide vers une zone deja debloquee (menu Zones). ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Format = require(Shared.Domain.Support.Format)

local TravelToZone = {}
TravelToZone.__index = TravelToZone

function TravelToZone.new(dependencies)
	return setmetatable(table.clone(dependencies), TravelToZone)
end

function TravelToZone.run(self, player, zoneId)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	-- Valeur venue du reseau : type et existence verifies avant toute action.
	local zone = if typeof(zoneId) == "number" then self.ladder:get(zoneId) else nil
	if not zone then
		return Result.err("UNKNOWN_ZONE", "Cette zone n'existe pas")
	end

	if not self.ladder:isUnlocked(zone.id, session.profile.speed) then
		self.notifier:notify(
			player,
			`{zone.name} demande {Format.abbreviate(zone.requiredSpeed)} de vitesse.`,
			"warning"
		)
		return Result.err("ZONE_LOCKED", "Zone verrouillee", { required = zone.requiredSpeed })
	end

	session.zoneId = zone.id
	session.lastPosition = nil
	session.lastSampleAt = nil

	self.teleporter:sendTo(player, self.layout:spawnOf(zone.id))
	self.progression:noteZone(session.profile, zone.id)
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok({ zoneId = zone.id })
end

return TravelToZone
