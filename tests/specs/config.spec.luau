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

		THE SHOP IS PART OF THE MEASUREMENT. Measured without it this used to read
		over four hours while the real game took under one: Stride alone multiplies
		the gain by five before a world is out, and a floor that ignores the single
		biggest accelerator in the game is not a floor. So the simulation buys, the
		way a player buys — whatever is affordable, cheapest first.

		Simulated rather than reasoned about, because the gain feeds back into
		itself: running faster earns more, which buys more, which runs faster. Any
		retune of the exponent, the speed curve or a price moves this, and that is
		exactly when someone should be told.
	]]
	local function simulateWorld(world: number): number
		local scale = Config.Worlds[world].scale
		local curve = SpeedCurve.new(Config.Balance.speedCurve)
		local levels = LevelCurve.new({
			base = Config.Balance.level.base * scale,
			exponent = Config.Balance.level.exponent,
		})
		local policy = PrestigePolicy.new(Config.Balance.prestige)
		local catalog = UpgradeCatalog.new(Config.Upgrades, {
			priceGrowthPerPrestige = Config.Balance.prestige.multiplierGrowth,
		})

		local perWorld = Config.Balance.prestige.rebirthsPerWorld
		local tuning = Config.Balance.progression
		local perStep = 1 / Config.Balance.movement.studsPerStep
		local seconds, step = 0, 2
		local best = 0

		for cycle = 0, perWorld - 1 do
			-- The ladder is continuous: the second world starts at the seventh
			-- rebirth, and its scale is already that multiplier.
			local prestiges = (world - 1) * perWorld + cycle
			local multiplier = policy:multiplierFor(prestiges)
			-- No world scale here: the requirement already grows by the same rebirth
			-- multiplier the scale is made of, and counting it twice would make every
			-- world after the first look impossible.
			local target = policy:requirementFor(prestiges)
			local upgrades, speed, coins = {}, 0, 0

			while speed < target and seconds < 40 * 3600 do
				local level = levels:levelFor(speed)

				local stageMultiplier = 1
				for _, stage in Config.Stages do
					if speed >= stage.requiredSpeed * scale then
						stageMultiplier = stage.coinMultiplier
					end
				end

				local speedBonus, coinBonus = 0, 0
				for id, owned in upgrades do
					local definition = catalog:get(id)
					if definition.effect == "speedMultiplier" then
						speedBonus += definition.effectPerLevel * owned
					elseif definition.effect == "coinMultiplier" then
						coinBonus += definition.effectPerLevel * owned
					end
				end

				local catchUp = if best > 0 and level < best then tuning.catchUp else 1
				local steps = curve:walkSpeedFor(level) * perStep * step
				speed += steps * tuning.speedPerStep * (1 + speedBonus) * multiplier * catchUp
				coins += steps * tuning.coinsPerStep * (1 + coinBonus) * multiplier * stageMultiplier
				best = math.max(best, level)

				local bought = true
				while bought do
					bought = false
					local cheapest, price = nil, math.huge
					for _, definition in Config.Upgrades do
						local owned = upgrades[definition.id] or 0
						if not catalog:isMaxed(definition.id, owned) then
							local cost = catalog:costFor(definition.id, owned, prestiges)
							if cost <= coins and cost < price then
								cheapest, price = definition.id, cost
							end
						end
					end
					if cheapest then
						upgrades[cheapest] = (upgrades[cheapest] or 0) + 1
						coins -= price
						bought = true
					end
				end

				seconds += step
			end
		end

		return seconds / 3600
	end

	it("keeps a world out of reach for at least four hours of running", function()
		local hours = simulateWorld(1)
		expect(hours).toBeGreaterThan(4)
		expect(hours).toBeLessThan(6)
	end)

	--[[
		AND EVERY WORLD COSTS THE SAME, which is the promise the whole scaling rests
		on: the ladder, the level curve and the shop are all multiplied by the same
		rebirth multiplier, so a world is the same climb wherever it sits. Before the
		shop was priced that way it was the odd one out — fixed prices against income
		that grows every rebirth — and the fifth world took a quarter of the first.
	]]
	it("costs the same in every world", function()
		local first = simulateWorld(1)
		for world = 2, #Config.Worlds do
			expect(simulateWorld(world)).toBeCloseTo(first, first * 0.05)
		end
	end)

	--[[
		A world is two hundred levels, and the seventh rebirth is what closes it. If
		the requirement stopped short the last courses would belong to nobody; if it
		overshot, the level a world ends on would drift world after world.
	]]
	it("ends a world on level 200", function()
		local levels = LevelCurve.new(Config.Balance.level)
		local policy = PrestigePolicy.new(Config.Balance.prestige)
		local last = policy:requirementFor(Config.Balance.prestige.rebirthsPerWorld - 1)

		expect(levels:levelFor(last)).toBe(200)
	end)

	--[[
		And the top of that ladder has to be the top of the speed curve: level 200 is
		where a world ends and where the character stops getting faster, or one of
		the two numbers is decoration.
	]]
	it("reaches the top speed exactly at the top of the world", function()
		local curve = SpeedCurve.new(Config.Balance.speedCurve)
		expect(curve:walkSpeedFor(200)).toBe(Config.Balance.speedCurve.maxWalkSpeed)
		expect(curve:walkSpeedFor(199)).toBeLessThan(Config.Balance.speedCurve.maxWalkSpeed)
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
		And the LAST one lands on the top of the world. Without this the rebirth loop
		tops out below the final stages and a player moves on having never seen them
		— a third of a world nobody plays.
	]]
	it("reaches the top of the world on its last rebirth", function()
		local policy = PrestigePolicy.new(Config.Balance.prestige)
		local levels = LevelCurve.new(Config.Balance.level)
		local perWorld = Config.Balance.prestige.rebirthsPerWorld
		local lastStage = Config.Stages[#Config.Stages]

		local final = policy:requirementFor(perWorld - 1)
		expect(final).toBeGreaterThan(lastStage.requiredSpeed)
		expect(levels:levelFor(final)).toBeGreaterThanOrEqual(lastStage.requiredLevel)
	end)

	--[[
		A stage every twenty levels, two hundred to a world. The regularity is the
		promise: a player always knows how far the next gate is, and every world is
		built to the same ruler.
	]]
	it("spaces the stages evenly across a world", function()
		for index = 2, #Config.Stages do
			expect(Config.Stages[index].requiredLevel).toBe((index - 1) * 20)
		end
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

		--[[
			The two must climb at THE SAME RATE. A continuous ladder is only
			self-similar across worlds if they do: let the requirement outpace the
			multiplier and every world takes longer than the last by the same factor,
			forever, until the ladder is a wall. This is the assertion that caught
			exactly that.
		]]
		local early = policy:requirementFor(1) / policy:multiplierFor(1)
		local late = policy:requirementFor(30) / policy:multiplierFor(30)
		-- Loose, because requirementFor floors to whole experience and thirty
		-- rebirths of rounding is not a design drift.
		expect(late / early).toBeCloseTo(1, 0.001)
	end)
end)

describe("Config.Theme", function()
	-- A theme carries presentation only: never a balancing number.
	it("names every core concept", function()
		for _, key in { "speed", "coins", "prestige", "stage", "hub" } do
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

	--[[
		The Rebirth badge is the only place the interface says which world a player is
		in, and it says it with a colour. A theme that lists fewer pairs than the game
		has worlds would leave the last ones sharing a colour with an earlier one,
		which is worse than saying nothing: it would be saying something false.
	]]
	it("dresses every world in a colour of its own", function()
		local worlds = Config.Theme.palette.worlds
		expect(#worlds).toBeGreaterThanOrEqual(#Config.Worlds)

		local seen = {}
		for _, pair in worlds do
			expect(#pair).toBe(2)
			local key = table.concat(pair[1], ",")
			expect(seen[key]).toBeNil()
			seen[key] = true
		end
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
		for _, key in { "level", "stage", "coins", "prestige", "hub" } do
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
