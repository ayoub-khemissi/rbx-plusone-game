--!strict
--[[
	PurchaseLedger — registre des achats Robux deja traites.

	C'est la piece qui rend la monetisation FIABLE : Roblox peut rejouer un meme
	`ProcessReceipt` (relance de serveur, timeout reseau). Sans registre, le joueur
	est credite deux fois ; si on renvoie `NotProcessedYet` par erreur, Roblox
	rejoue indefiniment. On enregistre donc l'identifiant d'achat AVANT de confirmer,
	et on ne credite jamais deux fois le meme.

	L'historique est borne : une sauvegarde DataStore ne doit pas grossir sans fin.
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

--[[ Enregistre un achat. Renvoie false s'il avait deja ete traite. ]]
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
