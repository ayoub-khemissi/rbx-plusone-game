--!nocheck
local SpeedCurve = require(Domain.Flight.SpeedCurve)
local FlightAccounting = require(Domain.Flight.FlightAccounting)
local Multipliers = require(Domain.Flight.Multipliers)
local Progression = require(Domain.Flight.Progression)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local MoltPolicy = require(Domain.Molt.MoltPolicy)
local Pouch = require(Domain.Run.Pouch)
local Profile = require(Domain.Profile.Profile)

local CURVE_TUNING = {
	baseVelocity = 60,
	maxBonusVelocity = 240,
	softness = 1200,
	baseAgility = 1,
	agilityPerLevel = 0.12,
	maxAgility = 4,
}

local ACCOUNTING_TUNING = {
	studsPerStep = 8,
	deadzone = 0.2,
	toleranceFactor = 1.4,
	minimumSpeedAllowance = 60,
}

describe("SpeedCurve", function()
	local curve
	beforeEach(function()
		curve = SpeedCurve.new(CURVE_TUNING)
	end)

	it("starts at the hatchling velocity", function()
		expect(curve:velocityFor(0)).toBe(60)
	end)

	it("rises monotonically", function()
		local previous = curve:velocityFor(0)
		for speed = 50, 5000, 50 do
			local current = curve:velocityFor(speed)
			expect(current).toBeGreaterThan(previous)
			previous = current
		end
	end)

	-- Au-dela, le personnage traverse les murs avant que la collision ne soit vue.
	it("saturates under the physics ceiling", function()
		local ceiling = CURVE_TUNING.baseVelocity + CURVE_TUNING.maxBonusVelocity
		expect(curve:velocityFor(1e12)).toBeLessThanOrEqual(ceiling)
		expect(curve:velocityFor(1e12)).toBeGreaterThan(ceiling - 0.001)
	end)

	it("treats invalid speeds as zero", function()
		expect(curve:velocityFor(-500)).toBe(60)
		expect(curve:velocityFor(0 / 0)).toBe(60)
	end)

	it("turns agility levels into a turn rate", function()
		expect(curve:agilityFor(0)).toBe(1)
		expect(curve:agilityFor(5)).toBeCloseTo(1.6, 1e-9)
		expect(curve:agilityFor(1000)).toBe(4)
	end)

	it("exposes saturation for the interface", function()
		expect(curve:saturationFor(0)).toBe(0)
		expect(curve:saturationFor(1e12)).toBeCloseTo(1, 0.001)
	end)
end)

describe("FlightAccounting", function()
	local accounting
	beforeEach(function()
		accounting = FlightAccounting.new(ACCOUNTING_TUNING)
	end)

	it("turns distance flown into steps", function()
		local reading = accounting:measure(80, 1, 100)
		expect(reading.steps).toBe(10)
		expect(reading.clamped).toBe(false)
	end)

	it("ignores jitter under the deadzone", function()
		expect(accounting:measure(0.1, 0.1, 100).steps).toBe(0)
	end)

	-- Anti-triche : le serveur mesure, puis plafonne a ce qui est atteignable.
	it("clamps impossible displacement", function()
		local reading = accounting:measure(5000, 0.1, 100)
		expect(reading.clamped).toBe(true)
		expect(reading.distance).toBeCloseTo(100 * 1.4 * 0.1, 1e-6)
	end)

	it("gives slow dragons a floor allowance", function()
		expect(accounting:measure(500, 1, 0).distance).toBeCloseTo(60 * 1.4, 1e-6)
	end)

	it("refuses null or negative time steps", function()
		expect(accounting:measure(10, 0, 100).steps).toBe(0)
		expect(accounting:measure(10, -1, 100).steps).toBe(0)
	end)

	-- En vol, contrairement a la course, monter EST un deplacement qui compte.
	it("measures distance in three dimensions", function()
		local distance = accounting:distanceBetween({ x = 0, y = 0, z = 0 }, { x = 3, y = 4, z = 0 })
		expect(distance).toBe(5)
		expect(accounting:distanceBetween({ x = 0, y = 0, z = 0 }, { x = 0, y = 12, z = 0 })).toBe(12)
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
		id = "goldGain",
		maxLevel = 0,
		baseCost = 10,
		costGrowth = 2,
		effectPerLevel = 0.5,
		effect = "goldMultiplier",
	},
	{ id = "agility", maxLevel = 0, baseCost = 10, costGrowth = 2, effectPerLevel = 1, effect = "agility" },
	{ id = "magnet", maxLevel = 0, baseCost = 10, costGrowth = 2, effectPerLevel = 5, effect = "magnet" },
}

local PASS_EFFECTS = {
	doubleGold = { gold = 2 },
	swiftWing = { speed = 1.5, flat = { agility = 1 } },
}

local function buildMultipliers()
	return Multipliers.new({
		catalog = UpgradeCatalog.new(UPGRADES),
		moltPolicy = MoltPolicy.new({
			baseRequirement = 100,
			requirementGrowth = 2,
			multiplierPerMolt = 0.5,
			resetsUpgrades = true,
		}),
		passEffects = PASS_EFFECTS,
	})
end

describe("Multipliers", function()
	local multipliers, profile, tier
	beforeEach(function()
		multipliers = buildMultipliers()
		profile = Profile.create()
		tier = { id = 1, goldMultiplier = 1 }
	end)

	it("is neutral with nothing owned", function()
		local bonuses = multipliers:compute(profile, { passes = {} })
		expect(bonuses.speed).toBe(1)
		expect(bonuses.gold).toBe(1)
		expect(bonuses.flat.agility).toBe(0)
	end)

	it("adds upgrade levels together", function()
		profile.upgrades.speedGain = 4
		expect(multipliers:compute(profile, {}).speed).toBeCloseTo(2, 1e-9)
	end)

	it("multiplies by the molt bonus", function()
		profile.molts = 2
		expect(multipliers:compute(profile, {}).speed).toBeCloseTo(2, 1e-9)
	end)

	-- Le multiplicateur d'or du tier s'applique a l'ENCAISSEMENT, pas au ramassage :
	-- il ne doit donc pas apparaitre ici.
	it("ignores the tier gold multiplier, which belongs to banking", function()
		expect(multipliers:compute(profile, { tier = tier }).gold).toBe(1)
	end)

	it("applies gamepasses, boosts and dragons", function()
		local bonuses = multipliers:compute(profile, {
			passes = { doubleGold = true, swiftWing = true },
			boosts = { speed = 2 },
			dragons = { gold = 0.5, speed = 0.25, agility = 0.3 },
		})

		expect(bonuses.gold).toBeCloseTo(2 * 1.5, 1e-9)
		expect(bonuses.speed).toBeCloseTo(1.5 * 2 * 1.25, 1e-9)
		expect(bonuses.flat.agility).toBeCloseTo(1.3, 1e-9)
	end)

	it("collects flat upgrade effects", function()
		profile.upgrades.agility = 3
		profile.upgrades.magnet = 2
		local bonuses = multipliers:compute(profile, {})
		expect(bonuses.flat.agility).toBe(3)
		expect(bonuses.flat.magnet).toBe(10)
	end)
end)

describe("Progression", function()
	local progression, profile, pouch

	local function context(overrides)
		local base = { distance = 80, deltaTime = 1, currentVelocity = 100, passes = {} }
		for key, value in overrides or {} do
			base[key] = value
		end
		return base
	end

	beforeEach(function()
		progression = Progression.new({
			curve = SpeedCurve.new(CURVE_TUNING),
			accounting = FlightAccounting.new(ACCOUNTING_TUNING),
			multipliers = buildMultipliers(),
			tuning = { speedPerStep = 1, goldPerStep = 0.5 },
		})
		profile = Profile.create()
		pouch = Pouch.new()
	end)

	-- Le filet de securite du quitte ou double : la vitesse est acquise tout de suite.
	it("credits speed to the profile, permanently", function()
		local outcome = progression:advance(profile, pouch, context())
		expect(outcome.steps).toBe(10)
		expect(outcome.speedGained).toBe(10)
		expect(profile.speed).toBe(10)
	end)

	-- L'or, lui, reste en jeu tant qu'on n'a pas encaisse.
	it("drops gold into the pouch, not into the profile", function()
		progression:advance(profile, pouch, context())
		expect(pouch.gold).toBe(5)
		expect(profile.gold).toBe(0)
	end)

	it("accumulates lifetime statistics", function()
		progression:advance(profile, pouch, context())
		progression:advance(profile, pouch, context())
		expect(profile.totals.distance).toBe(160)
	end)

	it("applies every multiplier to the gains", function()
		profile.upgrades.speedGain = 2
		profile.molts = 1
		local outcome = progression:advance(profile, pouch, context({ passes = { swiftWing = true } }))
		expect(outcome.speedGained).toBeCloseTo(10 * 1.5 * 1.5 * 1.5, 1e-9)
	end)

	it("returns the flight state to apply to the dragon", function()
		profile.speed = 1200
		profile.upgrades.agility = 5
		local outcome = progression:advance(profile, pouch, context({ distance = 0 }))
		expect(outcome.flight.velocity).toBeCloseTo(60 + 240 * (1 - math.exp(-1)), 0.01)
		expect(outcome.flight.agility).toBeCloseTo(1.6, 1e-9)
	end)

	it("gains nothing from an impossible jump", function()
		local outcome = progression:advance(profile, pouch, context({ distance = 1e6, deltaTime = 0.1 }))
		expect(outcome.clamped).toBe(true)
		expect(profile.speed).toBeLessThan(3)
	end)

	it("credits a ring pickup straight into the pouch", function()
		local granted = progression:collectRing(profile, pouch, 100, {})
		expect(granted).toBe(100)
		expect(pouch.gold).toBe(100)
	end)

	it("scales ring value with the gold multipliers", function()
		profile.upgrades.goldGain = 2 -- +100%
		expect(progression:collectRing(profile, pouch, 100, {})).toBeCloseTo(200, 1e-9)
	end)
end)
