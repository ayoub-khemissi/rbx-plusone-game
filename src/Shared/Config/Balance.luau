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
	-- Level -> actual walk speed
	speedCurve = table.freeze({
		baseWalkSpeed = 16, -- Roblox default, and the speed the first jump was designed around
		-- Ceiling at 120 studs/s, which is 2 studs between two frames: platforms
		-- thinner than that can be skipped, and anything built at 4 studs or more is
		-- safe. It sits high on purpose — a world of ten courses needs the speed to
		-- keep climbing all the way through, or the last five play like the fifth.
		maxBonusWalkSpeed = 104,
		--[[
			In LEVELS, not in speed, and the one number that decides how fast the
			game gets fast. Lower bites harder.

			Stretched to span a whole world. Simulated against real play — the gain
			rate feeds back into itself, since running faster earns levels faster —
			the character runs at 23 after eight minutes, 47 after an hour and 20,
			and 75 by the end of the tenth course at four and a half hours. It is
			still climbing there, which is what keeps the last courses different
			from the middle ones.
		]]
		softness = 155,
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
	--[[
		A dash is a MULTIPLE of the speed the character already runs at, so it keeps
		meaning the same thing all game. Unlocked and unimproved it is worth x1 —
		a burst in a chosen direction, no faster than running, which is exactly what
		makes Dash Power worth buying. Each level of that adds a multiple, up to x6.

		`maxPower` is a physics limit, not a balance one: past it the character
		crosses thin platforms between two frames. It is set generously, and a map
		built out of walls a few studs thick will want it lower.
	]]
	--[[
		A dash is a SPEED HELD for a fraction of a second, not a shove.

		A single write to the velocity is undone by the Humanoid within two or three
		frames, so it took absurd numbers to be felt and then crossed walls. Held for
		a third of a second, a modest speed covers real ground at a velocity the
		collision solver can still see.

		`floorSpeed` is what stops the dash being pointless early. A multiple of the
		run speed is a small number while the run speed is small: at 16 the dash was
		barely quicker than walking, so the upgrade did nothing the player could see.
		The multiplier applies to whichever is greater, the run speed or this floor.

		Distance covered, against what running covers in the same time:

		    run speed 16   running  6      1.5x 14   2x 18   3.5x 32   5x 46
		    run speed 40   running 14      1.5x 21   2x 28   3.5x 49   5x 70
		    run speed 53   running 19      1.5x 28   2x 37   3.5x 65   5x 70

		`maxSpeed` is a physics limit, not a balance one: 200 studs/s is about 3.3
		studs between two frames, so walls thinner than that can be crossed. It only
		meets the top levels once running is quick, which is late enough to be worth
		the trade.
	]]
	dash = table.freeze({
		multipliers = table.freeze({ 1.5, 2, 2.75, 3.5, 4.25, 5 }),
		duration = 0.35,
		floorSpeed = 26,
		maxSpeed = 200,
		cooldown = 2, -- seconds; a dash is a decision, not a resource to dump
	}),

	-- Steps to resources
	progression = table.freeze({
		speedPerStep = 1,
		coinsPerStep = 0.4,
	}),

	--[[
		Speed read as a rank. `base * level^exponent`, so the first levels arrive in
		seconds and the pace stretches without ever flattening.

		At the starting walk speed this is roughly a level every 15 seconds at the
		start, every 4 minutes around level 25, and the last Stage lands near level
		50 — far enough that there is always a next one in sight.

		A level grants nothing on its own. Rewards hang off Stages, which the map
		lays out; retuning this changes how progress READS, never what it pays.
	]]
	level = table.freeze({
		base = 20,
		-- 1.9 rather than 1.7: the exponent is what decides how long a world takes.
		-- At 1.7 the tenth course fell at forty minutes; at 1.9 it lands at four and
		-- a half hours of uninterrupted running, which is the floor a free player
		-- should meet.
		exponent = 1.9,
	}),

	-- The long loop. The requirement matches the last Stage: prestige is what you do
	-- once the course has nothing left to show you.
	prestige = table.freeze({
		-- The experience the tenth course sits behind: a prestige means the world
		-- is finished, not that an afternoon was spent.
		baseRequirement = 215000,
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
