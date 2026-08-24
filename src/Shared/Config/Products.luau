--!strict
--[[
	Products — developer products (repeatable Robux purchases).

	These carry most of the revenue of a game like this: the player comes back to buy
	at every hard step. The ones that sell best are bought in a precise moment of
	friction — a barrier that refuses to open, an upgrade tree nobody wants to buy
	twice — which is why the catalogue answers problems rather than listing goods.

	IMPORTANT: `productId = 0` means "not created on the Roblox site yet" — the product
	is then invisible and unbuyable, so the game ships without ids and they can be
	filled in later without touching any code. The `robux` field is display only; the
	real price is the one set on the site.
]]

local ProductCatalog = require(script.Parent.Parent.Domain.Monetization.ProductCatalog)

type Definition = ProductCatalog.Definition

local products: { Definition } = {
	{
		id = "coinsSmall",
		productId = 0,
		name = "Handful of Coins",
		description = "2 500 coins, right now.",
		icon = "🪙",
		image = nil, -- icon:productCoinsSmall
		robux = 99,
		grant = { coins = 2500 },
	},
	{
		id = "coinsMedium",
		productId = 0,
		name = "Bag of Coins",
		description = "8 000 coins to clear the next barrier.",
		icon = "💰",
		image = nil, -- icon:productCoinsMedium
		robux = 199,
		badge = "popular",
		grant = { coins = 8000 },
	},
	{
		id = "coinsLarge",
		productId = 0,
		name = "Chest of Coins",
		description = "30 000 coins.",
		icon = "🏆",
		image = nil, -- icon:productCoinsLarge
		robux = 499,
		grant = { coins = 30000 },
	},
	{
		id = "coinsHuge",
		productId = 0,
		name = "Vault of Coins",
		description = "100 000 coins — the best value.",
		icon = "👑",
		image = nil, -- icon:productCoinsHuge
		robux = 999,
		badge = "best value",
		grant = { coins = 100000 },
	},
	{
		id = "speedRush",
		productId = 0,
		name = "Speed Rush",
		description = "x2 speed for 20 minutes.",
		icon = "⚡",
		image = nil, -- icon:productSpeedRush
		robux = 149,
		grant = { boost = { id = "speedRush", duration = 1200 } },
	},
	{
		id = "coinRush",
		productId = 0,
		name = "Coin Rush",
		description = "x3 coins for 20 minutes.",
		icon = "🔥",
		image = nil, -- icon:productCoinRush
		robux = 149,
		grant = { boost = { id = "coinRush", duration = 1200 } },
	},
	{
		id = "partyTime",
		productId = 0,
		name = "Party Time",
		description = "x1.5 speed and coins for EVERY player on the server, 10 minutes.",
		icon = "🎉",
		image = nil, -- icon:productPartyTime
		robux = 299,
		badge = "whole server",
		grant = { serverBoost = { id = "partyTime", duration = 600 } },
	},
	{
		id = "instantChest",
		productId = 0,
		name = "Instant Chest",
		description = "Opens your session chest right now.",
		icon = "🎁",
		image = nil, -- icon:productInstantChest
		robux = 149,
		grant = { instantChest = true },
	},
	{
		id = "instantPrestige",
		productId = 0,
		name = "Instant Prestige",
		description = "Prestige now, and keep your upgrades.",
		icon = "🔁",
		image = nil, -- icon:productInstantPrestige
		robux = 399,
		grant = { prestiges = 1 },
	},
	{
		id = "starterPack",
		productId = 0,
		name = "Starter Pack",
		description = "5 000 Coins and 30 minutes of x2 speed.",
		icon = "🎁",
		image = nil, -- icon:productStarterPack
		robux = 199,
		badge = "welcome offer",
		grant = {
			coins = 5000,
			boost = { id = "speedRush", duration = 1800 },
		},
	},
}

return table.freeze(products)
