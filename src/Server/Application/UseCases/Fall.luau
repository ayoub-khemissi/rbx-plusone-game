--!strict
--[[
	Fall — a hole, a hazard, a bad jump.

	The whole promise of the game lives here: a fall costs TIME, never progress.
	Speed and Coins are untouched, and the player comes back at the Hub to run the
	course again.

	IT KILLS RATHER THAN TELEPORTS. Snatching a falling character back to solid
	ground reads as a glitch — the fall is cut off mid-air and the player is left
	wondering what just happened. A death is a punctuation mark they already know how
	to read, and the seconds before the new body are the cost.

	So this half only ends the run. Where the player comes back is decided by
	RespawnPlayer, because it has to be decided for EVERY new body — including the
	first one, and the one after a Roblox-side reset this server never saw.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local Fall = {}
Fall.__index = Fall

function Fall.new(dependencies)
	return setmetatable(table.clone(dependencies), Fall)
end

function Fall.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	session.profile.totals.falls += 1

	-- The plunge must not be credited as distance run.
	session.lastPosition = nil
	session.lastSampleAt = nil

	self.body:kill(player)

	-- A fall is loud enough on its own: it is heard, never written.
	self.notifier:cue(player, "fall")
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok({ destination = self.hubPoint })
end

return Fall
