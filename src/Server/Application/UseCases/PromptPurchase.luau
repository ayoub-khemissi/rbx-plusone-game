--!strict
--[[
	PromptPurchase — ouvre la fenetre d'achat Roblox pour un produit ou un gamepass.

	Le client demande, le serveur decide : un identifiant non configure (0) ou
	inconnu ne declenche aucune fenetre.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local PromptPurchase = {}
PromptPurchase.__index = PromptPurchase

function PromptPurchase.new(dependencies)
	return setmetatable(table.clone(dependencies), PromptPurchase)
end

function PromptPurchase.run(self, player, kind, id)
	if typeof(id) ~= "string" then
		return Result.err("UNKNOWN_ITEM", "Identifiant invalide")
	end

	if kind == "product" then
		if not self.products:isConfigured(id) then
			return Result.err("NOT_CONFIGURED", "Produit indisponible")
		end
		local product = self.products:get(id)
		self.marketplace:promptProduct(player, product.productId)
		return Result.ok({ kind = kind, productId = product.productId })
	end

	if kind == "pass" then
		local pass = self.passes[id]
		if not pass or pass.assetId == 0 then
			return Result.err("NOT_CONFIGURED", "Gamepass indisponible")
		end
		self.marketplace:promptGamePass(player, pass.assetId)
		return Result.ok({ kind = kind, assetId = pass.assetId })
	end

	return Result.err("UNKNOWN_KIND", "Type d'achat inconnu")
end

return PromptPurchase
