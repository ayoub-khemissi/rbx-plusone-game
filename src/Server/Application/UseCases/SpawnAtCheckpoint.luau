--!strict
--[[
	SpawnAtCheckpoint — a new body arrives; put it where the run left off.

	EVERY new character comes through here, not just the ones a fall killed. A player
	can die in ways this server never decided — a hazard someone built, a reset from
	the Roblox menu, the first spawn of the session — and all of them owe the player
	the same thing: the checkpoint they had reached, or the Hub if they had reached
	none.

	Everything tied to the old body is dropped with it. The air jumps come back, the
	last sampled position is forgotten — it belonged to a character that no longer
	exists, and measuring from it would pay for the distance between two bodies — and
	the Coins go back on the course, so a fall costs the run rather than the money
	lying on it.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local CoinField = require(Shared.Domain.Run.CoinField)
local Result = require(Shared.Domain.Support.Result)

local SpawnAtCheckpoint = {}
SpawnAtCheckpoint.__index = SpawnAtCheckpoint

function SpawnAtCheckpoint.new(dependencies)
	return setmetatable(table.clone(dependencies), SpawnAtCheckpoint)
end

function SpawnAtCheckpoint.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	self.jumpBudget:land(session.jumps)
	CoinField.clear(session.coins)

	session.lastPosition = nil
	session.lastSampleAt = nil

	local destination = session.checkpoint or self.hubPoint
	self.body:sendTo(player, destination)
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok({ destination = destination, atCheckpoint = session.checkpoint ~= nil })
end

return SpawnAtCheckpoint
