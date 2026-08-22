--!strict
--[[
	Upgrades — definitions des ameliorations achetables en bananes.

	`effect` designe la famille de bonus agregee par Domain.Progression.Multipliers :
	  speedMultiplier / bananaMultiplier -> bonus additifs en pourcentage
	  jumpPower / wallGrip / airDash     -> bonus plats
	`maxLevel = 0` signifie "sans limite".
]]

local UpgradeCatalog = require(script.Parent.Parent.Domain.Economy.UpgradeCatalog)

type Definition = UpgradeCatalog.Definition

local definitions: { Definition } = {
	{
		id = "speedGain",
		name = "Foulee du Singe",
		icon = "👟",
		description = "+15% de vitesse gagnee a chaque pas.",
		maxLevel = 0,
		baseCost = 75,
		costGrowth = 1.32,
		effectPerLevel = 0.15,
		effect = "speedMultiplier",
	},
	{
		id = "bananaGain",
		name = "Flair a Bananes",
		icon = "🍌",
		description = "+20% de bananes ramassees.",
		maxLevel = 0,
		baseCost = 60,
		costGrowth = 1.35,
		effectPerLevel = 0.2,
		effect = "bananaMultiplier",
	},
	{
		id = "jumpPower",
		name = "Ressort Simien",
		icon = "🦘",
		description = "Saute plus haut pour attraper les lianes.",
		maxLevel = 30,
		baseCost = 250,
		costGrowth = 1.5,
		effectPerLevel = 1,
		effect = "jumpPower",
	},
	{
		id = "wallGrip",
		name = "Griffes Adherentes",
		icon = "🧗",
		description = "+0.25 s de course sur les murs.",
		maxLevel = 12,
		baseCost = 400,
		costGrowth = 1.6,
		effectPerLevel = 0.25,
		effect = "wallGrip",
	},
	{
		id = "airDash",
		name = "Elan Aerien",
		icon = "💨",
		description = "Un elan supplementaire en plein saut.",
		maxLevel = 3,
		baseCost = 1500,
		costGrowth = 3,
		effectPerLevel = 1,
		effect = "airDash",
	},
}

return table.freeze(definitions)
