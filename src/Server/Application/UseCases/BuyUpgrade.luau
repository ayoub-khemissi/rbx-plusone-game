--!strict
--[[ BuyUpgrade — spends Coins on a permanent upgrade. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Purchase = require(Shared.Domain.Economy.Purchase)

local MESSAGES = {
	UNKNOWN_UPGRADE = "That upgrade does not exist.",
	MAX_LEVEL = "Already at maximum level!",
	INSUFFICIENT_FUNDS = "You are %s Coins short.",
	LOCKED = "Not unlocked yet.",
}

local BuyUpgrade = {}
BuyUpgrade.__index = BuyUpgrade

function BuyUpgrade.new(dependencies)
	return setmetatable(table.clone(dependencies), BuyUpgrade)
end

function BuyUpgrade.run(self, player, upgradeId)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	-- The id comes from the network: never trust its type.
	if typeof(upgradeId) ~= "string" then
		return Result.err("UNKNOWN_UPGRADE", MESSAGES.UNKNOWN_UPGRADE)
	end

	-- What a requirement may ask about beyond the profile itself.
	local result = Purchase.apply(self.catalog, session.profile, upgradeId, {
		level = self.levels:levelFor(session.profile.speed),
		passes = session.passes,
	})

	if not result.ok then
		-- The reason travels in the Result, which is what the shop reads to grey a
		-- row and explain itself in place. The player hears the refusal; they do not
		-- need to be told about it twice.
		self.notifier:cue(player, "refused")
		return result
	end

	self.publisher:publish(player, self.snapshots:build(session))

	return result
end

return BuyUpgrade
