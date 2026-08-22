--!nocheck
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
		effectPerLevel = 0.25,
		effect = "speedMultiplier",
	},
	{
		id = "bananaGain",
		maxLevel = 0,
		baseCost = 10,
		costGrowth = 2,
		effectPerLevel = 0.5,
		effect = "bananaMultiplier",
	},
	{ id = "jump", maxLevel = 0, baseCost = 10, costGrowth = 2, effectPerLevel = 1, effect = "jumpPower" },
	{ id = "grip", maxLevel = 0, baseCost = 10, costGrowth = 2, effectPerLevel = 0.4, effect = "wallGrip" },
}

local PASS_EFFECTS = {
	doubleSpeed = { speed = 2 },
	doubleBananas = { bananas = 2 },
	superJump = { flat = { jumpPower = 10 } },
}

describe("Multipliers", function()
	local multipliers, profile, zone
	beforeEach(function()
		multipliers = Multipliers.new({
			catalog = UpgradeCatalog.new(DEFINITIONS),
			rebirthPolicy = RebirthPolicy.new({
				baseRequirement = 100,
				requirementGrowth = 2,
				multiplierPerRebirth = 0.5,
				resetsUpgrades = true,
			}),
			passEffects = PASS_EFFECTS,
		})
		profile = Profile.create()
		zone = { id = 1, stepMultiplier = 1, bananaMultiplier = 1 }
	end)

	it("vaut 1 sans amelioration, ni renaissance, ni pass", function()
		local result = multipliers:compute(profile, { zone = zone, passes = {} })
		expect(result.speed).toBe(1)
		expect(result.bananas).toBe(1)
		expect(result.flat.jumpPower).toBe(0)
		expect(result.flat.wallGrip).toBe(0)
	end)

	it("cumule les ameliorations de facon additive", function()
		profile.upgrades.speedGain = 4 -- +100%
		local result = multipliers:compute(profile, { zone = zone, passes = {} })
		expect(result.speed).toBeCloseTo(2, 1e-9)
	end)

	it("multiplie par le bonus de renaissance", function()
		profile.rebirths = 2 -- x2
		local result = multipliers:compute(profile, { zone = zone, passes = {} })
		expect(result.speed).toBeCloseTo(2, 1e-9)
		expect(result.bananas).toBeCloseTo(2, 1e-9)
	end)

	it("multiplie par les bonus de zone", function()
		local result = multipliers:compute(profile, {
			zone = { id = 3, stepMultiplier = 2.2, bananaMultiplier = 3.5 },
			passes = {},
		})
		expect(result.speed).toBeCloseTo(2.2, 1e-9)
		expect(result.bananas).toBeCloseTo(3.5, 1e-9)
	end)

	it("applique les gamepasses possedes", function()
		local result = multipliers:compute(profile, {
			zone = zone,
			passes = { doubleSpeed = true, doubleBananas = true, superJump = true },
		})
		expect(result.speed).toBe(2)
		expect(result.bananas).toBe(2)
		expect(result.flat.jumpPower).toBe(10)
	end)

	it("compose toutes les sources", function()
		profile.upgrades.speedGain = 4 -- x2
		profile.upgrades.bananaGain = 2 -- x2
		profile.rebirths = 2 -- x2
		local result = multipliers:compute(profile, {
			zone = { id = 2, stepMultiplier = 1.5, bananaMultiplier = 3 },
			passes = { doubleSpeed = true },
		})
		expect(result.speed).toBeCloseTo(2 * 2 * 1.5 * 2, 1e-9)
		expect(result.bananas).toBeCloseTo(2 * 2 * 3, 1e-9)
	end)

	it("agrege les effets plats des ameliorations", function()
		profile.upgrades.jump = 3
		profile.upgrades.grip = 2
		local result = multipliers:compute(profile, { zone = zone, passes = { superJump = true } })
		expect(result.flat.jumpPower).toBe(13)
		expect(result.flat.wallGrip).toBeCloseTo(0.8, 1e-9)
	end)
end)
