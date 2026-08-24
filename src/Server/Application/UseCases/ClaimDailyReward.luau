--!strict
--[[ ClaimDailyReward — daily streak reward, the reason to come back tomorrow. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local ClaimDailyReward = {}
ClaimDailyReward.__index = ClaimDailyReward

function ClaimDailyReward.new(dependencies)
	return setmetatable(table.clone(dependencies), ClaimDailyReward)
end

function ClaimDailyReward.status(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	return Result.ok(self.daily:statusFor(session.profile, self.clock.now()))
end

function ClaimDailyReward.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local claim = self.daily:claim(session.profile, self.clock.now())
	if not claim.ok then
		return claim
	end

	local summary = self.rewards:award(session, claim.value.grant, {
		title = `Day {claim.value.day} — streak of {claim.value.streak}`,
	})

	return Result.ok({ day = claim.value.day, streak = claim.value.streak, summary = summary })
end

return ClaimDailyReward
