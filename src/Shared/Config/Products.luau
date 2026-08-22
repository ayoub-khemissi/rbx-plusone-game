--!strict
--[[
	Products — produits developpeur (achats repetables en Robux).

	Ce sont eux qui portent l'essentiel du revenu d'un jeu de type "+1" : le joueur
	revient acheter des bananes et des boosts a chaque palier difficile.

	IMPORTANT : `productId = 0` = produit non configure -> invisible et inachetable.
	Cree les produits sur create.roblox.com puis colle les identifiants ici. Les prix
	`robux` ne sont qu'un affichage : le vrai prix est celui defini sur le site.

	Grille de prix volontairement classique (99 / 199 / 499 / 999) : c'est celle a
	laquelle les joueurs Roblox sont habitues, avec une offre "meilleur rapport"
	mise en avant pour orienter vers le panier moyen le plus rentable.
]]

local ProductCatalog = require(script.Parent.Parent.Domain.Monetization.ProductCatalog)

type Definition = ProductCatalog.Definition

local products: { Definition } = {
	{
		id = "bananaSmall",
		productId = 0,
		name = "Poignee de bananes",
		description = "2 500 bananes tout de suite.",
		icon = "🍌",
		robux = 99,
		grant = { bananas = 2500 },
	},
	{
		id = "bananaMedium",
		productId = 0,
		name = "Regime de bananes",
		description = "8 000 bananes pour passer le palier.",
		icon = "🍌",
		robux = 199,
		badge = "populaire",
		grant = { bananas = 8000 },
	},
	{
		id = "bananaLarge",
		productId = 0,
		name = "Cageot de bananes",
		description = "30 000 bananes.",
		icon = "📦",
		robux = 499,
		grant = { bananas = 30000 },
	},
	{
		id = "bananaHuge",
		productId = 0,
		name = "Camion de bananes",
		description = "100 000 bananes : le meilleur rapport.",
		icon = "🚚",
		robux = 999,
		badge = "meilleure offre",
		grant = { bananas = 100000 },
	},
	{
		id = "speedRush",
		productId = 0,
		name = "Ruee du singe",
		description = "x2 vitesse pendant 20 minutes.",
		icon = "⚡",
		robux = 149,
		grant = { boost = { id = "speedRush", duration = 1200 } },
	},
	{
		id = "bananaFever",
		productId = 0,
		name = "Fievre de la banane",
		description = "x3 bananes pendant 20 minutes.",
		icon = "🔥",
		robux = 149,
		grant = { boost = { id = "bananaFever", duration = 1200 } },
	},
	{
		id = "serverParty",
		productId = 0,
		name = "Fete du serveur",
		description = "x1.5 vitesse et bananes pour TOUT le serveur, 10 minutes.",
		icon = "🎉",
		robux = 299,
		badge = "tout le serveur",
		grant = { serverBoost = { id = "serverParty", duration = 600 } },
	},
	{
		id = "instantRebirth",
		productId = 0,
		name = "Renaissance immediate",
		description = "Renais tout de suite et garde tes ameliorations.",
		icon = "🔁",
		robux = 399,
		grant = { rebirths = 1 },
	},
	{
		id = "starterPack",
		productId = 0,
		name = "Pack du petit singe",
		description = "5 000 bananes + 30 minutes de x2 vitesse.",
		icon = "🐒",
		robux = 199,
		badge = "offre de bienvenue",
		grant = { bananas = 5000, boost = { id = "speedRush", duration = 1800 } },
	},
}

return table.freeze(products)
