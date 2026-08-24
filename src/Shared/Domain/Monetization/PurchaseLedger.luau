--!strict
--[[
	PurchaseLedger — the record of Robux purchases already handled.

	This is what makes the monetization RELIABLE. Roblox may replay the same receipt
	after a server restart or a network timeout. Without a ledger the player is
	credited twice; answering `NotProcessedYet` by mistake makes Roblox replay
	forever. So the purchase id is recorded BEFORE the receipt is confirmed, and the
	same id is never credited twice.

	The history is bounded: a DataStore save must not grow without end.
]]

export type Record = {
	purchaseId: string,
	productId: string,
	robux: number?,
	at: number?,
}

local PurchaseLedger = {}

PurchaseLedger.MAX_HISTORY = 100

function PurchaseLedger.hasProcessed(profile: any, purchaseId: string): boolean
	return profile.purchases.ids[purchaseId] == true
end

--[[ Records a purchase. Returns false if it had already been handled. ]]
function PurchaseLedger.record(profile: any, record: Record): boolean
	if typeof(record.purchaseId) ~= "string" or PurchaseLedger.hasProcessed(profile, record.purchaseId) then
		return false
	end

	local purchases = profile.purchases
	purchases.ids[record.purchaseId] = true
	table.insert(purchases.order, record.purchaseId)
	purchases.count += 1
	purchases.spentRobux += math.max(record.robux or 0, 0)

	while #purchases.order > PurchaseLedger.MAX_HISTORY do
		local oldest = table.remove(purchases.order, 1)
		if oldest then
			purchases.ids[oldest] = nil
		end
	end

	return true
end

return PurchaseLedger
