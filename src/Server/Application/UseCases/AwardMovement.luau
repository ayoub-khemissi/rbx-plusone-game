--!strict
--[[
	AwardMovement — coeur de la boucle "+1 a chaque pas".

	Appele periodiquement par l'ordonnanceur serveur avec la position REELLE du
	personnage. Le client n'envoie jamais de gain : il ne peut donc pas en inventer.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local AwardMovement = {}
AwardMovement.__index = AwardMovement

function AwardMovement.new(dependencies)
	return setmetatable(table.clone(dependencies), AwardMovement)
end

function AwardMovement.run(self, player, sample)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	local position = sample.position
	local at = sample.at

	-- Premier echantillon : on memorise la position de reference sans rien crediter.
	if not session.lastPosition or not session.lastSampleAt then
		session.lastPosition = position
		session.lastSampleAt = at
		return Result.ok({ warmup = true, steps = 0, speedGained = 0, bananasGained = 0 })
	end

	local distance = self.progression:distanceBetween(session.lastPosition, position)
	local deltaTime = at - session.lastSampleAt
	session.lastPosition = position
	session.lastSampleAt = at

	local zone = self.ladder:get(session.zoneId) or self.ladder:get(1)
	local outcome = self.progression:advance(session.profile, {
		distance = distance,
		deltaTime = deltaTime,
		currentWalkSpeed = sample.walkSpeed,
		zone = zone,
		passes = session.passes,
	})

	self.actuator:apply(player, outcome.movement)
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok(outcome)
end

return AwardMovement
