--!strict
--[[ SavePlayerProfile — ecrit le profil d'une session dans le depot. ]]

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
		return Result.err("NO_SESSION", "Aucune session ouverte pour ce joueur")
	end
	if not session.savable then
		return Result.err("READ_ONLY", "Session en lecture seule : sauvegarde ignoree")
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
