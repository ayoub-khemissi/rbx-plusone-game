--!strict
--[[
	ProductCatalog — developer products, the repeatable Robux purchases.

	`productId = 0` means "not created on the Roblox site yet": the product is then
	invisible and unbuyable. That is what lets the game ship before any id exists,
	and the ids be filled in later without touching a line of code.
]]

export type Definition = {
	id: string,
	productId: number,
	name: string,
	description: string?,
	icon: string?,
	image: string?,
	robux: number?,
	badge: string?, -- "popular", "best value"...
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
			error(`Duplicate product in the catalogue: {definition.id}`, 2)
		end
		byId[definition.id] = definition
		table.insert(order, definition.id)

		if definition.productId ~= 0 then
			if byProductId[definition.productId] then
				error(`Two products share the productId {definition.productId}`, 2)
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

--[[ The products actually offerable: the ones whose Roblox id is filled in. ]]
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
