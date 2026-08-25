--!nocheck
--[[
	Guard rail over the real balancing data: a configuration mistake must break the
	build, not production.
]]

local Config = require(Config)
local StageLadder = require(Domain.Run.StageLadder)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local PrestigePolicy = require(Domain.Prestige.PrestigePolicy)
local SpeedCurve = require(Domain.Movement.SpeedCurve)
local JumpBudget = require(Domain.Movement.JumpBudget)
local DashPolicy = require(Domain.Movement.DashPolicy)
local ProductCatalog = require(Domain.Monetization.ProductCatalog)
local LevelCurve = require(Domain.Run.LevelCurve)

local KNOWN_EFFECTS = {
	speedMultiplier = true,
	coinMultiplier = true,
	jumpPower = true,
	jumps = true,
	dash = true,
	dashPower = true,
	magnet = true,
}

describe("Config.Stages", function()
	it("builds a valid ladder", function()
		expect(function()
			StageLadder.new(Config.Stages)
		end).never.toThrow()
	end)

	it("numbers the stages from 1 to N without a gap", function()
		for index, stage in Config.Stages do
			expect(stage.id).toBe(index)
		end
	end)

	it("opens the first stage to a brand new player", function()
		expect(Config.Stages[1].requiredSpeed).toBe(0)
	end)

	it("makes reaching one more stage clearly worth it", function()
		for index = 2, #Config.Stages do
			local previous, current = Config.Stages[index - 1], Config.Stages[index]
			local ratio = current.coinMultiplier / previous.coinMultiplier
			expect(ratio).toBeGreaterThan(1.2)
			expect(ratio).toBeLessThan(3)
		end
	end)
end)

describe("Config.Upgrades", function()
	it("builds a valid catalog", function()
		expect(function()
			UpgradeCatalog.new(Config.Upgrades)
		end).never.toThrow()
	end)

	it("only uses effect families the domain knows", function()
		for _, definition in Config.Upgrades do
			expect(KNOWN_EFFECTS[definition.effect]).toBe(true)
		end
	end)

	it("keeps costs rising and finite", function()
		local catalog = UpgradeCatalog.new(Config.Upgrades)
		for _, id in catalog:ids() do
			expect(catalog:costFor(id, 0)).toBeGreaterThan(0)
			expect(catalog:costFor(id, 20)).toBeLessThan(math.huge)

			-- A one-level upgrade is a switch, not a curve: there is no second
			-- price for it to rise to.
			if catalog:get(id).maxLevel ~= 1 then
				expect(catalog:costFor(id, 1)).toBeGreaterThan(catalog:costFor(id, 0))
			end
		end
	end)

	-- The two mechanics the player comes for must both be buyable.
	it("sells both the extra jumps and the dash", function()
		local catalog = UpgradeCatalog.new(Config.Upgrades)
		expect(catalog:get("jump")).never.toBeNil()
		expect(catalog:get("dash")).never.toBeNil()
	end)

	it("caps the upgrades exactly where the domain caps them", function()
		local catalog = UpgradeCatalog.new(Config.Upgrades)
		local jumps = JumpBudget.new(Config.Balance.movement)
		local dash = DashPolicy.new(Config.Balance.dash)

		-- Buying the last level must land exactly on the maximum, not past it.
		expect(jumps:levelFor({ flat = { jumps = catalog:get("jump").maxLevel } })).toBe(
			Config.Balance.movement.maxJumpLevel
		)
		-- The shop must sell exactly as many levels as the table has entries beyond
		-- the unimproved one, or the last one bought would grant nothing.
		expect(dash:powerLevelFor({ flat = { dashPower = catalog:get("dashPower").maxLevel } })).toBe(
			#Config.Balance.dash.multipliers - 1
		)
	end)
end)

describe("Config.Balance", function()
	--[[
		Regression, and the reason these three points are pinned: the character once
		ran at 82 studs/s a few minutes in, five times the default. A course with
		gaps in it becomes unplayable long before that, and the problem was only
		noticed by playing. A spec fixing the pace turns the next retune into a
		failing test rather than a feeling.
	]]
	it("keeps the character controllable at every level", function()
		local curve = SpeedCurve.new(Config.Balance.speedCurve)
		local levels = LevelCurve.new(Config.Balance.level)

		-- The first few minutes must be felt without becoming uncontrollable.
		local early = levels:levelFor(500)
		expect(curve:walkSpeedFor(early)).toBeGreaterThan(Config.Balance.speedCurve.baseWalkSpeed)
		expect(curve:walkSpeedFor(early)).toBeLessThan(24)

		--[[
			At the last course of a world the character is fast, but the curve has
			not run out: there has to be headroom left, or the courses after it
			would have nothing to give.
		]]
		local lastCourse = Config.Stages[#Config.Stages]
		local atLastCourse = curve:walkSpeedFor(levels:levelFor(lastCourse.requiredSpeed))
		local ceiling = Config.Balance.speedCurve.baseWalkSpeed + Config.Balance.speedCurve.maxBonusWalkSpeed

		expect(atLastCourse).toBeGreaterThan(60)
		expect(atLastCourse).toBeLessThan(ceiling * 0.75)

		--[[
			The ceiling is the physics limit, and it is what stops the character
			passing through thin platforms between two frames. At 120 studs/s that
			is two studs a frame, so anything built at four or more is safe.
		]]
		expect(curve:walkSpeedFor(1e12)).toBeLessThanOrEqual(120)
	end)

	it("leaves an anti-cheat margin above 1", function()
		expect(Config.Balance.movement.toleranceFactor).toBeGreaterThan(1)
		expect(Config.Balance.movement.sampleInterval).toBeGreaterThan(0)
	end)

	--[[
		The multiples the shop row promises have to be the ones the domain grants.
		A description saying x6 and a policy granting x4 is the kind of drift nobody
		notices until a player counts.
	]]
	it("keeps the dash worth upgrading, at the multiples it advertises", function()
		local dash = DashPolicy.new(Config.Balance.dash)
		local levels = UpgradeCatalog.new(Config.Upgrades):get("dashPower").maxLevel

		expect(dash:multiplierFor(0)).toBeLessThan(dash:multiplierFor(1))
		expect(dash:multiplierFor(levels)).toBe(Config.Balance.dash.multipliers[levels + 1])

		-- A dash has to beat running at the speed a starting player runs at, or the
		-- first purchase buys nothing anybody can see.
		local starting = Config.Balance.speedCurve.baseWalkSpeed
		expect(dash:powerFor(0, starting)).toBeGreaterThan(starting * 2)
		expect(dash:powerFor(levels, starting)).toBeGreaterThan(dash:powerFor(1, starting))
		expect(Config.Balance.dash.cooldown).toBeGreaterThan(0)
	end)

	--[[
		THE PACING OF A WHOLE WORLD, which is the reason the curve is shaped the way
		it is: a free player running without pause must not clear ten courses in an
		afternoon. Everything sold on top — the treadmills — shortens this, and it
		only means something if the floor is real.

		Simulated rather than reasoned about, because the gain feeds back into
		itself: running faster earns levels faster, which makes you run faster. Any
		retune of the level exponent or the speed curve moves this, and that is
		exactly when someone should be told.
	]]
	it("keeps a world out of reach for at least four hours of running", function()
		local curve = SpeedCurve.new(Config.Balance.speedCurve)
		local levels = LevelCurve.new(Config.Balance.level)
		local policy = PrestigePolicy.new(Config.Balance.prestige)
		local perSecond = Config.Balance.progression.speedPerStep / Config.Balance.movement.studsPerStep
		local perWorld = Config.Balance.prestige.rebirthsPerWorld

		-- The seven cycles of reset-and-climb a world is made of. Each is quicker
		-- than the last, because the multiplier keeps what the reset takes away.
		local seconds, step = 0, 5
		for taken = 0, perWorld - 1 do
			local target = policy:requirementFor(taken)
			local multiplier = policy:multiplierFor(taken)
			local experience = 0

			while experience < target and seconds < 20 * 3600 do
				experience += curve:walkSpeedFor(levels:levelFor(experience)) * perSecond * multiplier * step
				seconds += step
			end
		end

		expect(seconds / 3600).toBeGreaterThan(4)
		expect(seconds / 3600).toBeLessThan(6)
	end)

	--[[
		And the level each course announces has to be the level a player actually
		holds when they arrive. A gate saying 12 in front of a course built for a
		speed nobody has at 12 is worse than no gate.
	]]
	it("announces a level that matches the experience behind it", function()
		local levels = LevelCurve.new(Config.Balance.level)
		for _, stage in Config.Stages do
			expect(levels:levelFor(stage.requiredSpeed)).toBe(stage.requiredLevel)
		end
	end)

	--[[
		A rebirth is a loop inside a world, so its first requirement sits in the
		MIDDLE of the course ladder: early enough that the loop starts before a
		player has seen everything, late enough to be a decision rather than a
		formality on the first climb.
	]]
	it("places the first rebirth in the middle of a world", function()
		local policy = PrestigePolicy.new(Config.Balance.prestige)
		local first = policy:requirementFor(0)

		expect(first).toBeGreaterThan(Config.Stages[3].requiredSpeed)
		expect(first).toBeLessThan(Config.Stages[7].requiredSpeed)
		expect(policy:multiplierFor(1)).toBeGreaterThan(1)
	end)

	--[[
		The ladder is CONTINUOUS: nothing about it restarts at a world boundary. What
		keeps it climbable is that the multiplier compounds alongside it, a little
		more slowly, so a rebirth becomes a bigger decision by degrees rather than
		becoming a wall.
	]]
	it("runs one unbroken ladder across every world", function()
		local policy = PrestigePolicy.new(Config.Balance.prestige)
		local perWorld = Config.Balance.prestige.rebirthsPerWorld

		expect(policy:requirementFor(perWorld)).toBeGreaterThan(policy:requirementFor(perWorld - 1))
		expect(policy:multiplierFor(perWorld)).toBeGreaterThan(policy:multiplierFor(perWorld - 1))

		-- The gap between the two widens, but slowly enough to stay walkable: a
		-- rebirth deep in the game must not cost hours more than the one before it.
		local early = policy:requirementFor(1) / policy:multiplierFor(1)
		local late = policy:requirementFor(30) / policy:multiplierFor(30)
		expect(late / early).toBeLessThan(3)
	end)
end)

describe("Config.Theme", function()
	-- A theme carries presentation only: never a balancing number.
	it("names every core concept", function()
		for _, key in { "speed", "coins", "prestige", "stage", "checkpoint", "hub" } do
			local label = Config.Theme.labels[key]
			expect(label).never.toBeNil()
			expect(label.name).toBeA("string")
			expect(label.icon).toBeA("string")
		end
	end)

	it("carries no balancing number", function()
		expect(Config.Theme.labels.speed.baseWalkSpeed).toBeNil()
		expect(Config.Theme.requiredSpeed).toBeNil()
	end)
end)

describe("Config.Products and Passes", function()
	it("builds a valid product catalog", function()
		expect(function()
			ProductCatalog.new(Config.Products)
		end).never.toThrow()
	end)

	it("exposes unique pass ids with a numeric assetId", function()
		local seen = {}
		for _, pass in Config.Passes do
			expect(seen[pass.id]).toBeNil()
			seen[pass.id] = true
			expect(pass.assetId).toBeA("number")
		end
	end)

	it("only grants flat bonuses the domain knows", function()
		for _, pass in Config.Passes do
			for key in pass.effect.flat or {} do
				expect(KNOWN_EFFECTS[key]).toBe(true)
			end
		end
	end)

	--[[
		The real curve, against the real Stages. The rank is only worth reading if it
		keeps moving over the whole span the map covers.
	]]
	it("keeps the level climbing across the whole course", function()
		local curve = LevelCurve.new(Config.Balance.level)
		local lastStage = Config.Stages[#Config.Stages]

		expect(curve:levelFor(0)).toBe(1)
		expect(curve:requirementFor(2)).toBeLessThan(200)
		expect(curve:levelFor(lastStage.requiredSpeed)).toBeGreaterThan(20)
	end)

	--[[
		Every noun the interface speaks has to exist in the theme, because the views
		read them and a missing one shows up as an empty string in a message rather
		than as an error anybody notices.
	]]
	it("names every concept the interface speaks", function()
		for _, key in { "level", "stage", "coins", "prestige", "checkpoint", "hub" } do
			local label = Config.Theme.labels[key]
			expect(label).never.toBeNil()
			expect(label.name).toBeA("string")
			expect(#label.name).toBeGreaterThan(0)
		end
	end)

	it("points every offer at a product that exists", function()
		local catalog = ProductCatalog.new(Config.Products)
		for _, offer in Config.Monetization.offers do
			expect(catalog:get(offer.productKey)).never.toBeNil()
		end
	end)
end)
