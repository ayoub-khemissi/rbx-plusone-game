--!strict
--[[
	EggRoller — turns a tier's loot into actual eggs of a rolled rarity.

	The randomness lives here, at the edge of the Application layer, so the domain
	stays pure and reproducible. The rarity table enforces both the cap of the tier
	and its guaranteed floor; this service only decides how many rolls to make.
]]

local Shared = require(script.Parent.Parent.Shared)
local Profile = require(Shared.Domain.Profile.Profile)

local EggRoller = {}
EggRoller.__index = EggRoller

-- Beyond that many eggs, rolling one by one costs more than it is worth.
local MAX_INDIVIDUAL_ROLLS = 500

export type Dependencies = {
	rarities: any,
	random: any,
}

export type EggRoller = typeof(setmetatable({} :: Dependencies, EggRoller))

function EggRoller.new(dependencies: Dependencies): EggRoller
	return setmetatable(table.clone(dependencies), EggRoller)
end

--[[ Rolls `loot.eggs` eggs and returns how many of each rarity came out. ]]
function EggRoller.roll(self: EggRoller, loot: any, multiplier: number?): { [string]: number }
	local counts: { [string]: number } = {}
	if typeof(loot) ~= "table" then
		return counts
	end

	local amount = math.floor(math.max(loot.eggs or 0, 0) * math.max(multiplier or 1, 0))
	local rolls = math.min(amount, MAX_INDIVIDUAL_ROLLS)
	local perRoll = if rolls > 0 then amount / rolls else 0

	for _ = 1, rolls do
		local rarity = self.rarities:roll(loot.maxRarity, self.random.nextNumber(), loot.minRarity)
		counts[rarity] = (counts[rarity] or 0) + perRoll
	end

	for rarity, count in counts do
		counts[rarity] = math.floor(count + 0.5)
	end

	return counts
end

--[[ Rolls and credits in one go. ]]
function EggRoller.grant(self: EggRoller, profile: any, loot: any, multiplier: number?): { [string]: number }
	local counts = self:roll(loot, multiplier)
	for rarity, count in counts do
		Profile.addEggs(profile, rarity, count)
	end
	return counts
end

return EggRoller
