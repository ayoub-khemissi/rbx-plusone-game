--!strict
--[[
	RewardSchedule — recompense quotidienne a serie (streak).

	Levier de RETENTION, donc de revenus : le joueur revient chaque jour pour ne pas
	casser sa serie, et plus il revient, plus il a de chances d'acheter. La serie
	repart a 1 apres une absence superieure a `graceWindow`.
]]

local Result = require(script.Parent.Parent.Support.Result)

type Result = Result.Result

export type Reward = {
	day: number,
	grant: { [string]: any },
	label: string?,
}

export type Tuning = {
	dayLength: number,
	graceWindow: number,
	rewards: { Reward },
}

export type Status = {
	claimable: boolean,
	day: number,
	streak: number,
	secondsRemaining: number,
	reward: Reward,
}

local RewardSchedule = {}
RewardSchedule.__index = RewardSchedule

export type RewardSchedule = typeof(setmetatable({} :: Tuning, RewardSchedule))

function RewardSchedule.new(tuning: Tuning): RewardSchedule
	return setmetatable({
		dayLength = tuning.dayLength,
		graceWindow = tuning.graceWindow,
		rewards = tuning.rewards,
	}, RewardSchedule)
end

--[[ Jour du cycle correspondant a une serie donnee (la serie boucle sur le cycle). ]]
function RewardSchedule.dayFor(self: RewardSchedule, streak: number): number
	local count = #self.rewards
	if count == 0 then
		return 1
	end
	return ((math.max(streak, 1) - 1) % count) + 1
end

function RewardSchedule.rewardFor(self: RewardSchedule, streak: number): Reward
	return self.rewards[self:dayFor(streak)]
end

function RewardSchedule.statusFor(self: RewardSchedule, profile: any, now: number): Status
	local daily = profile.daily
	local nextStreak = if daily.streak == 0
		then 1
		elseif now - daily.lastClaimAt <= self.graceWindow then daily.streak + 1
		else 1

	if daily.streak == 0 then
		return {
			claimable = true,
			day = self:dayFor(1),
			streak = daily.streak,
			secondsRemaining = 0,
			reward = self:rewardFor(1),
		}
	end

	local elapsed = now - daily.lastClaimAt
	local claimable = elapsed >= self.dayLength

	return {
		claimable = claimable,
		day = self:dayFor(nextStreak),
		streak = daily.streak,
		secondsRemaining = if claimable then 0 else self.dayLength - elapsed,
		reward = self:rewardFor(nextStreak),
	}
end

function RewardSchedule.claim(self: RewardSchedule, profile: any, now: number): Result
	local status = self:statusFor(profile, now)
	if not status.claimable then
		return Result.err("ALREADY_CLAIMED", "Recompense deja reclamee aujourd'hui", {
			secondsRemaining = status.secondsRemaining,
		})
	end

	local daily = profile.daily
	daily.streak = if daily.streak == 0
		then 1
		elseif now - daily.lastClaimAt <= self.graceWindow then daily.streak + 1
		else 1
	daily.lastClaimAt = now

	local reward = self:rewardFor(daily.streak)
	return Result.ok({
		day = self:dayFor(daily.streak),
		streak = daily.streak,
		grant = reward.grant,
		reward = reward,
	})
end

return RewardSchedule
