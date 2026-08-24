--!strict
--[[
	Upgrades — what gold buys.

	`effect` names the bonus family aggregated by Domain.Flight.Multipliers:
	  speedMultiplier / goldMultiplier -> additive percentages
	  agility / magnet / feathers      -> flat bonuses
	`maxLevel = 0` means unlimited.

	Speed and agility are deliberately two separate purchases: buying speed alone
	makes the dragon impossible to steer, so the player has a real arbitrage instead
	of a slider to push right.
]]

local UpgradeCatalog = require(script.Parent.Parent.Domain.Economy.UpgradeCatalog)

type Definition = UpgradeCatalog.Definition

local definitions: { Definition } = {
	{
		id = "speedGain",
		name = "Wingbeat",
		icon = "💨",
		description = "+15% speed gained on every stretch flown.",
		maxLevel = 0,
		baseCost = 80,
		costGrowth = 1.32,
		effectPerLevel = 0.15,
		effect = "speedMultiplier",
	},
	{
		id = "goldGain",
		name = "Hoard Sense",
		icon = "🪙",
		description = "+20% gold from rings.",
		maxLevel = 0,
		baseCost = 65,
		costGrowth = 1.35,
		effectPerLevel = 0.2,
		effect = "goldMultiplier",
	},
	{
		id = "agility",
		name = "Tailfin",
		icon = "🪶",
		description = "Turn tighter — the counterweight to raw speed.",
		maxLevel = 30,
		baseCost = 220,
		costGrowth = 1.45,
		effectPerLevel = 1,
		effect = "agility",
	},
	{
		id = "magnet",
		name = "Ring Pull",
		icon = "🧲",
		description = "Catch rings from further away.",
		maxLevel = 12,
		baseCost = 400,
		costGrowth = 1.6,
		effectPerLevel = 4,
		effect = "magnet",
	},
	{
		id = "hatchSpeed",
		name = "Warm Scales",
		icon = "🔥",
		description = "Eggs hatch faster in the Nest.",
		maxLevel = 10,
		baseCost = 900,
		costGrowth = 1.8,
		effectPerLevel = 0.08,
		effect = "hatch",
	},
}

return table.freeze(definitions)
