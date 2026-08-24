--!strict
--[[
	UpgradeCatalog — the cost and effect rules of the upgrades.

	The catalogue is built FROM injected definitions: the real configuration in
	production, fixtures in tests. Nothing is hardcoded here, so balancing stays
	data and a test never has to bend the real numbers to make a point.
]]

export type Definition = {
	id: string,
	name: string?,
	icon: string?,
	description: string?,
	maxLevel: number, -- 0 means unlimited
	baseCost: number,
	costGrowth: number,
	effectPerLevel: number,
	effect: string, -- "speedMultiplier" | "coinMultiplier" | a flat key such as "jumps"
}

local UpgradeCatalog = {}
UpgradeCatalog.__index = UpgradeCatalog

export type UpgradeCatalog = typeof(setmetatable(
	{} :: { _order: { string }, _byId: { [string]: Definition } },
	UpgradeCatalog
))

function UpgradeCatalog.new(definitions: { Definition }): UpgradeCatalog
	local order, byId = {}, {}

	for _, definition in definitions do
		if byId[definition.id] then
			error(`Duplicate upgrade in the catalogue: {definition.id}`, 2)
		end
		byId[definition.id] = definition
		table.insert(order, definition.id)
	end

	return setmetatable({ _order = order, _byId = byId }, UpgradeCatalog)
end

function UpgradeCatalog.ids(self: UpgradeCatalog): { string }
	return table.clone(self._order)
end

function UpgradeCatalog.get(self: UpgradeCatalog, upgradeId: string): Definition?
	return self._byId[upgradeId]
end

function UpgradeCatalog.expect(self: UpgradeCatalog, upgradeId: string): Definition
	local definition = self._byId[upgradeId]
	if not definition then
		error(`Unknown upgrade: {tostring(upgradeId)}`, 3)
	end
	return definition
end

--[[ The cost of going from `currentLevel` to `currentLevel + 1`. ]]
function UpgradeCatalog.costFor(self: UpgradeCatalog, upgradeId: string, currentLevel: number): number
	local definition = self:expect(upgradeId)
	return math.floor(definition.baseCost * definition.costGrowth ^ math.max(currentLevel, 0))
end

function UpgradeCatalog.isMaxed(self: UpgradeCatalog, upgradeId: string, currentLevel: number): boolean
	local definition = self:expect(upgradeId)
	return definition.maxLevel > 0 and currentLevel >= definition.maxLevel
end

function UpgradeCatalog.effectFor(self: UpgradeCatalog, upgradeId: string, level: number): number
	local definition = self:expect(upgradeId)
	return math.max(level, 0) * definition.effectPerLevel
end

--[[ Every definition carrying a given effect type. ]]
function UpgradeCatalog.byEffect(self: UpgradeCatalog, effect: string): { Definition }
	local matches = {}
	for _, id in self._order do
		local definition = self._byId[id]
		if definition.effect == effect then
			table.insert(matches, definition)
		end
	end
	return matches
end

return UpgradeCatalog
