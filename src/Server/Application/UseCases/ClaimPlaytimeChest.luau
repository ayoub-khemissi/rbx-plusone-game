--!strict
--[[ ClaimPlaytimeChest — coffre offert toutes les X minutes passees en jeu. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local ClaimPlaytimeChest = {}
ClaimPlaytimeChest.__index = ClaimPlaytimeChest

function ClaimPlaytimeChest.new(dependencies)
	return setmetatable(table.clone(dependencies), ClaimPlaytimeChest)
end

function ClaimPlaytimeChest.status(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end
	return Result.ok(self.chest:statusFor(session.profile, self.chestKey, self.clock.now()))
end

function ClaimPlaytimeChest.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	local claim = self.chest:claim(session.profile, self.chestKey, self.clock.now())
	if not claim.ok then
		return claim
	end

	local summary = self.rewards:award(session, claim.value.grant, {
		title = claim.value.label or "Coffre",
	})

	return Result.ok({ summary = summary })
end

return ClaimPlaytimeChest
