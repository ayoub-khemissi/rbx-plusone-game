--!strict
--[[
	RequestDash — the client asks for a dash, the server decides.

	The cooldown is held server side for the same reason as the jump budget: a client
	that counted its own cooldown would simply not wait.

	The clock used is the MONOTONIC one — a cooldown measures a duration, and must
	not care what the wall clock does.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local RequestDash = {}
RequestDash.__index = RequestDash

function RequestDash.new(dependencies)
	return setmetatable(table.clone(dependencies), RequestDash)
end

function RequestDash.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local profile = session.profile
	local bonuses = self.multipliers:compute(profile, {
		stage = self.ladder:reachedBy(session.profile.speed),
		passes = session.passes,
		boosts = self.boosts:multipliersFor(profile, self.clock.now()),
	})

	if not self.dashPolicy:isUnlocked(bonuses) then
		return Result.err("NO_DASH", "Dash not unlocked yet")
	end

	-- Scaled against the speed the character actually runs at right now, which is
	-- what keeps a dash worth using once the game is fast.
	local movement = self.progression:movementFor(profile, bonuses)
	local level = self.dashPolicy:powerLevelFor(bonuses)

	local now = self.clock.monotonic()
	local power = self.dashPolicy:tryConsume(session.dash, level, movement.walkSpeed, now)
	if power <= 0 then
		return Result.err("DASH_COOLDOWN", "Dash still recharging", {
			remaining = self.dashPolicy:remainingCooldown(session.dash, now),
		})
	end

	self.publisher:publish(player, self.snapshots:build(session))
	return Result.ok({ power = power, level = level })
end

return RequestDash
