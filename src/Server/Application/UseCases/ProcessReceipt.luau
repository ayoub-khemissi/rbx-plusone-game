--!strict
--[[
	ProcessReceipt — traitement d'un achat Robux (produit developpeur).

	Point le plus sensible du jeu : Roblox REJOUE un recu tant qu'il n'a pas ete
	confirme, et l'argent est deja debite. Les regles appliquees ici :

	  - session absente  -> on refuse de confirmer (le profil n'est pas charge, on
	    ne peut pas crediter) ; Roblox retentera, y compris a la prochaine session ;
	  - recu deja traite -> on ne credite pas deux fois, mais on reconfirme ;
	  - sauvegarde KO    -> on refuse de confirmer : mieux vaut un rejeu qu'un achat
	    credite en memoire puis perdu au redemarrage du serveur.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local PurchaseLedger = require(Shared.Domain.Monetization.PurchaseLedger)

local ProcessReceipt = {}
ProcessReceipt.__index = ProcessReceipt

function ProcessReceipt.new(dependencies)
	return setmetatable(table.clone(dependencies), ProcessReceipt)
end

--[[ Un boost de serveur profite a tous les joueurs presents : c'est ce qui en fait
	un achat social, tres visible, et donc tres vendeur. ]]
function ProcessReceipt._applyServerBoost(self, buyer, boost, now)
	self.sessions:forEach(function(session)
		self.boosts:grant(session.profile, boost.id, boost.duration, now)
		if session.player then
			self.publisher:publish(session.player, self.snapshots:build(session))
			self.notifier:notify(
				session.player,
				`🎉 {buyer.Name} offre une fete du serveur a tout le monde !`,
				"success"
			)
		end
	end)
end

function ProcessReceipt.run(self, receiptInfo)
	local session = self.sessions:get(receiptInfo.PlayerId)
	if not session then
		return Result.err("NO_SESSION", "Profil non charge : achat a rejouer")
	end

	local product = self.products:byProductId(receiptInfo.ProductId)
	if not product then
		return Result.err("UNKNOWN_PRODUCT", `Produit inconnu : {tostring(receiptInfo.ProductId)}`)
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
			save = false, -- la sauvegarde est faite ci-dessous, et conditionne la confirmation
		})

		if product.grant.serverBoost and session.player then
			self:_applyServerBoost(session.player, product.grant.serverBoost, now)
		end

		if self.offers then
			self.offers:markPurchasedByProduct(session.profile, product.id)
		end
	end

	local saved = self.save:run(session.userId)
	if not saved.ok then
		-- On ne confirme pas : Roblox rejouera le recu et le registre evitera le double credit.
		return Result.err("SAVE_FAILED", "Sauvegarde impossible : achat a rejouer")
	end

	return Result.ok({ duplicate = duplicate, product = product, summary = summary })
end

return ProcessReceipt
