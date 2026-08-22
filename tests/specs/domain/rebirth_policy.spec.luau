--!nocheck
local RebirthPolicy = require(Domain.Rebirth.RebirthPolicy)
local Profile = require(Domain.Profile.Profile)

local TUNING = {
	baseRequirement = 2500,
	requirementGrowth = 2.5,
	multiplierPerRebirth = 0.35,
	resetsUpgrades = true,
	keptBananaRatio = 0,
}

describe("RebirthPolicy", function()
	local policy
	beforeEach(function()
		policy = RebirthPolicy.new(TUNING)
	end)

	it("fait croitre le seuil geometriquement", function()
		expect(policy:requirementFor(0)).toBe(2500)
		expect(policy:requirementFor(1)).toBe(6250)
		expect(policy:requirementFor(2)).toBe(15625)
	end)

	it("calcule le multiplicateur permanent", function()
		expect(policy:multiplierFor(0)).toBe(1)
		expect(policy:multiplierFor(4)).toBeCloseTo(2.4, 1e-9)
	end)

	it("refuse la renaissance sous le seuil", function()
		local profile = Profile.create()
		profile.speed = 2499
		local result = policy:evaluate(profile)
		expect(result.ok).toBe(false)
		expect(result.code).toBe("SPEED_TOO_LOW")
	end)

	it("autorise la renaissance au seuil exact", function()
		local profile = Profile.create()
		profile.speed = 2500
		local result = policy:evaluate(profile)
		expect(result.ok).toBe(true)
		expect(result.value.nextRebirths).toBe(1)
		expect(result.value.nextMultiplier).toBeCloseTo(1.35, 1e-9)
	end)

	it("remet a zero la progression et incremente le compteur", function()
		local profile = Profile.create()
		profile.speed = 9000
		profile.bananas = 4000
		profile.upgrades.speedGain = 5
		profile.highestZone = 6
		profile.totals.steps = 12345

		policy:apply(profile)

		expect(profile.speed).toBe(0)
		expect(profile.bananas).toBe(0)
		expect(profile.rebirths).toBe(1)
		expect(profile.upgrades).toEqual({})
		expect(profile.highestZone).toBe(1)
		expect(profile.totals.steps).toBe(12345) -- les statistiques a vie survivent
		expect(profile.totals.rebirths).toBe(1)
	end)

	it("peut conserver les ameliorations si la regle le prevoit", function()
		local lenient = RebirthPolicy.new({
			baseRequirement = 100,
			requirementGrowth = 2,
			multiplierPerRebirth = 0.5,
			resetsUpgrades = false,
			keptBananaRatio = 0.25,
		})
		local profile = Profile.create()
		profile.speed = 500
		profile.bananas = 400
		profile.upgrades.speedGain = 5

		lenient:apply(profile)

		expect(profile.upgrades.speedGain).toBe(5)
		expect(profile.bananas).toBe(100)
	end)

	it("indique la progression vers la prochaine renaissance", function()
		local profile = Profile.create()
		profile.speed = 1250
		expect(policy:progressFor(profile)).toBeCloseTo(0.5, 1e-9)
		profile.speed = 99999
		expect(policy:progressFor(profile)).toBe(1)
	end)
end)
