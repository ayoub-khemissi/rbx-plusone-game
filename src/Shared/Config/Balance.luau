--!strict
--[[
	Balance — every tuning number of the game, in one place.

	Project rule: no gameplay constant may live outside Config/. The domain receives
	these values by injection, which is what makes rebalancing a data change rather
	than a code change.
]]

return table.freeze({
	-- Accumulated speed -> actual flight velocity
	speedCurve = table.freeze({
		baseVelocity = 70,
		maxBonusVelocity = 230, -- ceiling at 300 studs/s: past that a wall can be crossed between two frames
		softness = 1500,
		baseAgility = 1,
		agilityPerLevel = 0.1,
		maxAgility = 4,
	}),

	-- Server-side displacement measurement (anti-cheat)
	flight = table.freeze({
		studsPerStep = 8,
		deadzone = 0.2,
		toleranceFactor = 1.4, -- headroom over theoretical velocity (lag, dives)
		minimumSpeedAllowance = 70,
		sampleInterval = 0.2, -- server sampling period, in seconds
	}),

	-- Steps to resources
	progression = table.freeze({
		speedPerStep = 1,
		goldPerStep = 0.6,
	}),

	-- The long loop. The requirement matches the last tier: molting is what you do
	-- once the sky has nothing left to show you.
	molt = table.freeze({
		baseRequirement = 200000,
		requirementGrowth = 2.4,
		multiplierPerMolt = 0.4,
		resetsUpgrades = true,
		keptGoldRatio = 0,
	}),

	-- Sky geometry (the Nest sits before the first tier, around the origin)
	sky = table.freeze({
		launchX = 240,
		corridorWidth = 140,
		corridorHeight = 100,
		baseAltitude = 180,
		altitudeStep = 110,
		altarOffset = 95, -- lateral detour needed to bank: banking must cost something
		ringSpacing = 55,
		ringWeave = 32,
	}),

	run = table.freeze({
		ringValue = 12, -- raw gold per ring, before multipliers
		insuranceRatio = 0.5, -- share of the pouch rescued by the paid insurance
		respawnDelay = 0.6,
		perchInterval = 5, -- how often perched incubation is credited, in seconds
	}),

	persistence = table.freeze({
		dataStoreName = "SkyDragons_Profiles_v1",
		leaderboardStoreName = "SkyDragons_Leaderboard_v1",
		autosaveInterval = 90,
		maxRetries = 4,
		retryBackoff = 2,
	}),
})
