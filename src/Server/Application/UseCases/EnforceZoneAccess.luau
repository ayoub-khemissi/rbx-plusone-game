--!strict
--[[
	EnforceZoneAccess — fait respecter les barrieres de vitesse.

	Les barrieres sont rendues traversables cote client (confort, zero latence), mais
	c'est le serveur qui tranche : un joueur qui entre dans une zone trop rapide pour
	lui est renvoye au debut de sa derniere zone accessible.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local EnforceZoneAccess = {}
EnforceZoneAccess.__index = EnforceZoneAccess

function EnforceZoneAccess.new(dependencies)
	return setmetatable(table.clone(dependencies), EnforceZoneAccess)
end

function EnforceZoneAccess.run(self, player, position)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	local zoneId = self.layout:zoneAt(position.x)
	if not zoneId then
		-- Le joueur est dans le hub : la zone de reference reste la premiere.
		session.zoneId = 1
		return Result.ok({ zoneId = nil })
	end

	if not self.ladder:isUnlocked(zoneId, session.profile.speed) then
		local fallbackZone = self.ladder:highestUnlocked(session.profile.speed)
		local zone = self.ladder:get(zoneId)
		local required = zone and zone.requiredSpeed or 0

		session.zoneId = fallbackZone
		self.teleporter:sendTo(player, self.layout:spawnOf(fallbackZone))
		self.notifier:notify(
			player,
			`Il te faut {math.floor(required)} de vitesse pour entrer dans {zone and zone.name or "cette zone"} !`,
			"warning"
		)

		return Result.err("ZONE_LOCKED", "Zone verrouillee", { zoneId = zoneId, required = required })
	end

	session.zoneId = zoneId
	local discovered = self.progression:noteZone(session.profile, zoneId)
	if discovered then
		self.publisher:publish(player, self.snapshots:build(session))
		local zone = self.ladder:get(zoneId)
		self.notifier:notify(player, `Nouvelle zone atteinte : {zone and zone.name or zoneId} !`, "success")
	end

	return Result.ok({ zoneId = zoneId, discovered = discovered })
end

return EnforceZoneAccess
