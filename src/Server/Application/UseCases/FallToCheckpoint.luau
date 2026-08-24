--!strict
--[[
	FallToCheckpoint — a hole, a hazard, a bad jump.

	The whole promise of the game lives here: a fall costs TIME, never progress.
	Speed and Coins are untouched, the air jumps are refilled, and the player is put
	back on the last checkpoint they crossed.

	With no checkpoint yet, they go back to the Hub — which the map declares through
	its SpawnLocation.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local FallToCheckpoint = {}
FallToCheckpoint.__index = FallToCheckpoint

function FallToCheckpoint.new(dependencies)
	return setmetatable(table.clone(dependencies), FallToCheckpoint)
end

function FallToCheckpoint.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	session.profile.totals.falls += 1

	-- Landing back on solid ground refills the air jumps.
	self.jumpBudget:land(session.jumps)

	-- The teleport must not be credited as distance run.
	session.lastPosition = nil
	session.lastSampleAt = nil

	local destination = session.checkpoint or self.hubPoint
	self.teleporter:sendTo(player, destination)

	-- Silent message: a fall is loud enough on its own, and a toast on every miss
	-- would nag. The cue is the whole point of the call.
	self.notifier:notify(player, "", "info", "fall")
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok({ destination = destination, atCheckpoint = session.checkpoint ~= nil })
end

return FallToCheckpoint
