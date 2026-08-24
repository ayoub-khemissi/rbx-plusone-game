--!strict
--[[
	ReleasePlayer — saves then frees the session when a player leaves.

	A flight in progress is simply dropped: the pouch was never theirs, and letting
	it survive would turn disconnecting into a way to protect it.
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

	self.sessions:endFlight(session)

	local saved = self.save:run(userId)
	self.sessions:close(userId)

	if not saved.ok then
		return saved
	end
	return Result.ok({ userId = userId })
end

return ReleasePlayer
