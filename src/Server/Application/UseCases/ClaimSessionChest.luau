--!strict
--[[ ClaimSessionChest — a chest every few minutes of play, the reason to stay. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local ClaimSessionChest = {}
ClaimSessionChest.__index = ClaimSessionChest

function ClaimSessionChest.new(dependencies)
	return setmetatable(table.clone(dependencies), ClaimSessionChest)
end

function ClaimSessionChest.status(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	return Result.ok(self.chest:statusFor(session.profile, self.chestKey, self.clock.now()))
end

function ClaimSessionChest.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local claim = self.chest:claim(session.profile, self.chestKey, self.clock.now())
	if not claim.ok then
		return claim
	end

	local summary = self.rewards:award(session, claim.value.grant, { title = claim.value.label or "Chest" })
	return Result.ok({ summary = summary })
end

return ClaimSessionChest
