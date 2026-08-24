--!nocheck
local MoltPolicy = require(Domain.Molt.MoltPolicy)
local Profile = require(Domain.Profile.Profile)

local TUNING = {
	baseRequirement = 2500,
	requirementGrowth = 2.5,
	multiplierPerMolt = 0.35,
	resetsUpgrades = true,
	keptGoldRatio = 0,
}

describe("MoltPolicy", function()
	local policy
	beforeEach(function()
		policy = MoltPolicy.new(TUNING)
	end)

	it("grows the requirement geometrically", function()
		expect(policy:requirementFor(0)).toBe(2500)
		expect(policy:requirementFor(1)).toBe(6250)
		expect(policy:requirementFor(2)).toBe(15625)
	end)

	it("computes the permanent multiplier", function()
		expect(policy:multiplierFor(0)).toBe(1)
		expect(policy:multiplierFor(4)).toBeCloseTo(2.4, 1e-9)
	end)

	it("refuses to molt below the requirement", function()
		local profile = Profile.create()
		profile.speed = 2499
		expect(policy:evaluate(profile).code).toBe("SPEED_TOO_LOW")
	end)

	it("allows molting exactly at the requirement", function()
		local profile = Profile.create()
		profile.speed = 2500
		local result = policy:evaluate(profile)
		expect(result.ok).toBe(true)
		expect(result.value.nextMolts).toBe(1)
		expect(result.value.nextMultiplier).toBeCloseTo(1.35, 1e-9)
	end)

	it("resets progression and keeps lifetime statistics", function()
		local profile = Profile.create()
		profile.speed = 9000
		profile.gold = 4000
		profile.upgrades.speedGain = 5
		profile.deepestTier = 6
		profile.totals.distance = 12345

		policy:apply(profile)

		expect(profile.speed).toBe(0)
		expect(profile.gold).toBe(0)
		expect(profile.molts).toBe(1)
		expect(profile.upgrades).toEqual({})
		expect(profile.deepestTier).toBe(0)
		expect(profile.totals.distance).toBe(12345)
		expect(profile.totals.molts).toBe(1)
	end)

	-- La collection ne doit JAMAIS etre remise a zero : c'est le capital du joueur.
	it("never touches the dragon collection", function()
		local profile = Profile.create()
		profile.speed = 9000
		profile.dragons.emberling = 2
		Profile.addEggs(profile, "rare", 3)

		policy:apply(profile)

		expect(profile.dragons.emberling).toBe(2)
		expect(Profile.eggsOf(profile, "rare")).toBe(3)
	end)

	it("can keep upgrades and part of the gold when configured to", function()
		local lenient = MoltPolicy.new({
			baseRequirement = 100,
			requirementGrowth = 2,
			multiplierPerMolt = 0.5,
			resetsUpgrades = false,
			keptGoldRatio = 0.25,
		})
		local profile = Profile.create()
		profile.speed = 500
		profile.gold = 400
		profile.upgrades.speedGain = 5

		lenient:apply(profile)

		expect(profile.upgrades.speedGain).toBe(5)
		expect(profile.gold).toBe(100)
	end)

	it("reports progress towards the next molt", function()
		local profile = Profile.create()
		profile.speed = 1250
		expect(policy:progressFor(profile)).toBeCloseTo(0.5, 1e-9)
		profile.speed = 99999
		expect(policy:progressFor(profile)).toBe(1)
	end)
end)
