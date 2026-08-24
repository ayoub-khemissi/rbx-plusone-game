--!strict
--[[
	Upgrades — what Coins buy.

	`effect` names the bonus family aggregated by Domain.Movement.Multipliers:
	  speedMultiplier / coinMultiplier -> additive percentages
	  jumpPower / airJumps / magnet    -> flat bonuses
	`maxLevel = 0` means unlimited.

	`jump` and `dash` are deliberately expensive and capped: they are not stats to
	grind but milestones. Each level changes which parts of a map are reachable, so
	they are events, not increments.

	Careful with `jump`: the character starts at jump level 1, so buying level 1 of
	this upgrade grants the DOUBLE jump and level 2 the triple. The interface shows
	the real jump level, never the raw upgrade level.
]]

local UpgradeCatalog = require(script.Parent.Parent.Domain.Economy.UpgradeCatalog)

type Definition = UpgradeCatalog.Definition

local definitions: { Definition } = {
	{
		id = "speedGain",
		name = "Stride",
		icon = "👟",
		description = "+15% speed gained on every stretch run.",
		maxLevel = 0,
		baseCost = 60,
		costGrowth = 1.3,
		effectPerLevel = 0.15,
		effect = "speedMultiplier",
	},
	{
		id = "coinGain",
		name = "Fortune",
		icon = "🪙",
		description = "+20% Coins from everything.",
		maxLevel = 0,
		baseCost = 50,
		costGrowth = 1.32,
		effectPerLevel = 0.2,
		effect = "coinMultiplier",
	},
	{
		id = "jumpPower",
		name = "Spring",
		icon = "🦿",
		description = "Jump higher.",
		maxLevel = 30,
		baseCost = 200,
		costGrowth = 1.4,
		effectPerLevel = 1,
		effect = "jumpPower",
	},
	{
		id = "jump",
		name = "Air Jump",
		icon = "🪽",
		description = "Double jump, then triple jump.",
		maxLevel = 2,
		baseCost = 2500,
		costGrowth = 8,
		effectPerLevel = 1,
		effect = "jumps",
	},
	{
		id = "dash",
		name = "Dash",
		icon = "💨",
		description = "A burst forward. Each level hits harder.",
		maxLevel = 3,
		baseCost = 1200,
		costGrowth = 6,
		effectPerLevel = 1,
		effect = "dash",
	},
	{
		id = "magnet",
		name = "Magnet",
		icon = "🧲",
		description = "Collect Coins from further away.",
		maxLevel = 12,
		baseCost = 400,
		costGrowth = 1.6,
		effectPerLevel = 4,
		effect = "magnet",
	},
}

return table.freeze(definitions)
