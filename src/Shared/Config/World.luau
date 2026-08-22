--!strict
--[[ World — parametres du generateur de map (aucune logique, uniquement des reglages). ]]

return table.freeze({
	hub = table.freeze({
		size = 260, -- cote de la plateforme du hub, centree sur l'origine
		thickness = 6,
		color = { 118, 96, 74 },
		spawnHeight = 6,
	}),

	-- Passerelle reliant le hub a la premiere zone : sans elle, la piste est
	-- litteralement hors de portee d'un saut.
	approach = table.freeze({
		width = 44,
		railHeight = 3,
	}),

	track = table.freeze({
		thickness = 6,
		wallHeight = 42, -- murs lateraux : support du wall-run
		wallThickness = 4,
		wallSegmentLength = 70,
		wallGapLength = 34,
		hurdleSpacing = 95, -- espacement des obstacles au sol
		hurdleHeight = 5,
		bananaSpacing = 42,
		bananaHeight = 4.5,
		platformChance = 0.35, -- proportion de segments recevant une plateforme haute
	}),

	gate = table.freeze({
		height = 34,
		thickness = 3,
		transparency = 0.45,
		lockedColor = { 214, 78, 74 },
		unlockedColor = { 92, 206, 118 },
	}),

	decor = table.freeze({
		treesPerZone = 14,
		trunkHeight = 26,
		foliageSize = 22,
		sideOffset = 26, -- distance entre le bord de piste et les arbres
	}),
})
