--!strict
--[[
	RequestJump — the client asks for an air jump, the server decides.

	The client cannot simply jump twice on its own: the number of jumps is bought,
	and letting the client count them would make the upgrade free. It asks, the
	server spends one from the budget and hands back the power to apply.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local RequestJump = {}
RequestJump.__index = RequestJump

function RequestJump.new(dependencies)
	return setmetatable(table.clone(dependencies), RequestJump)
end

function RequestJump.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local profile = session.profile
	local bonuses = self.multipliers:compute(profile, {
		stage = self.ladder:get(session.stageId),
		passes = session.passes,
		boosts = self.boosts:multipliersFor(profile, self.clock.now()),
	})

	local capacity = self.jumpBudget:capacityFor(bonuses)
	if not self.jumpBudget:tryConsume(session.jumps, capacity) then
		return Result.err("NO_JUMP_LEFT", "No air jump left", {
			jumpLevel = self.jumpBudget:levelFor(bonuses),
		})
	end

	local movement = self.progression:movementFor(profile, bonuses)
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok({
		jumpPower = movement.jumpPower,
		jumpsLeft = self.jumpBudget:remaining(session.jumps, capacity),
	})
end

return RequestJump
