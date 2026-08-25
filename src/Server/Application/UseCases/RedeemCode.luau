--!strict
--[[ RedeemCode — promo codes shared on social media: reach without an ad budget. ]]

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
		return Result.err("NO_SESSION", "No open session")
	end

	local redemption = self.codes:redeem(session.profile, rawCode, self.clock.now())
	if not redemption.ok then
		self.notifier:cue(player, "refused")
		return redemption
	end

	local summary = self.rewards:award(session, redemption.value.grant, {
		title = `Code {redemption.value.code}`,
	})

	return Result.ok({ code = redemption.value.code, summary = summary })
end

return RedeemCode
