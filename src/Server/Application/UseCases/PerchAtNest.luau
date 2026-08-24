--!strict
--[[
	PerchAtNest — staying at the Nest speeds incubation up.

	This is the idle mechanic of the game, and it is an honest one: eggs hatch on
	real time whether the player is here or not, so absence is never punished.
	Perching only makes it faster, which keeps servers populated — a number that
	weighs on Roblox recommendations — without paying anyone to stand still.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local PerchAtNest = {}
PerchAtNest.__index = PerchAtNest

function PerchAtNest.new(dependencies)
	return setmetatable(table.clone(dependencies), PerchAtNest)
end

function PerchAtNest.run(self, player, seconds)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	if session.flying or #session.profile.hatchery == 0 then
		return Result.ok({ perched = false })
	end

	local profile = session.profile
	local bonuses = self.multipliers:compute(profile, {
		passes = session.passes,
		dragons = self.dragons:bonusesFor(profile),
	})
	local rate = bonuses.hatch + (bonuses.flat.hatch or 0)

	self.clutch:perch(profile, math.max(seconds, 0) * rate)
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok({ perched = true, rate = rate })
end

return PerchAtNest
