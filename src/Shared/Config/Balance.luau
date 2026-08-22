--!strict
--[[
	Balance — tous les nombres d'equilibrage du jeu, au meme endroit.

	Regle du projet : aucune constante de gameplay ne doit apparaitre ailleurs que
	dans Config/. Le domaine recoit ces valeurs par injection.
]]

return table.freeze({
	-- Courbe vitesse accumulee -> vitesse de deplacement reelle
	speedCurve = table.freeze({
		baseWalkSpeed = 16,
		maxBonusWalkSpeed = 234, -- plafond a 250 studs/s : au-dela la physique decroche
		softness = 1200,
		baseJumpPower = 50,
		jumpPowerPerLevel = 3,
		maxJumpPower = 160,
	}),

	-- Mesure du deplacement cote serveur (anti-triche)
	movement = table.freeze({
		studsPerStep = 4,
		deadzone = 0.15,
		toleranceFactor = 1.4, -- marge au-dessus de la vitesse theorique (lag, pentes)
		minimumSpeedAllowance = 16,
		sampleInterval = 0.2, -- periode d'echantillonnage serveur, en secondes
	}),

	-- Conversion des pas en ressources
	progression = table.freeze({
		speedPerStep = 1,
		bananasPerStep = 0.35,
	}),

	rebirth = table.freeze({
		baseRequirement = 2500,
		requirementGrowth = 2.35,
		multiplierPerRebirth = 0.4,
		resetsUpgrades = true,
		keptBananaRatio = 0,
	}),

	-- Geometrie de la piste (le hub occupe la zone centrale autour de l'origine)
	layout = table.freeze({
		trackStartX = 200,
		trackWidth = 64,
		groundY = 0,
		spawnInset = 28,
	}),

	persistence = table.freeze({
		dataStoreName = "SingeRapide_Profils_v1",
		leaderboardStoreName = "SingeRapide_Classement_v1",
		autosaveInterval = 90,
		maxRetries = 4,
		retryBackoff = 2,
	}),

	session = table.freeze({
		bananaCollectAmount = 25,
		bananaRespawnDelay = 18,
		obstacleStunDuration = 1.5,
		obstacleSpeedPenalty = 0.45, -- vitesse conservee pendant l'etourdissement
	}),
})
