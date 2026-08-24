--!strict
--[[
	Dragons — the species a player can hatch.

	Every dragon carries a small permanent bonus so collecting is never purely
	cosmetic, and the bonuses are deliberately modest: the collection is a long game,
	not a shortcut past the upgrades.

	Bonus keys map to Domain.Flight.Multipliers: gold, speed, agility, hatch.
]]

local DragonCatalog = require(script.Parent.Parent.Domain.Hatchery.DragonCatalog)

type Species = DragonCatalog.Species

local species: { Species } = {
	-- Common
	{
		id = "emberling",
		name = "Emberling",
		rarity = "common",
		bonus = { gold = 0.03 },
		description = "A hatchling that never stops chewing on coins.",
	},
	{
		id = "mossback",
		name = "Mossback",
		rarity = "common",
		bonus = { speed = 0.03 },
		description = "Slow to wake, quick once airborne.",
	},
	{
		id = "pebblewing",
		name = "Pebblewing",
		rarity = "common",
		bonus = { agility = 0.05 },
		description = "Small wings, very sharp turns.",
	},
	{
		id = "sunspeck",
		name = "Sunspeck",
		rarity = "common",
		bonus = { hatch = 0.04 },
		description = "Keeps the whole nest warm just by sitting in it.",
	},

	-- Rare
	{
		id = "stormtail",
		name = "Stormtail",
		rarity = "rare",
		bonus = { gold = 0.12, agility = 0.06 },
		description = "Rides the updrafts other dragons avoid.",
	},
	{
		id = "glasswing",
		name = "Glasswing",
		rarity = "rare",
		bonus = { speed = 0.12 },
		description = "Almost invisible at full speed.",
	},
	{
		id = "cinderfang",
		name = "Cinderfang",
		rarity = "rare",
		bonus = { gold = 0.18 },
		description = "Smells gold through solid rock.",
	},

	-- Epic
	{
		id = "aurorent",
		name = "Aurorent",
		rarity = "epic",
		bonus = { speed = 0.3, agility = 0.12 },
		description = "Born in the polar sky, made of light.",
	},
	{
		id = "mistcaller",
		name = "Mistcaller",
		rarity = "epic",
		bonus = { gold = 0.35, hatch = 0.12 },
		description = "Parts the fog for anyone flying behind.",
	},

	-- Legendary
	{
		id = "crownwyrm",
		name = "Crownwyrm",
		rarity = "legendary",
		bonus = { speed = 0.6, gold = 0.6, agility = 0.2, hatch = 0.25 },
		description = "Only ever seen above the last tier.",
	},
}

return table.freeze(species)
