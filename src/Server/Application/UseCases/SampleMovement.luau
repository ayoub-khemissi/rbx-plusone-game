--!strict
--[[
	SampleMovement — the heart of the loop, called by the server sampling loop.

	The server measures the character itself: the client never declares a gain, so it
	cannot invent one. Both speed and coins land straight in the profile — falling
	into a hole costs time, never progress.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local SampleMovement = {}
SampleMovement.__index = SampleMovement

function SampleMovement.new(dependencies)
	return setmetatable(table.clone(dependencies), SampleMovement)
end

function SampleMovement.run(self, player, sample)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local position = sample.position
	local at = sample.at

	if not session.lastPosition or not session.lastSampleAt then
		session.lastPosition = position
		session.lastSampleAt = at
		return Result.ok({ warmup = true, steps = 0, speedGained = 0, coinsGained = 0 })
	end

	local distance = self.progression:distanceBetween(session.lastPosition, position)
	local deltaTime = at - session.lastSampleAt
	session.lastPosition = position
	session.lastSampleAt = at

	local profile = session.profile
	local outcome = self.progression:advance(profile, {
		distance = distance,
		deltaTime = deltaTime,
		currentWalkSpeed = sample.walkSpeed,
		stage = self.ladder:reachedBy(session.profile.speed),
		passes = session.passes,
		boosts = self.boosts:multipliersFor(profile, self.clock.now()),
	})

	self.actuator:apply(player, outcome.movement)
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok(outcome)
end

return SampleMovement
