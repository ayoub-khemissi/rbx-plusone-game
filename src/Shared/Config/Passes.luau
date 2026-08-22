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
	effect: {
		speed: number?,
		bananas: number?,
		flat: { [string]: number }?,
	},
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
}

return table.freeze(passes)
