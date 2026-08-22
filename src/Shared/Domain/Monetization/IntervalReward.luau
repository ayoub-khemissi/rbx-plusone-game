--!strict
--[[
	IntervalReward — recompense periodique (coffre toutes les X minutes de jeu).

	Levier de SESSION : donne une raison de rester connecte, ce qui augmente le temps
	de jeu moyen, la probabilite d'achat et le classement du jeu dans les
	recommandations Roblox.
]]

local Result = require(script.Parent.Parent.Support.Result)

type Result = Result.Result

export type Tuning = {
	interval: number,
	grant: { [string]: any },
	label: string?,
}

export type Status = {
	claimable: boolean,
	secondsRemaining: number,
	grant: { [string]: any },
}

local IntervalReward = {}
IntervalReward.__index = IntervalReward

export type IntervalReward = typeof(setmetatable({} :: Tuning, IntervalReward))

function IntervalReward.new(tuning: Tuning): IntervalReward
	return setmetatable({
		interval = tuning.interval,
		grant = tuning.grant,
		label = tuning.label,
	}, IntervalReward)
end

function IntervalReward.statusFor(self: IntervalReward, profile: any, key: string, now: number): Status
	local last = profile.timers[key] or 0
	local elapsed = now - last
	local claimable = elapsed >= self.interval

	return {
		claimable = claimable,
		secondsRemaining = if claimable then 0 else self.interval - elapsed,
		grant = self.grant,
	}
end

--[[ Repart le compteur (a la connexion, pour ne pas offrir un coffre immediat). ]]
function IntervalReward.touch(_self: IntervalReward, profile: any, key: string, now: number)
	profile.timers[key] = now
end

function IntervalReward.claim(self: IntervalReward, profile: any, key: string, now: number): Result
	local status = self:statusFor(profile, key, now)
	if not status.claimable then
		return Result.err("NOT_READY", "Le coffre n'est pas encore pret", {
			secondsRemaining = status.secondsRemaining,
		})
	end

	profile.timers[key] = now
	return Result.ok({ grant = self.grant, label = self.label })
end

return IntervalReward
