--!strict
--[[ CollectCoin — a coin picked up on the course. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local CollectCoin = {}
CollectCoin.__index = CollectCoin

function CollectCoin.new(dependencies)
	return setmetatable(table.clone(dependencies), CollectCoin)
end

function CollectCoin.run(self, player, value)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local profile = session.profile
	local granted = self.progression:collectCoin(profile, if typeof(value) == "number" then value else 0, {
		stage = self.ladder:get(session.stageId),
		passes = session.passes,
		boosts = self.boosts:multipliersFor(profile, self.clock.now()),
	})

	self.publisher:publish(player, self.snapshots:build(session))
	return Result.ok({ granted = granted })
end

return CollectCoin
