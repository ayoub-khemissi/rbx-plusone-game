--!strict
--[[
	Pouch — everything carried during a single flight, and nothing else.

	This is the push-your-luck core. Gold picked from rings piles up raw; reaching a
	tier records how much that gold is worth and how many eggs the flight is holding.
	Nothing belongs to the player until the pouch is banked at an Altar.

	Two rules make the tension readable:

	  - the loot is the one of the DEEPEST tier reached, never the sum of the tiers
	    crossed, so climbing one more tier is a clean x2.5 rather than a vague trickle;
	  - permanent speed is never part of the pouch, so a failed flight still made the
	    player faster. Without that floor, a run of deaths feels like a wasted evening.

	The pouch lives in the session and is never persisted: a flight must not survive
	a reconnection.
]]

export type Tier = {
	id: number,
	goldMultiplier: number,
	eggs: number,
	maxRarity: string,
}

export type Pouch = {
	gold: number,
	tierId: number,
	goldMultiplier: number,
	eggs: number,
	maxRarity: string?,
}

export type Payload = {
	gold: number,
	eggs: number,
	maxRarity: string?,
	tierId: number,
	rescuedGold: number?,
	rescuedEggs: number?,
}

export type DropOptions = {
	insuranceRatio: number?,
	profile: any?,
}

local Pouch = {}

local function isUsableNumber(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value > 0
end

function Pouch.new(): Pouch
	return {
		gold = 0,
		tierId = 0,
		goldMultiplier = 0,
		eggs = 0,
		maxRarity = nil,
	}
end

function Pouch.isEmpty(pouch: Pouch): boolean
	return pouch.gold == 0 and pouch.tierId == 0
end

--[[ Raw gold picked up mid-flight. Multiplied only when the pouch is valued. ]]
function Pouch.addGold(pouch: Pouch, amount: number)
	if not isUsableNumber(amount) then
		return
	end
	pouch.gold += amount
end

--[[ Records a tier crossing. Only ever moves the pouch forward. ]]
function Pouch.reachTier(pouch: Pouch, tier: Tier): boolean
	if typeof(tier) ~= "table" or tier.id <= pouch.tierId then
		return false
	end

	pouch.tierId = tier.id
	pouch.goldMultiplier = tier.goldMultiplier
	pouch.eggs = tier.eggs
	pouch.maxRarity = tier.maxRarity
	return true
end

--[[ What the pouch is worth right now — used by the HUD to show what is at stake. ]]
function Pouch.preview(pouch: Pouch): Payload
	if pouch.tierId == 0 then
		-- Before the first tier nothing is claimable: the gold has no multiplier yet.
		return { gold = 0, eggs = 0, maxRarity = nil, tierId = 0 }
	end

	return {
		gold = pouch.gold * pouch.goldMultiplier,
		eggs = pouch.eggs,
		maxRarity = pouch.maxRarity,
		tierId = pouch.tierId,
	}
end

local function reset(pouch: Pouch)
	pouch.gold = 0
	pouch.tierId = 0
	pouch.goldMultiplier = 0
	pouch.eggs = 0
	pouch.maxRarity = nil
end

--[[
	Banks the pouch into the profile and empties it.

	Gold is credited here; eggs are only reported. Rolling their rarity needs
	randomness, which does not belong in a pure domain module — the Application layer
	does it with an injected generator.
]]
function Pouch.bank(pouch: Pouch, profile: any): Payload?
	if pouch.tierId == 0 then
		return nil
	end

	local payload = Pouch.preview(pouch)

	profile.gold += payload.gold
	profile.totals.goldEarned += payload.gold
	profile.deepestTier = math.max(profile.deepestTier, payload.tierId)

	reset(pouch)
	return payload
end

--[[
	Drops the pouch after a wall. Reports what was lost so the interface can show it.

	`insuranceRatio` is the paid safety net: part of the pouch is rescued instead of
	being lost outright.
]]
function Pouch.drop(pouch: Pouch, options: DropOptions?): Payload
	local payload = Pouch.preview(pouch)
	local ratio = options and options.insuranceRatio
	local profile = options and options.profile

	if isUsableNumber(ratio) and profile then
		local rescuedGold = math.floor(payload.gold * (ratio :: number))
		payload.rescuedGold = rescuedGold
		payload.rescuedEggs = math.floor(payload.eggs * (ratio :: number))

		profile.gold += rescuedGold
		profile.totals.goldEarned += rescuedGold
	end

	reset(pouch)
	return payload
end

return Pouch
