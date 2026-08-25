--!strict
--[[ PerformPrestige — the long loop: reset everything, come back stronger. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local PerformPrestige = {}
PerformPrestige.__index = PerformPrestige

function PerformPrestige.new(dependencies)
	return setmetatable(table.clone(dependencies), PerformPrestige)
end

function PerformPrestige.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local result = self.prestigePolicy:apply(session.profile)
	if not result.ok then
		self.notifier:cue(player, "refused")
		return result
	end

	-- The run in progress is dropped. The CHARACTER does not move — a rebirth is taken standing on a pad the player
	-- chose to step on, and snatching them to the hub for it takes the moment away
	-- from them. The Speed is gone either way, so every gate ahead is shut again.
	self.sessions:resetRun(session)

	-- Played on the server, so the room sees it. A rebirth is the one moment in the
	-- game whose whole point is being watched — which is another reason not to
	-- teleport: the confetti should fall where the people are.
	self.effects:celebrate(player, "rebirth")
	self.publisher:publish(player, self.snapshots:build(session))
	self.save:run(session.userId)
	return result
end

return PerformPrestige
