--!strict
--[[
	ReachCheckpoint — the player crossed a checkpoint of the map.

	This is also where the speed gate is enforced. The client makes a SpeedGate
	locally passable as soon as it thinks the player is fast enough — instant, no
	latency — but the server decides: a checkpoint belonging to a Stage the player
	cannot enter is refused.

	The checkpoint carries its Stage: the map declares it, the ladder prices it.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local ReachCheckpoint = {}
ReachCheckpoint.__index = ReachCheckpoint

function ReachCheckpoint.new(dependencies)
	return setmetatable(table.clone(dependencies), ReachCheckpoint)
end

local function samePlace(a, b): boolean
	return a ~= nil and b ~= nil and a.x == b.x and a.y == b.y and a.z == b.z
end

function ReachCheckpoint.run(self, player, checkpoint)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	-- Everything here comes from a hand built map: never trust its shape.
	if typeof(checkpoint) ~= "table" or typeof(checkpoint.stageId) ~= "number" then
		return Result.err("BAD_CHECKPOINT", "Checkpoint without a StageId")
	end
	if typeof(checkpoint.position) ~= "table" then
		return Result.err("BAD_CHECKPOINT", "Checkpoint without a position")
	end

	local stageId = math.floor(checkpoint.stageId)
	local stage = self.ladder:get(stageId)
	if not stage then
		return Result.err("BAD_CHECKPOINT", `Unknown stage {stageId}`)
	end

	if not self.ladder:isUnlocked(stageId, session.profile.speed) then
		self.notifier:cue(player, "refused")
		self.offers:trigger(session.profile, "gateBlocked", self.clock.now())
		return Result.err(
			"STAGE_LOCKED",
			"Stage locked",
			{ stageId = stageId, required = stage.requiredSpeed }
		)
	end

	if samePlace(session.checkpoint, checkpoint.position) then
		return Result.ok({ unchanged = true, stageId = session.stageId })
	end

	session.checkpoint = checkpoint.position
	session.stageId = stageId
	session.profile.totals.checkpoints += 1

	local discovered = self.progression:noteStage(session.profile, stageId)
	self.publisher:publish(player, self.snapshots:build(session))

	-- Crossing a checkpoint has to be NOTICED, which is not the same as read. A new
	-- stage and a checkpoint already crossed are two different sounds, and the
	-- player learns the difference once.
	self.notifier:cue(player, if discovered then "stageReached" else "checkpoint")

	return Result.ok({ stageId = stageId, discovered = discovered })
end

return ReachCheckpoint
