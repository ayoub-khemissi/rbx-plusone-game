--!strict
--[[ RedeemCode — codes promo diffuses sur les reseaux (levier d'acquisition). ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local RedeemCode = {}
RedeemCode.__index = RedeemCode

function RedeemCode.new(dependencies)
	return setmetatable(table.clone(dependencies), RedeemCode)
end

function RedeemCode.run(self, player, rawCode)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	local redemption = self.codes:redeem(session.profile, rawCode, self.clock.now())
	if not redemption.ok then
		self.notifier:notify(player, redemption.message or "Code invalide.", "error")
		return redemption
	end

	local summary = self.rewards:award(session, redemption.value.grant, {
		title = `Code {redemption.value.code}`,
	})

	return Result.ok({ code = redemption.value.code, summary = summary })
end

return RedeemCode
