--!nocheck
local Purchase = require(Domain.Economy.Purchase)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local Profile = require(Domain.Profile.Profile)

local DEFINITIONS = {
	{
		id = "speedGain",
		name = "Stride",
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

	it("rejects an unknown upgrade", function()
		expect(Purchase.evaluate(catalog, profile, "jetpack").code).toBe("UNKNOWN_UPGRADE")
	end)

	it("rejects an insufficient balance", function()
		profile.coins = 99
		local result = Purchase.evaluate(catalog, profile, "speedGain")
		expect(result.code).toBe("INSUFFICIENT_FUNDS")
		expect(result.value.missing).toBe(1)
	end)

	it("rejects a maxed out upgrade", function()
		profile.coins = 1e9
		profile.upgrades.speedGain = 2
		expect(Purchase.evaluate(catalog, profile, "speedGain").code).toBe("MAX_LEVEL")
	end)

	it("accepts an affordable purchase", function()
		profile.coins = 100
		local result = Purchase.evaluate(catalog, profile, "speedGain")
		expect(result.ok).toBe(true)
		expect(result.value.cost).toBe(100)
		expect(result.value.nextLevel).toBe(1)
	end)

	it("spends the coins when applied", function()
		profile.coins = 350
		Purchase.apply(catalog, profile, "speedGain")
		expect(profile.coins).toBe(250)
		expect(profile.upgrades.speedGain).toBe(1)

		Purchase.apply(catalog, profile, "speedGain")
		expect(profile.coins).toBe(50)
		expect(profile.upgrades.speedGain).toBe(2)
	end)

	it("changes nothing when the purchase is refused", function()
		profile.coins = 10
		Purchase.apply(catalog, profile, "speedGain")
		expect(profile.coins).toBe(10)
		expect(profile.upgrades.speedGain).toBeNil()
	end)

	it("plans a bulk purchase without touching the profile", function()
		profile.coins = 1000
		local plan = Purchase.planBulk(catalog, profile, "speedGain", 10)
		expect(plan.affordableLevels).toBe(2)
		expect(plan.totalCost).toBe(300)
		expect(profile.coins).toBe(1000)
	end)
end)
