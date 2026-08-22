--!strict
--[[
	Monetization — reglages du modele economique.

	Le modele repose sur quatre piliers eprouves sur Roblox :
	  1. GRATUIT QUI FIDELISE  : recompense quotidienne a serie + coffre toutes les
	     5 minutes de jeu -> le joueur revient et reste (le temps de jeu est ce qui
	     fait remonter le jeu dans les recommandations Roblox) ;
	  2. PERMANENT             : gamepasses (x2 vitesse, x2 bananes, VIP...) achetes
	     une fois, valeur percue elevee ;
	  3. REPETABLE             : produits consommables (bananes, boosts) achetes a
	     chaque palier difficile -> c'est la source de revenu principale ;
	  4. SOCIAL & ACQUISITION  : boost de serveur payant visible par tous, codes
	     promo diffusables sur les reseaux, offre de bienvenue limitee dans le temps.

	Aucune de ces mecaniques ne bloque la progression : tout est achetable en jouant.
	C'est ce qui evite l'effet "pay-to-win" et preserve la retention.
]]

local HOUR = 3600
local DAY = 86400

return table.freeze({
	boosts = table.freeze({
		definitions = table.freeze({
			speedRush = table.freeze({ name = "Ruee du singe", icon = "⚡", speed = 2 }),
			bananaFever = table.freeze({ name = "Fievre de la banane", icon = "🔥", bananas = 3 }),
			serverParty = table.freeze({
				name = "Fete du serveur",
				icon = "🎉",
				speed = 1.5,
				bananas = 1.5,
			}),
			dailyRush = table.freeze({ name = "Bonus quotidien", icon = "📅", speed = 1.5 }),
		}),
		maxStackedDuration = 4 * HOUR,
	}),

	daily = table.freeze({
		dayLength = DAY,
		graceWindow = 2 * DAY,
		rewards = table.freeze({
			{ day = 1, label = "Jour 1", grant = { bananas = 500 } },
			{ day = 2, label = "Jour 2", grant = { bananas = 1500 } },
			{ day = 3, label = "Jour 3", grant = { boost = { id = "dailyRush", duration = 900 } } },
			{ day = 4, label = "Jour 4", grant = { bananas = 5000 } },
			{ day = 5, label = "Jour 5", grant = { boost = { id = "bananaFever", duration = 900 } } },
			{ day = 6, label = "Jour 6", grant = { bananas = 15000 } },
			{
				day = 7,
				label = "Jour 7",
				grant = { bananas = 40000, boost = { id = "speedRush", duration = 1800 } },
			},
		}),
	}),

	-- Zone AFK : revenu passif volontairement faible et NON multiplie, plafonne
	-- par session. Elle sert la retention, pas la progression.
	afk = table.freeze({
		bananasPerMinute = 300,
		payoutInterval = 60,
		sessionCapSeconds = 4 * HOUR,
		station = table.freeze({ x = -65, z = 65, radius = 26 }),
	}),

	playtimeChest = table.freeze({
		key = "playtimeChest",
		interval = 300,
		label = "Coffre de jungle",
		grant = { bananas = 750 },
	}),

	codes = table.freeze({
		{ code = "SINGE2026", label = "Lancement", grant = { bananas = 2500 } },
		{ code = "BANANE", label = "Merci", grant = { bananas = 1000 } },
		{ code = "WALLRUN", label = "Astuce", grant = { boost = { id = "speedRush", duration = 600 } } },
	}),

	offers = table.freeze({
		{
			id = "starterPack",
			productKey = "starterPack",
			title = "Pack du petit singe",
			description = "5 000 bananes + 30 min de x2 vitesse",
			triggerAfterSeconds = 240,
			durationSeconds = 900,
			oncePerProfile = true,
		},
		{
			id = "gateBooster",
			productKey = "speedRush",
			title = "Barriere trop rapide ?",
			description = "x2 vitesse pendant 20 minutes",
			trigger = "zoneBlocked",
			durationSeconds = 600,
		},
	}),
})
