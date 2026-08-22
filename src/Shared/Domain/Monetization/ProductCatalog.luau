--!strict
--[[
	ProductCatalog — produits developpeur (achats consommables en Robux).

	`productId = 0` signifie "pas encore cree sur le site Roblox" : le produit est
	alors invisible et impossible a acheter, ce qui permet de livrer le jeu sans
	identifiants et de les renseigner plus tard sans toucher au code.
]]

export type Definition = {
	id: string,
	productId: number,
	name: string,
	description: string?,
	icon: string?,
	robux: number?,
	badge: string?, -- "populaire", "meilleure offre"...
	grant: { [string]: any },
}

local ProductCatalog = {}
ProductCatalog.__index = ProductCatalog

export type ProductCatalog = typeof(setmetatable(
	{} :: { _order: { string }, _byId: { [string]: Definition }, _byProductId: { [number]: Definition } },
	ProductCatalog
))

function ProductCatalog.new(definitions: { Definition }): ProductCatalog
	local order, byId, byProductId = {}, {}, {}

	for _, definition in definitions do
		if byId[definition.id] then
			error(`Produit duplique dans le catalogue : {definition.id}`, 2)
		end
		byId[definition.id] = definition
		table.insert(order, definition.id)

		if definition.productId ~= 0 then
			if byProductId[definition.productId] then
				error(`Deux produits partagent le productId {definition.productId}`, 2)
			end
			byProductId[definition.productId] = definition
		end
	end

	return setmetatable({ _order = order, _byId = byId, _byProductId = byProductId }, ProductCatalog)
end

function ProductCatalog.get(self: ProductCatalog, id: string): Definition?
	return self._byId[id]
end

function ProductCatalog.byProductId(self: ProductCatalog, productId: number): Definition?
	if typeof(productId) ~= "number" or productId == 0 then
		return nil
	end
	return self._byProductId[productId]
end

function ProductCatalog.isConfigured(self: ProductCatalog, id: string): boolean
	local definition = self._byId[id]
	return definition ~= nil and definition.productId ~= 0
end

--[[ Produits reellement proposables au joueur (identifiant Roblox renseigne). ]]
function ProductCatalog.sellable(self: ProductCatalog): { Definition }
	local sellable = {}
	for _, id in self._order do
		if self:isConfigured(id) then
			table.insert(sellable, self._byId[id])
		end
	end
	return sellable
end

return ProductCatalog
