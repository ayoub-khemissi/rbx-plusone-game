--!strict
--[[
	Tiers — the ten altitude tiers of the sky.

	`requiredSpeed` must stay STRICTLY rising, and so must the loot (checked at start
	up by Domain.Run.TierLadder). The wind barrier is what stops a brand new player
	from strolling to the top: a slow dragon dodges easily, so without a speed gate
	tier 10 would be farmable in the first minute.

	`goldMultiplier` applies when the pouch is BANKED, never while picking gold up.
]]

local TierLadder = require(script.Parent.Parent.Domain.Run.TierLadder)

type Tier = TierLadder.Tier

local tiers: { Tier } = {
	{
		id = 1,
		name = "Hanging Meadows",
		requiredSpeed = 0,
		goldMultiplier = 1,
		eggs = 1,
		maxRarity = "common",
		length = 480,
		hazard = "static",
		color = { 124, 196, 128 },
	},
	{
		id = 2,
		name = "Gilded Ruins",
		requiredSpeed = 150,
		goldMultiplier = 1.8,
		eggs = 3,
		maxRarity = "common",
		length = 480,
		hazard = "static",
		color = { 206, 176, 106 },
	},
	{
		id = 3,
		name = "Upturned Falls",
		requiredSpeed = 450,
		goldMultiplier = 2.6,
		eggs = 6,
		maxRarity = "rare",
		length = 520,
		hazard = "static",
		color = { 108, 176, 208 },
	},
	{
		id = 4,
		name = "Cloud Grove",
		requiredSpeed = 1200,
		goldMultiplier = 3.5,
		eggs = 12,
		maxRarity = "rare",
		length = 520,
		hazard = "drifting",
		color = { 176, 200, 224 },
	},
	{
		id = 5,
		name = "Amber Arches",
		requiredSpeed = 3000,
		goldMultiplier = 4.4,
		eggs = 25,
		maxRarity = "rare",
		minRarity = "rare",
		length = 560,
		hazard = "drifting",
		color = { 224, 158, 84 },
	},
	{
		id = 6,
		name = "Wind Sanctuary",
		requiredSpeed = 7500,
		goldMultiplier = 5.4,
		eggs = 45,
		maxRarity = "epic",
		length = 560,
		hazard = "rotating",
		color = { 196, 188, 220 },
	},
	{
		id = 7,
		name = "Sea of Mist",
		requiredSpeed = 18000,
		goldMultiplier = 6.5,
		eggs = 80,
		maxRarity = "epic",
		length = 600,
		hazard = "rotating",
		color = { 168, 180, 190 },
	},
	{
		id = 8,
		name = "Crystal Spires",
		requiredSpeed = 42000,
		goldMultiplier = 7.6,
		eggs = 140,
		maxRarity = "epic",
		length = 600,
		hazard = "narrow",
		color = { 150, 214, 226 },
	},
	{
		id = 9,
		name = "The Aurora",
		requiredSpeed = 95000,
		goldMultiplier = 8.8,
		eggs = 240,
		maxRarity = "epic",
		minRarity = "epic",
		length = 640,
		hazard = "narrow",
		color = { 132, 226, 190 },
	},
	{
		id = 10,
		name = "The Crown",
		requiredSpeed = 200000,
		goldMultiplier = 10,
		eggs = 400,
		maxRarity = "legendary",
		minRarity = "legendary",
		length = 700,
		hazard = "everything",
		color = { 244, 214, 120 },
	},
}

return table.freeze(tiers)
