--!strict
--[[
	FinishStage — the plate at the end of a course: bank it and go home.

	Touching it is a CHOICE, not the end of the course. A player may walk past and
	carry straight on into the next one; the plate is there for anyone who would
	rather take the reward and start again from the lobby.

	It pays whatever the course is worth and returns the player to the hub. The
	teleport is the point as much as the reward: without it a player would have to
	walk back through everything they just cleared.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local FinishStage = {}
FinishStage.__index = FinishStage

function FinishStage.new(dependencies)
	return setmetatable(table.clone(dependencies), FinishStage)
end

function FinishStage.run(self, player, stageId)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	-- The id comes off a part in the map, which anyone may have mistagged.
	if typeof(stageId) ~= "number" then
		return Result.err("BAD_STAGE", "That plate does not name a stage")
	end

	local world = self.worlds:forProfile(session.profile)
	local stage = world.ladder:get(stageId)
	if not stage then
		return Result.err("BAD_STAGE", `Unknown stage {stageId}`)
	end

	local reward = self.stageRewards:forStage(stage, world.ladder:nextOf(stageId))
	if not reward then
		return Result.err("BAD_STAGE", `Stage {stageId} pays nothing`)
	end

	--[[
		Deepest stage reached is recorded here rather than at a checkpoint: a
		checkpoint says the player walked in, the plate says they got through it.
	]]
	if stageId > (session.profile.highestStage or 0) then
		session.profile.highestStage = stageId
	end

	self.rewards:award(session, reward, {
		title = `{self.labels.stage.name} {stageId} complete`,
		cue = "reward",
	})

	-- Back to the lobby, and the sampler must not read the trip as distance run.
	session.lastPosition = nil
	session.lastSampleAt = nil
	session.checkpoint = nil
	self.body:sendTo(player, self.hubPoint)

	return Result.ok({ stageId = stageId, reward = reward })
end

return FinishStage
