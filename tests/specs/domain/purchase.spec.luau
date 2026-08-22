--!nocheck
local Purchase = require(Domain.Economy.Purchase)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local Profile = require(Domain.Profile.Profile)

local DEFINITIONS = {
	{
		id = "speedGain",
		name = "Foulee",
		icon = "👟",
		maxLevel = 2,
		baseCost = 100,
		costGrowth = 2,
		effectPerLevel = 0.2,
		effect = "speedMultiplier",
	},
}

describe("Purchase", function()
	local catalog, profile
	beforeEach(function()
		catalog = UpgradeCatalog.new(DEFINITIONS)
		profile = Profile.create()
	end)

	it("rejette une amelioration inconnue", function()
		local result = Purchase.evaluate(catalog, profile, "jetpack")
		expect(result.ok).toBe(false)
		expect(result.code).toBe("UNKNOWN_UPGRADE")
	end)

	it("rejette un solde insuffisant", function()
		profile.bananas = 99
		local result = Purchase.evaluate(catalog, profile, "speedGain")
		expect(result.ok).toBe(false)
		expect(result.code).toBe("INSUFFICIENT_FUNDS")
		expect(result.value.missing).toBe(1)
	end)

	it("rejette un niveau deja maximal", function()
		profile.bananas = 1e9
		profile.upgrades.speedGain = 2
		local result = Purchase.evaluate(catalog, profile, "speedGain")
		expect(result.ok).toBe(false)
		expect(result.code).toBe("MAX_LEVEL")
	end)

	it("accepte un achat finançable", function()
		profile.bananas = 100
		local result = Purchase.evaluate(catalog, profile, "speedGain")
		expect(result.ok).toBe(true)
		expect(result.value.cost).toBe(100)
		expect(result.value.nextLevel).toBe(1)
	end)

	it("applique l'achat en debitant le solde", function()
		profile.bananas = 350
		local result = Purchase.apply(catalog, profile, "speedGain")
		expect(result.ok).toBe(true)
		expect(profile.bananas).toBe(250)
		expect(profile.upgrades.speedGain).toBe(1)

		Purchase.apply(catalog, profile, "speedGain")
		expect(profile.bananas).toBe(50)
		expect(profile.upgrades.speedGain).toBe(2)
	end)

	it("ne modifie rien lorsque l'achat est refuse", function()
		profile.bananas = 10
		Purchase.apply(catalog, profile, "speedGain")
		expect(profile.bananas).toBe(10)
		expect(profile.upgrades.speedGain).toBeNil()
	end)

	it("calcule le cout d'un achat en lot", function()
		profile.bananas = 1000
		local plan = Purchase.planBulk(catalog, profile, "speedGain", 10)
		expect(plan.affordableLevels).toBe(2) -- 100 + 200, puis niveau max atteint
		expect(plan.totalCost).toBe(300)
	end)
end)
