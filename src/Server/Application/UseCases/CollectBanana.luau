--!strict
--[[ CollectBanana — ramassage d'une banane posee sur la piste. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local CollectBanana = {}
CollectBanana.__index = CollectBanana

function CollectBanana.new(dependencies)
	return setmetatable(table.clone(dependencies), CollectBanana)
end

function CollectBanana.run(self, player, amount)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	local requested = if typeof(amount) == "number" then amount else 0
	local granted = self.progression:grantBananas(session.profile, requested, {
		zone = self.ladder:get(session.zoneId),
		passes = session.passes,
	})

	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok({ granted = granted })
end

return CollectBanana
