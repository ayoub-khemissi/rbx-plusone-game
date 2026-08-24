--!strict
--[[
	DragonCatalog — the species a player can hatch, and what owning them grants.

	The collection is the long game: a player comes back to complete a book, not to
	watch a counter grow. Every dragon therefore carries a small permanent bonus, so
	collecting is never purely cosmetic.

	Like the rarity roll, picking a species takes its randomness as an argument: the
	domain stays pure and a drop can be reproduced in a test.
]]

export type Bonus = {
	gold: number?,
	speed: number?,
	agility: number?,
	hatch: number?,
}

export type Species = {
	id: string,
	name: string,
	rarity: string,
	bonus: Bonus,
	description: string?,
}

export type Bonuses = {
	gold: number,
	speed: number,
	agility: number,
	hatch: number,
}

export type Completion = {
	owned: number,
	total: number,
	byRarity: { [string]: { owned: number, total: number } },
}

local DragonCatalog = {}
DragonCatalog.__index = DragonCatalog

export type DragonCatalog = typeof(setmetatable(
	{} :: { _order: { string }, _byId: { [string]: Species }, _byRarity: { [string]: { Species } } },
	DragonCatalog
))

local BONUS_KEYS = { "gold", "speed", "agility", "hatch" }

function DragonCatalog.new(species: { Species }): DragonCatalog
	local order, byId, byRarity = {}, {}, {}

	for _, entry in species do
		if byId[entry.id] then
			error(`Duplicate dragon in catalog: {entry.id}`, 2)
		end
		byId[entry.id] = entry
		table.insert(order, entry.id)

		byRarity[entry.rarity] = byRarity[entry.rarity] or {}
		table.insert(byRarity[entry.rarity], entry)
	end

	return setmetatable({ _order = order, _byId = byId, _byRarity = byRarity }, DragonCatalog)
end

function DragonCatalog.get(self: DragonCatalog, id: string): Species?
	return self._byId[id]
end

function DragonCatalog.all(self: DragonCatalog): { string }
	return table.clone(self._order)
end

function DragonCatalog.byRarity(self: DragonCatalog, rarity: string): { Species }
	return self._byRarity[rarity] or {}
end

--[[ Picks a species inside a rarity from a value in [0, 1]. ]]
function DragonCatalog.roll(self: DragonCatalog, rarity: string, value: number): Species?
	local pool = self:byRarity(rarity)
	if #pool == 0 then
		return nil
	end

	local index = math.floor(math.clamp(value, 0, 1) * #pool) + 1
	return pool[math.min(index, #pool)]
end

--[[ Sum of every bonus granted by the dragons the player owns. ]]
function DragonCatalog.bonusesFor(self: DragonCatalog, profile: any): Bonuses
	local bonuses: Bonuses = { gold = 0, speed = 0, agility = 0, hatch = 0 }

	for id, count in profile.dragons do
		local species = self._byId[id]
		if species and count > 0 then
			for _, key in BONUS_KEYS do
				bonuses[key] += (species.bonus[key] or 0) * count
			end
		end
	end

	return bonuses
end

--[[ Collection progress, per rarity — the screen players chase. ]]
function DragonCatalog.completion(self: DragonCatalog, profile: any): Completion
	local completion: Completion = { owned = 0, total = #self._order, byRarity = {} }

	for rarity, pool in self._byRarity do
		completion.byRarity[rarity] = { owned = 0, total = #pool }
	end

	for _, id in self._order do
		local species = self._byId[id]
		if (profile.dragons[id] or 0) > 0 then
			completion.owned += 1
			completion.byRarity[species.rarity].owned += 1
		end
	end

	return completion
end

return DragonCatalog
