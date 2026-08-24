--!strict
--[[
	Balance — every tuning number of the game, in one place.

	Project rule: no gameplay constant may live outside Config/. The domain receives
	these values by injection, which makes rebalancing a data change rather than a
	code change.

	Nothing here mentions a theme: these numbers describe running, jumping and
	falling, and hold whatever the maps look like.
]]

return table.freeze({
	-- Accumulated speed -> actual walk speed
	speedCurve = table.freeze({
		baseWalkSpeed = 16,
		maxBonusWalkSpeed = 234, -- ceiling at 250 studs/s: past that a character skips through thin floors
		softness = 1500,
		baseJumpPower = 50,
		jumpPowerPerLevel = 2.5,
		maxJumpPower = 140,
	}),

	-- Server-side displacement measurement (anti-cheat) and air jumps
	movement = table.freeze({
		studsPerStep = 4,
		deadzone = 0.15,
		toleranceFactor = 1.4, -- headroom over theoretical speed (lag, slopes)
		minimumSpeedAllowance = 16,
		sampleInterval = 0.2, -- server sampling period, in seconds
		-- Hard cap on the jump level: a player who could chain jumps forever would
		-- make every gap in every map meaningless.
		maxJumpLevel = 3,
	}),

	-- The dash: its level IS its power, which is what the player buys.
	dash = table.freeze({
		maxLevel = 3,
		basePower = 60,
		powerPerLevel = 30,
		cooldown = 2, -- seconds; a dash is a decision, not a resource to dump
	}),

	-- Steps to resources
	progression = table.freeze({
		speedPerStep = 1,
		coinsPerStep = 0.4,
	}),

	-- The long loop. The requirement matches the last Stage: prestige is what you do
	-- once the course has nothing left to show you.
	prestige = table.freeze({
		baseRequirement = 15000,
		requirementGrowth = 2.4,
		multiplierPerPrestige = 0.4,
		resetsUpgrades = true,
		keptCoinRatio = 0,
	}),

	run = table.freeze({
		coinValue = 10, -- default value of a Coin with no `Value` attribute
		coinRespawn = 15, -- seconds before a picked coin comes back
		respawnHeight = 4, -- studs above a checkpoint where the player reappears
		fallGrace = 1, -- seconds of immunity after respawning, so a hazard cannot loop
		voidMargin = 80, -- studs under the lowest part of the map: below that, it is a fall
	}),

	afk = table.freeze({
		coinsPerMinute = 240,
		payoutInterval = 60,
		sessionCapSeconds = 4 * 3600,
	}),

	persistence = table.freeze({
		dataStoreName = "Runner_Profiles_v1",
		leaderboardStoreName = "Runner_Leaderboard_v1",
		autosaveInterval = 90,
		maxRetries = 4,
		retryBackoff = 2,
	}),
})
