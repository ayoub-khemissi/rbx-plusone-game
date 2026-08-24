--!strict
--[[ NoteLanded — the character touched the ground: refill the air jumps. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local NoteLanded = {}
NoteLanded.__index = NoteLanded

function NoteLanded.new(dependencies)
	return setmetatable(table.clone(dependencies), NoteLanded)
end

function NoteLanded.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	self.jumpBudget:land(session.jumps)
	return Result.ok({ landed = true })
end

return NoteLanded
