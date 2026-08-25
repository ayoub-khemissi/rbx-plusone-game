--!strict
--[[
	RunOnTreadmill — the character runs on the spot, and it counts.

	A treadmill pays as if the player were running at their own speed, multiplied.
	The multiplier is the thing being sold: a x500 belt is not five hundred times a
	better game, it is five hundred times less waiting, and that is a fair thing to
	charge for.

	NOTHING IS MEASURED HERE, and nothing needs to be. Ordinary running is checked
	against what is physically reachable because the client reports where it went;
	a treadmill is the server deciding how far the character ran, so there is no
	claim to verify.

	Time on a belt still counts as playtime, since that is what the free belt's
	entry condition is measured in.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local RunOnTreadmill = {}
RunOnTreadmill.__index = RunOnTreadmill

function RunOnTreadmill.new(dependencies)
	return setmetatable(table.clone(dependencies), RunOnTreadmill)
end

function RunOnTreadmill.run(self, player, multiplier: number, elapsed: number)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	if typeof(multiplier) ~= "number" or multiplier <= 0 or elapsed <= 0 then
		return Result.err("NOTHING_TO_CREDIT", "Nothing to credit")
	end

	local profile = session.profile
	local bonuses = self.multipliers:compute(profile, {
		stage = self.ladder:get(session.stageId),
		passes = session.passes,
		boosts = self.boosts:multipliersFor(profile, self.clock.now()),
	})

	-- The belt runs the character at its own speed, so the walk speed the player
	-- has earned still decides the pace. A treadmill accelerates, it does not
	-- replace what was earned.
	local movement = self.progression:movementFor(profile, bonuses)
	local distance = movement.walkSpeed * multiplier * elapsed
	local steps = distance / self.tuning.studsPerStep

	local gained = self.progression:credit(profile, steps, bonuses, elapsed)
	profile.totals.distance += distance

	return Result.ok({ steps = steps, speedGained = gained.speedGained, coinsGained = gained.coinsGained })
end

return RunOnTreadmill
