--!strict
--[[
	FallToCheckpoint — a hole, a hazard, a bad jump.

	The whole promise of the game lives here: a fall costs TIME, never progress.
	Speed and Coins are untouched, and the player comes back on the last checkpoint
	they crossed.

	IT KILLS RATHER THAN TELEPORTS. Snatching a falling character back to solid
	ground reads as a glitch — the fall is cut off mid-air and the player is left
	wondering what just happened. A death is a punctuation mark they already know how
	to read, and the seconds before the new body are the cost.

	So this half only ends the run. Where the player comes back is decided by
	SpawnAtCheckpoint, because it has to be decided for EVERY new body — including
	the first one, and the one after a Roblox-side reset this server never saw.
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

	-- The plunge must not be credited as distance run.
	session.lastPosition = nil
	session.lastSampleAt = nil

	self.body:kill(player)

	-- Silent message: a fall is loud enough on its own, and a toast on every miss
	-- would nag. The cue is the whole point of the call.
	self.notifier:notify(player, "", "info", "fall")
	self.publisher:publish(player, self.snapshots:build(session))

	local destination = session.checkpoint or self.hubPoint
	return Result.ok({ destination = destination, atCheckpoint = session.checkpoint ~= nil })
end

return FallToCheckpoint
