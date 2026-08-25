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

		-- At the Prestige threshold: fast, and still short of the ceiling, so the
		-- levels after it still have something to give. The hard limit is the 60
		-- below; this bound is the headroom.
		local prestige = PrestigePolicy.new(Config.Balance.prestige):requirementFor(0)
		expect(curve:walkSpeedFor(levels:levelFor(prestige))).toBeLessThan(55)

		-- And the ceiling stays well under what the physics stops tolerating.
		expect(curve:walkSpeedFor(1e12)).toBeLessThanOrEqual(60)
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

	-- Prestige must mean "I finished the course", not "I played a bit".
	it("asks for the last stage before the first prestige", function()
		local policy = PrestigePolicy.new(Config.Balance.prestige)
		expect(policy:requirementFor(0)).toBeGreaterThanOrEqual(Config.Stages[#Config.Stages].requiredSpeed)
		expect(policy:multiplierFor(1)).toBeGreaterThan(1)
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

	it("points every offer at a product that exists", function()
		local catalog = ProductCatalog.new(Config.Products)
		for _, offer in Config.Monetization.offers do
			expect(catalog:get(offer.productKey)).never.toBeNil()
		end
	end)
end)
