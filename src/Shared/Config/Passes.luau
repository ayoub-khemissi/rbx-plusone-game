--!strict
--[[
	Passes — gamepasses and what they grant.

	IMPORTANT: fill `assetId` with the id of the gamepass created on the Roblox site.
	An `assetId` of 0 disables the pass cleanly — no purchase prompt, no effect — so
	the game ships and stays playable before anything is created.

	Nothing here unlocks content: passes buy time and comfort, never access.
]]

export type Pass = {
	id: string,
	assetId: number,
	name: string,
	icon: string,
	description: string,
	-- Numeric effects, aggregated by Domain.Flight.Multipliers.
	effect: {
		speed: number?,
		gold: number?,
		flat: { [string]: number }?,
	},
	-- Comfort handled by the client or a use case; no impact on balance.
	behaviour: string?,
}

local passes: { Pass } = {
	{
		id = "doubleGold",
		assetId = 0,
		name = "x2 Gold",
		icon = "🪙",
		description = "Doubles every piece of gold you carry home.",
		effect = { gold = 2 },
	},
	{
		id = "doubleEggs",
		assetId = 0,
		name = "x2 Eggs",
		icon = "🥚",
		description = "Doubles the eggs banked at an Altar.",
		effect = {},
		behaviour = "doubleEggs",
	},
	{
		id = "swiftWing",
		assetId = 0,
		name = "Swift Wing",
		icon = "💨",
		description = "x1.5 speed gain and a permanently steadier turn.",
		effect = { speed = 1.5, flat = { agility = 2 } },
	},
	{
		id = "phoenixFeather",
		assetId = 0,
		name = "Phoenix Feather",
		icon = "🪶",
		description = "One wall forgiven per flight — your pouch survives.",
		effect = { flat = { feathers = 1 } },
	},
	{
		id = "ringMagnet",
		assetId = 0,
		name = "Ring Magnet",
		icon = "🧲",
		description = "Catch rings from much further away.",
		effect = { flat = { magnet = 25 } },
	},
	{
		id = "nestKeeper",
		assetId = 0,
		name = "Nest Keeper",
		icon = "🪺",
		description = "Two extra hatchery slots, forever.",
		effect = {},
		behaviour = "extraSlots",
	},
}

return table.freeze(passes)
