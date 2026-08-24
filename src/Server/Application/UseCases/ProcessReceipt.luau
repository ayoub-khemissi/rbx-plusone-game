--!strict
--[[
	ProcessReceipt — handling a Robux purchase (developer product).

	The most sensitive path in the game: Roblox REPLAYS a receipt until it is
	confirmed, and the player has already been charged. The rules applied here:

	  - no session -> refuse to confirm; the profile is not loaded, so nothing can be
	    credited. Roblox will retry, including on the player's next session;
	  - receipt already processed -> do not credit twice, but confirm again;
	  - save failed -> refuse to confirm. A replay is better than a purchase credited
	    in memory and lost when the server restarts.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local PurchaseLedger = require(Shared.Domain.Monetization.PurchaseLedger)

local ProcessReceipt = {}
ProcessReceipt.__index = ProcessReceipt

function ProcessReceipt.new(dependencies)
	return setmetatable(table.clone(dependencies), ProcessReceipt)
end

--[[ A server boost reaches everyone: that is what makes it a social purchase. ]]
function ProcessReceipt._applyServerBoost(self, buyer, boost, now)
	self.sessions:forEach(function(session)
		self.boosts:grant(session.profile, boost.id, boost.duration, now)
		if session.player then
			self.publisher:publish(session.player, self.snapshots:build(session))
			self.notifier:notify(
				session.player,
				`🎉 {buyer.Name} started a Sky Festival for everyone!`,
				"success"
			)
		end
	end)
end

function ProcessReceipt.run(self, receiptInfo)
	local session = self.sessions:get(receiptInfo.PlayerId)
	if not session then
		return Result.err("NO_SESSION", "Profile not loaded: purchase must be replayed")
	end

	local product = self.products:byProductId(receiptInfo.ProductId)
	if not product then
		return Result.err("UNKNOWN_PRODUCT", `Unknown product: {tostring(receiptInfo.ProductId)}`)
	end

	local purchaseId = tostring(receiptInfo.PurchaseId)
	local now = self.clock.now()
	local duplicate = PurchaseLedger.hasProcessed(session.profile, purchaseId)
	local summary = {}

	if not duplicate then
		PurchaseLedger.record(session.profile, {
			purchaseId = purchaseId,
			productId = product.id,
			robux = receiptInfo.CurrencySpent,
			at = now,
		})

		summary = self.rewards:award(session, product.grant, {
			title = product.name,
			save = false, -- saved below; the save gates the confirmation
		})

		if product.grant.serverBoost and session.player then
			self:_applyServerBoost(session.player, product.grant.serverBoost, now)
		end

		self.offers:markPurchasedByProduct(session.profile, product.id)
	end

	local saved = self.save:run(session.userId)
	if not saved.ok then
		-- Not confirmed: Roblox replays, and the ledger prevents a double credit.
		return Result.err("SAVE_FAILED", "Save failed: purchase must be replayed")
	end

	return Result.ok({ duplicate = duplicate, product = product, summary = summary })
end

return ProcessReceipt
