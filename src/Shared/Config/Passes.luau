--!strict
--[[
	Passes — gamepasses and what they grant.

	IMPORTANT: fill `assetId` with the id of the gamepass created on the Roblox site.
	An `assetId` of 0 disables the pass cleanly — no purchase prompt, no effect — so
	the game ships and stays playable before anything is created.

	Nothing here unlocks content: passes buy time and comfort, never access.
	Nothing here is themed either: a pass is described by its effect.
]]

export type Pass = {
	id: string,
	assetId: number,
	name: string,
	icon: string,
	description: string,
	-- Numeric effects, aggregated by Domain.Movement.Multipliers.
	effect: {
		speed: number?,
		coins: number?,
		flat: { [string]: number }?,
	},
	-- Comfort handled by the client or a use case; no impact on balance.
	behaviour: string?,
}

local passes: { Pass } = {
	{
		id = "doubleCoins",
		assetId = 0,
		name = "x2 Coins",
		icon = "🪙",
		description = "Doubles every Coin you earn.",
		effect = { coins = 2 },
	},
	{
		id = "doubleSpeed",
		assetId = 0,
		name = "x2 Speed",
		icon = "⚡",
		description = "Doubles the speed gained on every step.",
		effect = { speed = 2 },
	},
	{
		id = "swiftBoots",
		assetId = 0,
		name = "Swift Boots",
		icon = "👟",
		description = "x1.5 speed and a permanently higher jump.",
		effect = { speed = 1.5, flat = { jumpPower = 8 } },
	},
	{
		id = "extraJump",
		assetId = 0,
		name = "Extra Jump",
		icon = "🪽",
		description = "One more air jump than your upgrades allow.",
		effect = { flat = { jumps = 1 } },
	},
	{
		id = "coinMagnet",
		assetId = 0,
		name = "Coin Magnet",
		icon = "🧲",
		description = "Collect Coins from much further away.",
		effect = { flat = { magnet = 25 } },
	},
	{
		id = "autoRun",
		assetId = 0,
		name = "Auto Run",
		icon = "🏃",
		description = "Your character keeps running on its own.",
		effect = {},
		behaviour = "autoRun",
	},
}

return table.freeze(passes)
