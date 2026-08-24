--!strict
--[[
	AccrueIdleReward — passive income while standing on the idle pad of the Hub.

	Called by the same sampling loop as movement: the server sees where the character
	is, the client declares nothing.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local AccrueIdleReward = {}
AccrueIdleReward.__index = AccrueIdleReward

function AccrueIdleReward.new(dependencies)
	return setmetatable(table.clone(dependencies), AccrueIdleReward)
end

function AccrueIdleReward.run(self, player, onPad: boolean, deltaTime: number)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	if not onPad then
		if session.idleActive then
			self.idle:reset(session.idle)
			session.idleActive = false
			self.publisher:publish(player, self.snapshots:build(session))
		end
		return Result.ok({ active = false })
	end

	if not session.idleActive then
		session.idleActive = true
		self.publisher:publish(player, self.snapshots:build(session))
		self.notifier:notify(player, "Idle zone: you earn Coins without moving.", "info")
	end

	local outcome = self.idle:accumulate(session.idle, deltaTime)
	if outcome.coins > 0 then
		-- Flat reward, no multiplier: standing still must never be the best way to play.
		self.rewards:award(session, { coins = outcome.coins }, {
			title = "Idle zone",
			save = false, -- the autosave takes care of it
		})
	end

	return Result.ok({ active = true, coins = outcome.coins, capped = outcome.capped })
end

return AccrueIdleReward
