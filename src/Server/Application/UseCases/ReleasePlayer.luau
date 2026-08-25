--!strict
--[[
	ReleasePlayer — saves then frees the session when a player leaves.

	The run in progress is simply dropped: a position is not progress,
	and nothing about it deserves to survive a reconnection.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local ReleasePlayer = {}
ReleasePlayer.__index = ReleasePlayer

function ReleasePlayer.new(dependencies)
	return setmetatable(table.clone(dependencies), ReleasePlayer)
end

function ReleasePlayer.run(self, player)
	local userId = player.UserId
	local session = self.sessions:get(userId)
	if not session then
		return Result.err("NO_SESSION", "No session to release")
	end

	self.sessions:resetRun(session)

	local saved = self.save:run(userId)
	self.sessions:close(userId)

	if not saved.ok then
		return saved
	end
	return Result.ok({ userId = userId })
end

return ReleasePlayer
