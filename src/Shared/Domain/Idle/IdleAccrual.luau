--!strict
--[[
	IdleAccrual — passive income from the idle zone of the Hub.

	Why an idle zone at all: a player who leaves the game open keeps the server
	populated, and concurrent players weigh heavily in Roblox recommendations. Three
	guardrails stop it from replacing the game:

	  1. it pays Coins only, never Speed — the leaderboard stays for those who run;
	  2. it ignores every multiplier, so its value melts as the player progresses;
	  3. a per-session cap makes endless farming pointless.

	The counter lives in the session and never in the save: reconnecting does not
	reset the cap of a session, and leaving the game running overnight does not create
	unlimited income.
]]

export type Tuning = {
	coinsPerMinute: number,
	payoutInterval: number,
	sessionCapSeconds: number,
}

export type State = {
	pendingSeconds: number,
	creditedSeconds: number,
}

export type Outcome = {
	payouts: number,
	coins: number,
	capped: boolean,
}

local IdleAccrual = {}
IdleAccrual.__index = IdleAccrual

export type IdleAccrual = typeof(setmetatable({} :: Tuning, IdleAccrual))

function IdleAccrual.new(tuning: Tuning): IdleAccrual
	return setmetatable({
		coinsPerMinute = tuning.coinsPerMinute,
		payoutInterval = tuning.payoutInterval,
		sessionCapSeconds = tuning.sessionCapSeconds,
	}, IdleAccrual)
end

function IdleAccrual.newState(): State
	return { pendingSeconds = 0, creditedSeconds = 0 }
end

function IdleAccrual.remainingFor(self: IdleAccrual, state: State): number
	return math.max(self.sessionCapSeconds - state.creditedSeconds, 0)
end

--[[ The player left the zone: partial time is lost, the cap counter is kept. ]]
function IdleAccrual.reset(_self: IdleAccrual, state: State)
	state.pendingSeconds = 0
end

function IdleAccrual.accumulate(self: IdleAccrual, state: State, deltaTime: number): Outcome
	local empty: Outcome = { payouts = 0, coins = 0, capped = false }

	if typeof(deltaTime) ~= "number" or deltaTime ~= deltaTime or deltaTime <= 0 then
		return empty
	end

	local remaining = self:remainingFor(state)
	if remaining <= 0 then
		return { payouts = 0, coins = 0, capped = true }
	end

	state.pendingSeconds += math.min(deltaTime, remaining)

	local payouts = math.floor(state.pendingSeconds / self.payoutInterval)
	if payouts <= 0 then
		return empty
	end

	local creditedSeconds = payouts * self.payoutInterval
	state.pendingSeconds -= creditedSeconds
	state.creditedSeconds += creditedSeconds

	return {
		payouts = payouts,
		coins = self.coinsPerMinute * (creditedSeconds / 60),
		capped = self:remainingFor(state) <= 0,
	}
end

return IdleAccrual
