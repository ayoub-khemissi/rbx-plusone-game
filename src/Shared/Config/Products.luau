--!strict
--[[
	Products — developer products (repeatable Robux purchases).

	These carry most of the revenue of a game like this: the player comes back to buy
	at every hard step. Three of them are specific to a push-your-luck loop and sell
	themselves because they are bought in the moment of regret — the feather, the
	insurance and the instant hatch.

	IMPORTANT: `productId = 0` means "not created on the Roblox site yet" — the product
	is then invisible and unbuyable, so the game ships without ids and they can be
	filled in later without touching any code. The `robux` field is display only; the
	real price is the one set on the site.
]]

local ProductCatalog = require(script.Parent.Parent.Domain.Monetization.ProductCatalog)

type Definition = ProductCatalog.Definition

local products: { Definition } = {
	{
		id = "goldSmall",
		productId = 0,
		name = "Pouch of Gold",
		description = "2 500 gold, right now.",
		icon = "🪙",
		robux = 99,
		grant = { gold = 2500 },
	},
	{
		id = "goldMedium",
		productId = 0,
		name = "Chest of Gold",
		description = "8 000 gold to clear the next barrier.",
		icon = "💰",
		robux = 199,
		badge = "popular",
		grant = { gold = 8000 },
	},
	{
		id = "goldLarge",
		productId = 0,
		name = "Hoard of Gold",
		description = "30 000 gold.",
		icon = "🏆",
		robux = 499,
		grant = { gold = 30000 },
	},
	{
		id = "goldHuge",
		productId = 0,
		name = "Dragon's Hoard",
		description = "100 000 gold — the best value.",
		icon = "👑",
		robux = 999,
		badge = "best value",
		grant = { gold = 100000 },
	},
	{
		id = "swiftRush",
		productId = 0,
		name = "Swift Rush",
		description = "x2 speed for 20 minutes.",
		icon = "⚡",
		robux = 149,
		grant = { boost = { id = "swiftRush", duration = 1200 } },
	},
	{
		id = "goldFever",
		productId = 0,
		name = "Gold Fever",
		description = "x3 gold for 20 minutes.",
		icon = "🔥",
		robux = 149,
		grant = { boost = { id = "goldFever", duration = 1200 } },
	},
	{
		id = "skyFestival",
		productId = 0,
		name = "Sky Festival",
		description = "x1.5 speed and gold for EVERY dragon on the server, 10 minutes.",
		icon = "🎉",
		robux = 299,
		badge = "whole server",
		grant = { serverBoost = { id = "skyFestival", duration = 600 } },
	},
	{
		id = "instantHatch",
		productId = 0,
		name = "Instant Hatch",
		description = "Every egg in the Nest hatches at once.",
		icon = "🥚",
		robux = 149,
		grant = { instantHatch = true },
	},
	{
		id = "flightInsurance",
		productId = 0,
		name = "Flight Insurance",
		description = "Hit a wall and keep half your pouch — for your next three flights.",
		icon = "🛡️",
		robux = 199,
		grant = { insurance = { flights = 3 } },
	},
	{
		id = "instantMolt",
		productId = 0,
		name = "Instant Molt",
		description = "Molt now, and keep your upgrades.",
		icon = "🐉",
		robux = 399,
		grant = { molts = 1 },
	},
	{
		id = "starterPack",
		productId = 0,
		name = "Hatchling Pack",
		description = "5 000 gold, a rare egg and 30 minutes of x2 speed.",
		icon = "🎁",
		robux = 199,
		badge = "welcome offer",
		grant = {
			gold = 5000,
			eggs = { rarity = "rare", amount = 1 },
			boost = { id = "swiftRush", duration = 1800 },
		},
	},
}

return table.freeze(products)
