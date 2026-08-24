--!strict
--[[ SavePlayerProfile — writes a session's profile to the store. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local SavePlayerProfile = {}
SavePlayerProfile.__index = SavePlayerProfile

function SavePlayerProfile.new(dependencies)
	return setmetatable(table.clone(dependencies), SavePlayerProfile)
end

function SavePlayerProfile.run(self, userId: number)
	local session = self.sessions:get(userId)
	if not session then
		return Result.err("NO_SESSION", "No open session for this player")
	end
	if not session.savable then
		return Result.err("READ_ONLY", "Read-only session: save skipped")
	end

	local written, err = pcall(function()
		return self.repository:save(userId, session.profile)
	end)

	if not written then
		return Result.err("SAVE_FAILED", tostring(err))
	end

	return Result.ok({ userId = userId })
end

return SavePlayerProfile
