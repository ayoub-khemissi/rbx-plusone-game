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
		-- 119 studs/s at level 200, which is the top of a world and the speed that
		-- was play-tested as the fastest worth having. That is 2 studs between two
		-- frames, so anything built at 4 studs or more is safe from being skipped.
		-- `maxBonusWalkSpeed` is the asymptote of the shape, not a target: the curve
		-- is aimed at 119 by level 200 and clamped there.
		maxBonusWalkSpeed = 200,
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
		softness = 275,
		-- Play-tested: the fastest the character should ever run.
		maxWalkSpeed = 119,
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

	--[[
		What the plate at the end of a stage pays.

		`share` is taken from what the NEXT stage costs to enter, so the reward
		scales with the game on its own. It is deliberately modest — roughly what
		running the stage pays anyway — because a plate that beats running turns a
		platformer into a queue. What makes it worth touching is the Coins and the
		ride back to the lobby.

		`minimum` exists for the first stage, which has almost nothing behind it: a
		reward of forty would teach a new player that the plate is not worth using.
	]]
	stage = table.freeze({
		share = 0.02,
		minimum = 300,
		coinsPerSpeed = 0.5,
	}),

	-- Steps to resources
	progression = table.freeze({
		speedPerStep = 1,
		coinsPerStep = 0.4,
		--[[
			How much faster ground already covered is re-covered, after a rebirth.

			Nine tenths of a world's experience sits in the last tenth of its levels,
			so without this a cycle spends most of itself re-walking known ground at a
			pace the player had already outgrown — twenty minutes of it by the seventh
			rebirth. At twelve, the climb back to where they were takes a couple of
			minutes and the rest of the cycle is spent on new ground.

			Paid on the GAIN, never on the price of a level: a discount would raise the
			level a given Speed reads as, every rebirth, until the number said nothing.
			See Domain.Movement.Progression.
		]]
		catchUp = 12,
	}),

	--[[
		Speed read as a rank. `base * level^exponent`, so the first levels arrive in
		seconds and the pace stretches without ever flattening.

		The exponent decides the SHAPE of a world, the base its LENGTH, and they are
		set together: 2.3 makes the first level arrive in twenty seconds and the two
		hundredth cost a third of the world, while 17.6 puts level 200 exactly on the
		experience seven rebirths add up to. A world is then four and a half hours of
		uninterrupted running WITH the shop bought as fast as it can be afforded —
		which is the floor a free player should meet.

		A flatter exponent was tried at 1.9: the same world, but the first level took
		two minutes to arrive, and the opening minutes are the ones a player decides
		on. Every world reads the same either way, because World scales this curve
		and the Stage ladder by the same factor.

		A level grants nothing on its own. Rewards hang off Stages, which the map
		lays out; retuning this changes how progress READS, never what it pays.
	]]
	level = table.freeze({
		base = 17.6,
		exponent = 2.3,
	}),

	-- The long loop. The requirement matches the last Stage: prestige is what you do
	-- once the course has nothing left to show you.
	--[[
		A rebirth is a loop INSIDE a world, and NOTHING about the ladder restarts.
		The count, the requirement and the multiplier run continuously across the
		whole game; a world is a stretch of that climb, entered once seven have been
		taken.

		THE TWO GROW AT THE SAME RATE, and they have to. A continuous ladder is only
		self-similar across worlds if the requirement and the multiplier climb
		together: let the requirement outpace it and every world takes longer than
		the last, by the same factor, forever. At 1.6 apiece every world is 4.6
		hours, exactly.

		Each cycle still reaches further than the one before — level 45 on the first,
		200 on the seventh — because the character keeps getting faster as it climbs.
		The seventh lands exactly on the top of the world, so the loop covers all ten
		stages rather than leaving the last ones for nobody. Cycles shorten as they
		go: near two hours for the first, a quarter of an hour for the last.

		Solved by simulating real play against the speed curve, since the earn rate
		feeds back into itself. The config spec re-runs that simulation.
	]]
	prestige = table.freeze({
		baseRequirement = 205666,
		requirementGrowth = 1.6,
		multiplierGrowth = 1.6,
		rebirthsPerWorld = 7,
		resetsUpgrades = true,
		keptCoinRatio = 0,
	}),

	run = table.freeze({
		coinValue = 10, -- default value of a Coin with no `Value` attribute
		-- Long enough that sweeping a course clean means running it again rather
		-- than circling one Coin. Counted per player: a fall puts them all back.
		coinRespawn = 30,
		-- How close a Coin has to be before it is drawn in. The Magnet upgrade adds
		-- to this; without it a player still picks up what they run through.
		coinReach = 7,
		respawnHeight = 4, -- studs above a checkpoint where the player reappears
		-- How long a fall costs. Long enough to be felt as a mistake, short enough
		-- that the player is running again before they reach for the mouse.
		respawnDelay = 2,
		fallGrace = 1, -- seconds of immunity after respawning, so a hazard cannot loop
		voidMargin = 80, -- studs under the lowest part of the map: below that, it is a fall
	}),

	persistence = table.freeze({
		dataStoreName = "Runner_Profiles_v1",
		leaderboardStoreName = "Runner_Leaderboard_v1",
		autosaveInterval = 90,
		maxRetries = 4,
		retryBackoff = 2,
	}),
})
