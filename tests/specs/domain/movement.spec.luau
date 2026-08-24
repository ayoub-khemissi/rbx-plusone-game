--!nocheck
local SpeedCurve = require(Domain.Movement.SpeedCurve)
local MovementAccounting = require(Domain.Movement.MovementAccounting)
local JumpBudget = require(Domain.Movement.JumpBudget)
local DashPolicy = require(Domain.Movement.DashPolicy)
local Multipliers = require(Domain.Movement.Multipliers)
local Progression = require(Domain.Movement.Progression)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local PrestigePolicy = require(Domain.Prestige.PrestigePolicy)
local Profile = require(Domain.Profile.Profile)

local CURVE_TUNING = {
	baseWalkSpeed = 16,
	maxBonusWalkSpeed = 234,
	softness = 1200,
	baseJumpPower = 50,
	jumpPowerPerLevel = 3,
	maxJumpPower = 140,
}

local ACCOUNTING_TUNING = {
	studsPerStep = 4,
	deadzone = 0.15,
	toleranceFactor = 1.4,
	minimumSpeedAllowance = 16,
}

describe("SpeedCurve", function()
	local curve
	beforeEach(function()
		curve = SpeedCurve.new(CURVE_TUNING)
	end)

	it("starts at the base walk speed", function()
		expect(curve:walkSpeedFor(0)).toBe(16)
	end)

	it("rises monotonically", function()
		local previous = curve:walkSpeedFor(0)
		for speed = 50, 5000, 50 do
			local current = curve:walkSpeedFor(speed)
			expect(current).toBeGreaterThan(previous)
			previous = current
		end
	end)

	-- Au-dela, le personnage traverse le sol et rate les plateformes.
	it("saturates under the physics ceiling", function()
		local ceiling = CURVE_TUNING.baseWalkSpeed + CURVE_TUNING.maxBonusWalkSpeed
		expect(curve:walkSpeedFor(1e12)).toBeLessThanOrEqual(ceiling)
		expect(curve:walkSpeedFor(1e12)).toBeGreaterThan(ceiling - 0.001)
	end)

	it("treats invalid speeds as zero", function()
		expect(curve:walkSpeedFor(-500)).toBe(16)
		expect(curve:walkSpeedFor(0 / 0)).toBe(16)
	end)

	it("turns jump levels into jump power", function()
		expect(curve:jumpPowerFor(0)).toBe(50)
		expect(curve:jumpPowerFor(5)).toBe(65)
		expect(curve:jumpPowerFor(1000)).toBe(140)
	end)
end)

describe("MovementAccounting", function()
	local accounting
	beforeEach(function()
		accounting = MovementAccounting.new(ACCOUNTING_TUNING)
	end)

	it("turns ground distance into steps", function()
		local reading = accounting:measure(40, 1, 50)
		expect(reading.steps).toBe(10)
		expect(reading.clamped).toBe(false)
	end)

	it("ignores jitter under the deadzone", function()
		expect(accounting:measure(0.1, 0.1, 50).steps).toBe(0)
	end)

	it("clamps impossible displacement", function()
		local reading = accounting:measure(5000, 0.1, 50)
		expect(reading.clamped).toBe(true)
		expect(reading.distance).toBeCloseTo(50 * 1.4 * 0.1, 1e-6)
	end)

	it("gives slow players a floor allowance", function()
		expect(accounting:measure(500, 1, 0).distance).toBeCloseTo(16 * 1.4, 1e-6)
	end)

	it("refuses null or negative time steps", function()
		expect(accounting:measure(10, 0, 50).steps).toBe(0)
		expect(accounting:measure(10, -1, 50).steps).toBe(0)
	end)

	-- Sauter n'est pas courir : la composante verticale ne rapporte rien.
	it("measures ground distance only", function()
		expect(accounting:distanceBetween({ x = 0, y = 0, z = 0 }, { x = 3, y = 99, z = 4 })).toBe(5)
	end)
end)

describe("JumpBudget", function()
	local budget, state
	beforeEach(function()
		budget = JumpBudget.new({ maxJumpLevel = 3 })
		state = JumpBudget.newState()
	end)

	-- Le domaine parle en NIVEAUX, comme le joueur : niveau 1 = un saut, niveau 3 =
	-- triple saut. Les "sauts aeriens" ne sont qu'une soustraction.
	it("starts every character at jump level 1", function()
		expect(budget:levelFor({ flat = {} })).toBe(1)
		expect(budget:capacityFor({ flat = {} })).toBe(0)
	end)

	it("turns bought levels into jump levels", function()
		expect(budget:levelFor({ flat = { jumps = 1 } })).toBe(2)
		expect(budget:levelFor({ flat = { jumps = 2 } })).toBe(3)
		expect(budget:capacityFor({ flat = { jumps = 2 } })).toBe(2)
	end)

	-- Le plafond protege le level design : un joueur qui vole rendrait les trous inutiles.
	it("caps the level whatever the upgrades say", function()
		expect(budget:levelFor({ flat = { jumps = 99 } })).toBe(3)
		expect(budget:capacityFor({ flat = { jumps = 99 } })).toBe(2)
	end)

	it("spends the air jumps one by one", function()
		expect(budget:tryConsume(state, 2)).toBe(true)
		expect(budget:tryConsume(state, 2)).toBe(true)
		expect(budget:tryConsume(state, 2)).toBe(false)
	end)

	it("reports what is left", function()
		expect(budget:remaining(state, 2)).toBe(2)
		budget:tryConsume(state, 2)
		expect(budget:remaining(state, 2)).toBe(1)
	end)

	it("refills on landing", function()
		budget:tryConsume(state, 1)
		budget:land(state)
		expect(budget:tryConsume(state, 1)).toBe(true)
	end)

	it("never goes negative when the capacity drops", function()
		budget:tryConsume(state, 2)
		budget:tryConsume(state, 2)
		expect(budget:remaining(state, 0)).toBe(0)
	end)
end)

describe("DashPolicy", function()
	local dash, state

	local TUNING = {
		maxLevel = 3,
		basePower = 60,
		powerPerLevel = 30,
		cooldown = 2,
	}

	beforeEach(function()
		dash = DashPolicy.new(TUNING)
		state = DashPolicy.newState()
	end)

	it("gives no dash before it is bought", function()
		expect(dash:levelFor({ flat = {} })).toBe(0)
		expect(dash:powerFor(0)).toBe(0)
		expect(dash:tryConsume(state, 0, 100)).toBe(0)
	end)

	-- Le niveau de dash EST sa puissance : c'est ce que le joueur achete.
	it("turns the level into raw power", function()
		expect(dash:powerFor(1)).toBe(60)
		expect(dash:powerFor(2)).toBe(90)
		expect(dash:powerFor(3)).toBe(120)
	end)

	it("caps the level whatever the upgrades say", function()
		expect(dash:levelFor({ flat = { dash = 99 } })).toBe(3)
	end)

	it("returns the power spent on a successful dash", function()
		expect(dash:tryConsume(state, 2, 100)).toBe(90)
	end)

	it("refuses a second dash before the cooldown", function()
		dash:tryConsume(state, 1, 100)
		expect(dash:tryConsume(state, 1, 101)).toBe(0)
		expect(dash:tryConsume(state, 1, 102)).toBe(60)
	end)

	it("reports the cooldown left, for the interface", function()
		dash:tryConsume(state, 1, 100)
		expect(dash:remainingCooldown(state, 100.5)).toBeCloseTo(1.5, 1e-9)
		expect(dash:remainingCooldown(state, 999)).toBe(0)
	end)

	it("ignores a nonsensical clock", function()
		expect(dash:tryConsume(state, 1, 0 / 0)).toBe(0)
	end)
end)

local UPGRADES = {
	{
		id = "speedGain",
		maxLevel = 0,
		baseCost = 10,
		costGrowth = 2,
		effectPerLevel = 0.25,
		effect = "speedMultiplier",
	},
	{
		id = "coinGain",
		maxLevel = 0,
		baseCost = 10,
		costGrowth = 2,
		effectPerLevel = 0.5,
		effect = "coinMultiplier",
	},
	{
		id = "jumpPower",
		maxLevel = 0,
		baseCost = 10,
		costGrowth = 2,
		effectPerLevel = 1,
		effect = "jumpPower",
	},
	{ id = "jump", maxLevel = 2, baseCost = 10, costGrowth = 2, effectPerLevel = 1, effect = "jumps" },
	{ id = "dash", maxLevel = 3, baseCost = 10, costGrowth = 2, effectPerLevel = 1, effect = "dash" },
}

local PASS_EFFECTS = {
	doubleCoins = { coins = 2 },
	swiftBoots = { speed = 1.5, flat = { jumpPower = 5 } },
}

local function buildMultipliers()
	return Multipliers.new({
		catalog = UpgradeCatalog.new(UPGRADES),
		prestigePolicy = PrestigePolicy.new({
			baseRequirement = 100,
			requirementGrowth = 2,
			multiplierPerPrestige = 0.5,
			resetsUpgrades = true,
		}),
		passEffects = PASS_EFFECTS,
	})
end

describe("Multipliers", function()
	local multipliers, profile
	beforeEach(function()
		multipliers = buildMultipliers()
		profile = Profile.create()
	end)

	it("is neutral with nothing owned", function()
		local bonuses = multipliers:compute(profile, {})
		expect(bonuses.speed).toBe(1)
		expect(bonuses.coins).toBe(1)
		expect(bonuses.flat.jumps).toBe(0)
		expect(bonuses.flat.dash).toBe(0)
	end)

	it("adds upgrade levels together", function()
		profile.upgrades.speedGain = 4
		expect(multipliers:compute(profile, {}).speed).toBeCloseTo(2, 1e-9)
	end)

	it("multiplies by the prestige bonus", function()
		profile.prestiges = 2
		expect(multipliers:compute(profile, {}).speed).toBeCloseTo(2, 1e-9)
	end)

	it("applies the stage coin multiplier", function()
		local bonuses = multipliers:compute(profile, { stage = { coinMultiplier = 3 } })
		expect(bonuses.coins).toBe(3)
		expect(bonuses.speed).toBe(1)
	end)

	it("applies passes and boosts", function()
		local bonuses = multipliers:compute(profile, {
			passes = { doubleCoins = true, swiftBoots = true },
			boosts = { speed = 2 },
		})
		expect(bonuses.coins).toBe(2)
		expect(bonuses.speed).toBeCloseTo(1.5 * 2, 1e-9)
		expect(bonuses.flat.jumpPower).toBe(5)
	end)

	it("collects flat upgrade effects", function()
		profile.upgrades.jumpPower = 3
		profile.upgrades.jump = 2
		profile.upgrades.dash = 3
		local bonuses = multipliers:compute(profile, {})
		expect(bonuses.flat.jumpPower).toBe(3)
		expect(bonuses.flat.jumps).toBe(2)
		expect(bonuses.flat.dash).toBe(3)
	end)
end)

describe("Progression", function()
	local progression, profile

	local function context(overrides)
		local base = { distance = 40, deltaTime = 1, currentWalkSpeed = 50 }
		for key, value in overrides or {} do
			base[key] = value
		end
		return base
	end

	beforeEach(function()
		progression = Progression.new({
			curve = SpeedCurve.new(CURVE_TUNING),
			accounting = MovementAccounting.new(ACCOUNTING_TUNING),
			multipliers = buildMultipliers(),
			jumpBudget = JumpBudget.new({ maxJumpLevel = 3 }),
			dashPolicy = DashPolicy.new({ maxLevel = 3, basePower = 60, powerPerLevel = 30, cooldown = 2 }),
			tuning = { speedPerStep = 1, coinsPerStep = 0.5 },
		})
		profile = Profile.create()
	end)

	it("credits speed and coins to the profile", function()
		local outcome = progression:advance(profile, context())

		expect(outcome.steps).toBe(10)
		expect(profile.speed).toBe(10)
		expect(profile.coins).toBe(5)
	end)

	it("accumulates lifetime statistics", function()
		progression:advance(profile, context())
		progression:advance(profile, context())
		expect(profile.totals.distance).toBe(80)
	end)

	it("applies every multiplier to the gains", function()
		profile.upgrades.speedGain = 2
		profile.prestiges = 1
		local outcome = progression:advance(profile, context({ passes = { swiftBoots = true } }))
		expect(outcome.speedGained).toBeCloseTo(10 * 1.5 * 1.5 * 1.5, 1e-9)
	end)

	it("returns the movement state to apply to the character", function()
		profile.speed = 1200
		profile.upgrades.jumpPower = 5
		local outcome = progression:advance(profile, context({ distance = 0 }))

		expect(outcome.movement.walkSpeed).toBeCloseTo(16 + 234 * (1 - math.exp(-1)), 0.01)
		expect(outcome.movement.jumpPower).toBe(65)
		expect(outcome.movement.jumpLevel).toBe(1)
		expect(outcome.movement.dashLevel).toBe(0)
	end)

	it("gains nothing from an impossible jump", function()
		local outcome = progression:advance(profile, context({ distance = 1e6, deltaTime = 0.1 }))
		expect(outcome.clamped).toBe(true)
		expect(profile.speed).toBeLessThan(2)
	end)

	it("credits a coin pickup with the coin multipliers", function()
		profile.upgrades.coinGain = 2 -- +100%
		local granted = progression:collectCoin(profile, 50, {})
		expect(granted).toBeCloseTo(100, 1e-9)
		expect(profile.coins).toBeCloseTo(100, 1e-9)
	end)

	it("remembers the deepest stage reached", function()
		expect(progression:noteStage(profile, 4)).toBe(true)
		expect(profile.highestStage).toBe(4)
		expect(progression:noteStage(profile, 2)).toBe(false)
		expect(profile.highestStage).toBe(4)
	end)
end)
