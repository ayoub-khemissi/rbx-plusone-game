--!strict
--[[
	CollectCoin — a Coin picked up on the course.

	The Coin is claimed against the player's OWN field before anything is paid. Two
	players running together do not compete for a pickup, and a client asking twice
	for the same one — which it will, the moment a Coin comes within reach and again
	on the next frame — is paid once.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local CoinField = require(Shared.Domain.Run.CoinField)
local Result = require(Shared.Domain.Support.Result)

local CollectCoin = {}
CollectCoin.__index = CollectCoin

function CollectCoin.new(dependencies)
	return setmetatable(table.clone(dependencies), CollectCoin)
end

--[[
	`coin` identifies the pickup. Anything comparable will do — the domain never
	looks at it — which is what keeps the use case testable without a map.
]]
function CollectCoin.run(self, player, value, coin)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	-- A duration, so the monotonic clock: a coin comes back thirty seconds after it
	-- was taken, whatever the wall clock does in between.
	if
		coin ~= nil
		and not CoinField.claim(session.coins, coin, self.clock.monotonic(), self.tuning.coinRespawn)
	then
		return Result.err("COIN_TAKEN", "Coin already collected")
	end

	local profile = session.profile
	local granted = self.progression:collectCoin(profile, if typeof(value) == "number" then value else 0, {
		stage = self.ladder:reachedBy(session.profile.speed),
		passes = session.passes,
		boosts = self.boosts:multipliersFor(profile, self.clock.now()),
	})

	self.publisher:publish(player, self.snapshots:build(session))
	return Result.ok({ granted = granted })
end

return CollectCoin
