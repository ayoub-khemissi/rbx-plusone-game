--!strict
--[[
	TierLadder — the ten altitude tiers, their wind barriers and their loot.

	Two invariants are enforced at construction so a balancing mistake fails on the
	first server start rather than in production:

	  - entry speed must strictly rise, otherwise a tier is free;
	  - loot must strictly rise, otherwise climbing one more tier is pure downside and
	    the whole push-your-luck loop collapses.
]]

export type Tier = {
	id: number,
	name: string?,
	requiredSpeed: number,
	goldMultiplier: number,
	eggs: number,
	maxRarity: string,
	minRarity: string?, -- guaranteed floor on deep tiers
	length: number?,
	color: { number }?,
	hazard: string?,
}

export type Loot = {
	eggs: number,
	maxRarity: string,
	minRarity: string?,
	goldMultiplier: number,
}

local TierLadder = {}
TierLadder.__index = TierLadder

export type TierLadder = typeof(setmetatable(
	{} :: { _tiers: { Tier }, _byId: { [number]: Tier }, _indexById: { [number]: number } },
	TierLadder
))

function TierLadder.new(tiers: { Tier }): TierLadder
	local byId, indexById = {}, {}
	local previousSpeed = -math.huge
	local previousLoot = -math.huge

	for index, tier in tiers do
		if tier.requiredSpeed <= previousSpeed then
			error(`Tier ladder is invalid: entry speed of tier {tier.id} must be rising`, 2)
		end

		local lootValue = tier.eggs * tier.goldMultiplier
		if index > 1 and lootValue <= previousLoot then
			error(`Tier ladder is invalid: loot of tier {tier.id} must grow with the risk`, 2)
		end

		previousSpeed = tier.requiredSpeed
		previousLoot = lootValue
		byId[tier.id] = tier
		indexById[tier.id] = index
	end

	return setmetatable({ _tiers = tiers, _byId = byId, _indexById = indexById }, TierLadder)
end

function TierLadder.count(self: TierLadder): number
	return #self._tiers
end

function TierLadder.all(self: TierLadder): { Tier }
	return self._tiers
end

function TierLadder.get(self: TierLadder, tierId: number): Tier?
	return self._byId[tierId]
end

function TierLadder.requirementOf(self: TierLadder, tierId: number): number?
	local tier = self._byId[tierId]
	return tier and tier.requiredSpeed
end

function TierLadder.nextOf(self: TierLadder, tierId: number): Tier?
	local index = self._indexById[tierId]
	return if index then self._tiers[index + 1] else nil
end

function TierLadder.isUnlocked(self: TierLadder, tierId: number, speed: number): boolean
	local tier = self._byId[tierId]
	return tier ~= nil and speed >= tier.requiredSpeed
end

--[[ Deepest tier this speed can punch through. ]]
function TierLadder.highestUnlocked(self: TierLadder, speed: number): number
	local highest = self._tiers[1].id
	for _, tier in self._tiers do
		if speed >= tier.requiredSpeed then
			highest = tier.id
		else
			break
		end
	end
	return highest
end

--[[ Progress in [0, 1] between this barrier and the next one. ]]
function TierLadder.progressToNext(self: TierLadder, tierId: number, speed: number): number
	local tier = self._byId[tierId]
	local nextTier = self:nextOf(tierId)
	if not tier or not nextTier then
		return 1
	end

	local span = nextTier.requiredSpeed - tier.requiredSpeed
	if span <= 0 then
		return 1
	end
	return math.clamp((speed - tier.requiredSpeed) / span, 0, 1)
end

function TierLadder.lootOf(self: TierLadder, tierId: number): Loot?
	local tier = self._byId[tierId]
	if not tier then
		return nil
	end
	return {
		eggs = tier.eggs,
		maxRarity = tier.maxRarity,
		minRarity = tier.minRarity,
		goldMultiplier = tier.goldMultiplier,
	}
end

return TierLadder
