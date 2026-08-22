--!nocheck
local Progression = require(Domain.Progression.Progression)
local SpeedCurve = require(Domain.Progression.SpeedCurve)
local MovementAccounting = require(Domain.Progression.MovementAccounting)
local Multipliers = require(Domain.Progression.Multipliers)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local RebirthPolicy = require(Domain.Rebirth.RebirthPolicy)
local Profile = require(Domain.Profile.Profile)

local DEFINITIONS = {
	{
		id = "speedGain",
		maxLevel = 0,
		baseCost = 10,
		costGrowth = 2,
		effectPerLevel = 0.5,
		effect = "speedMultiplier",
	},
	{ id = "jump", maxLevel = 0, baseCost = 10, costGrowth = 2, effectPerLevel = 1, effect = "jumpPower" },
}

local function buildProgression()
	local catalog = UpgradeCatalog.new(DEFINITIONS)
	local rebirthPolicy = RebirthPolicy.new({
		baseRequirement = 1000,
		requirementGrowth = 2,
		multiplierPerRebirth = 1,
		resetsUpgrades = true,
	})
	return Progression.new({
		curve = SpeedCurve.new({
			baseWalkSpeed = 16,
			maxBonusWalkSpeed = 234,
			softness = 900,
			baseJumpPower = 50,
			jumpPowerPerLevel = 4,
			maxJumpPower = 140,
		}),
		accounting = MovementAccounting.new({
			studsPerStep = 4,
			deadzone = 0.15,
			toleranceFactor = 1.35,
			minimumSpeedAllowance = 16,
		}),
		multipliers = Multipliers.new({
			catalog = catalog,
			rebirthPolicy = rebirthPolicy,
			passEffects = { doubleSpeed = { speed = 2 } },
		}),
		tuning = { speedPerStep = 1, bananasPerStep = 0.5 },
	})
end

local ZONE = { id = 1, stepMultiplier = 1, bananaMultiplier = 1 }

describe("Progression", function()
	local progression, profile
	beforeEach(function()
		progression = buildProgression()
		profile = Profile.create()
	end)

	it("convertit un deplacement en vitesse et en bananes", function()
		local outcome = progression:advance(profile, {
			distance = 40,
			deltaTime = 1,
			currentWalkSpeed = 50,
			zone = ZONE,
			passes = {},
		})

		expect(outcome.steps).toBe(10)
		expect(outcome.speedGained).toBe(10)
		expect(outcome.bananasGained).toBe(5)
		expect(profile.speed).toBe(10)
		expect(profile.bananas).toBe(5)
	end)

	it("cumule les statistiques a vie", function()
		progression:advance(
			profile,
			{ distance = 40, deltaTime = 1, currentWalkSpeed = 50, zone = ZONE, passes = {} }
		)
		progression:advance(
			profile,
			{ distance = 40, deltaTime = 1, currentWalkSpeed = 50, zone = ZONE, passes = {} }
		)
		expect(profile.totals.steps).toBe(20)
		expect(profile.totals.distance).toBe(80)
	end)

	it("applique les multiplicateurs au gain", function()
		profile.upgrades.speedGain = 2 -- x2
		profile.rebirths = 1 -- x2
		local outcome = progression:advance(profile, {
			distance = 40,
			deltaTime = 1,
			currentWalkSpeed = 50,
			zone = { id = 2, stepMultiplier = 1.5, bananaMultiplier = 1 },
			passes = { doubleSpeed = true },
		})
		expect(outcome.speedGained).toBeCloseTo(10 * 2 * 2 * 1.5 * 2, 1e-9)
	end)

	it("renvoie l'etat de mouvement a appliquer au personnage", function()
		profile.speed = 900
		profile.upgrades.jump = 5
		local outcome = progression:advance(profile, {
			distance = 0,
			deltaTime = 0.1,
			currentWalkSpeed = 16,
			zone = ZONE,
			passes = {},
		})
		expect(outcome.movement.walkSpeed).toBeCloseTo(16 + 234 * (1 - math.exp(-1)), 0.01)
		expect(outcome.movement.jumpPower).toBe(70)
		expect(outcome.movement.wallGrip).toBe(0)
	end)

	it("n'accorde aucun gain sur un deplacement plafonne a zero", function()
		local outcome = progression:advance(profile, {
			distance = 0,
			deltaTime = 0.1,
			currentWalkSpeed = 16,
			zone = ZONE,
			passes = {},
		})
		expect(outcome.speedGained).toBe(0)
		expect(profile.speed).toBe(0)
	end)

	it("signale une mesure suspecte sans crediter la distance complete", function()
		local outcome = progression:advance(profile, {
			distance = 10000,
			deltaTime = 0.1,
			currentWalkSpeed = 16,
			zone = ZONE,
			passes = {},
		})
		expect(outcome.clamped).toBe(true)
		expect(outcome.speedGained).toBeLessThan(1)
	end)

	it("met a jour la plus haute zone atteinte", function()
		progression:noteZone(profile, 4)
		expect(profile.highestZone).toBe(4)
		progression:noteZone(profile, 2)
		expect(profile.highestZone).toBe(4)
	end)
end)
