--!strict
--[[ BuyUpgrade — achat d'une amelioration avec les bananes du joueur. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Purchase = require(Shared.Domain.Economy.Purchase)
local Format = require(Shared.Domain.Support.Format)

local MESSAGES = {
	UNKNOWN_UPGRADE = "Cette amelioration n'existe pas.",
	MAX_LEVEL = "Niveau maximum deja atteint !",
	INSUFFICIENT_FUNDS = "Il te manque %s bananes.",
}

local BuyUpgrade = {}
BuyUpgrade.__index = BuyUpgrade

function BuyUpgrade.new(dependencies)
	return setmetatable(table.clone(dependencies), BuyUpgrade)
end

function BuyUpgrade.run(self, player, upgradeId)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end
	-- Le parametre vient du reseau : on ne fait aucune confiance a son type.
	if typeof(upgradeId) ~= "string" then
		return Result.err("UNKNOWN_UPGRADE", MESSAGES.UNKNOWN_UPGRADE)
	end

	local result = Purchase.apply(self.catalog, session.profile, upgradeId)

	if not result.ok then
		local template = MESSAGES[result.code or ""] or "Achat impossible."
		local message = if result.code == "INSUFFICIENT_FUNDS"
			then string.format(template, Format.abbreviate(result.value and result.value.missing or 0))
			else template
		self.notifier:notify(player, message, "error")
		return result
	end

	self.publisher:publish(player, self.snapshots:build(session))
	local definition = result.value.definition
	self.notifier:notify(player, `{definition.name} niveau {result.value.level} !`, "success")

	return result
end

return BuyUpgrade
