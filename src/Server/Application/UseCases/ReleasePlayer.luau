--!strict
--[[ ReleasePlayer — sauvegarde puis libere la session quand le joueur quitte. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local ReleasePlayer = {}
ReleasePlayer.__index = ReleasePlayer

function ReleasePlayer.new(dependencies)
	return setmetatable(table.clone(dependencies), ReleasePlayer)
end

function ReleasePlayer.run(self, player)
	local userId = player.UserId
	if not self.sessions:get(userId) then
		return Result.err("NO_SESSION", "Aucune session a liberer")
	end

	local saved = self.save:run(userId)
	self.sessions:close(userId)

	if not saved.ok then
		return saved
	end
	return Result.ok({ userId = userId })
end

return ReleasePlayer
