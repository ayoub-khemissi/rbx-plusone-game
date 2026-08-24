--!strict
--[[
	RarityTable — weighted rarity rolls, capped by the tier that produced the egg.

	The roll takes its randomness as an argument (a value in [0, 1]) instead of calling
	a generator: the domain stays pure and every drop is reproducible in a test.

	The cap matters for the economy: a tier advertised as "rare max" must never drop an
	epic, however lucky the roll. Weights below the cap are renormalised so the odds
	stay coherent rather than silently favouring the lowest rarity.

	A floor does the opposite job: deep tiers promise a guaranteed rarity, and that
	promise has to hold on an unlucky roll too.
]]

export type Entry = {
	rarity: string,
	weight: number,
}

local RarityTable = {}
RarityTable.__index = RarityTable

export type RarityTable = typeof(setmetatable(
	{} :: { _order: { string }, _weights: { number }, _indexOf: { [string]: number } },
	RarityTable
))

function RarityTable.new(entries: { Entry }): RarityTable
	local order, weights, indexOf = {}, {}, {}

	for index, entry in entries do
		if indexOf[entry.rarity] then
			error(`Duplicate rarity in table: {entry.rarity}`, 2)
		end
		order[index] = entry.rarity
		weights[index] = math.max(entry.weight, 0)
		indexOf[entry.rarity] = index
	end

	return setmetatable({ _order = order, _weights = weights, _indexOf = indexOf }, RarityTable)
end

function RarityTable.order(self: RarityTable): { string }
	return table.clone(self._order)
end

function RarityTable.indexOf(self: RarityTable, rarity: string): number?
	return self._indexOf[rarity]
end

function RarityTable.roll(self: RarityTable, maxRarity: string?, value: number, minRarity: string?): string
	-- No cap given: the safest reading is "commonest only", never a jackpot by omission.
	local capIndex = 1
	if typeof(maxRarity) == "string" then
		capIndex = self._indexOf[maxRarity] or #self._order
	end

	local total = 0
	for index = 1, capIndex do
		total += self._weights[index]
	end
	if total <= 0 then
		return self._order[1]
	end

	-- A guaranteed rarity can never exceed the cap of its own tier.
	local floorIndex = 1
	if typeof(minRarity) == "string" then
		floorIndex = math.min(self._indexOf[minRarity] or 1, capIndex)
	end

	local threshold = math.clamp(value, 0, 1) * total
	local accumulated = 0

	for index = 1, capIndex do
		accumulated += self._weights[index]
		if threshold < accumulated then
			return self._order[math.max(index, floorIndex)]
		end
	end

	return self._order[capIndex]
end

return RarityTable
