--!strict
--[[
	Passes — gamepasses et leurs effets de jeu.

	IMPORTANT : renseigne `assetId` avec l'identifiant du gamepass cree sur le site
	Roblox. Un `assetId` a 0 desactive proprement le pass (aucun prompt d'achat,
	aucun effet) : le jeu reste jouable tel quel.
]]

export type Pass = {
	id: string,
	assetId: number,
	name: string,
	icon: string,
	description: string,
	-- Effets chiffres, agreges par Domain.Progression.Multipliers.
	effect: {
		speed: number?,
		bananas: number?,
		flat: { [string]: number }?,
	},
	-- Effet de confort applique par le client (aucun impact sur l'equilibrage).
	behaviour: string?,
}

local passes: { Pass } = {
	{
		id = "doubleSpeed",
		assetId = 0,
		name = "x2 Vitesse",
		icon = "⚡",
		description = "Double la vitesse gagnee a chaque pas, pour toujours.",
		effect = { speed = 2 },
	},
	{
		id = "doubleBananas",
		assetId = 0,
		name = "x2 Bananes",
		icon = "🍌",
		description = "Double toutes les bananes ramassees.",
		effect = { bananas = 2 },
	},
	{
		id = "superJump",
		assetId = 0,
		name = "Super Saut",
		icon = "🦘",
		description = "+15 de puissance de saut.",
		effect = { flat = { jumpPower = 15 } },
	},
	{
		id = "vipMonkey",
		assetId = 0,
		name = "Singe VIP",
		icon = "👑",
		description = "x1.5 vitesse et bananes, +1 s de course sur les murs.",
		effect = { speed = 1.5, bananas = 1.5, flat = { wallGrip = 1 } },
	},
	{
		id = "autoRun",
		assetId = 0,
		name = "Course automatique",
		icon = "🏃",
		description = "Ton singe court tout seul, meme sans toucher aux touches.",
		effect = {},
		behaviour = "autoRun",
	},
	{
		id = "bananaMagnet",
		assetId = 0,
		name = "Aimant a bananes",
		icon = "🧲",
		description = "Ramasse les bananes a distance en courant.",
		effect = {},
		behaviour = "magnet",
	},
}

return table.freeze(passes)
