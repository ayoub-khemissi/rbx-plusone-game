--!strict
--[[ BuyUpgrade — spends banked gold on a permanent upgrade. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Purchase = require(Shared.Domain.Economy.Purchase)
local Format = require(Shared.Domain.Support.Format)

local MESSAGES = {
	UNKNOWN_UPGRADE = "That upgrade does not exist.",
	MAX_LEVEL = "Already at maximum level!",
	INSUFFICIENT_FUNDS = "You are %s gold short.",
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

	local result = Purchase.apply(self.catalog, session.profile, upgradeId)

	if not result.ok then
		local template = MESSAGES[result.code or ""] or "Purchase failed."
		local message = if result.code == "INSUFFICIENT_FUNDS"
			then string.format(template, Format.abbreviate(result.value and result.value.missing or 0))
			else template
		self.notifier:notify(player, message, "error")
		return result
	end

	self.publisher:publish(player, self.snapshots:build(session))
	self.notifier:notify(player, `{result.value.definition.name} level {result.value.level}!`, "success")

	return result
end

return BuyUpgrade
