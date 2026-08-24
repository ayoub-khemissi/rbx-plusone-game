--!nocheck
local Purchase = require(Domain.Economy.Purchase)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local Profile = require(Domain.Profile.Profile)

local DEFINITIONS = {
	{
		id = "speedGain",
		name = "Wingbeat",
		icon = "💨",
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
		profile.gold = 99
		local result = Purchase.evaluate(catalog, profile, "speedGain")
		expect(result.code).toBe("INSUFFICIENT_FUNDS")
		expect(result.value.missing).toBe(1)
	end)

	it("rejects a maxed out upgrade", function()
		profile.gold = 1e9
		profile.upgrades.speedGain = 2
		expect(Purchase.evaluate(catalog, profile, "speedGain").code).toBe("MAX_LEVEL")
	end)

	it("accepts an affordable purchase", function()
		profile.gold = 100
		local result = Purchase.evaluate(catalog, profile, "speedGain")
		expect(result.ok).toBe(true)
		expect(result.value.cost).toBe(100)
		expect(result.value.nextLevel).toBe(1)
	end)

	it("spends the gold when applied", function()
		profile.gold = 350
		Purchase.apply(catalog, profile, "speedGain")
		expect(profile.gold).toBe(250)
		expect(profile.upgrades.speedGain).toBe(1)

		Purchase.apply(catalog, profile, "speedGain")
		expect(profile.gold).toBe(50)
		expect(profile.upgrades.speedGain).toBe(2)
	end)

	it("changes nothing when the purchase is refused", function()
		profile.gold = 10
		Purchase.apply(catalog, profile, "speedGain")
		expect(profile.gold).toBe(10)
		expect(profile.upgrades.speedGain).toBeNil()
	end)

	it("plans a bulk purchase without touching the profile", function()
		profile.gold = 1000
		local plan = Purchase.planBulk(catalog, profile, "speedGain", 10)
		expect(plan.affordableLevels).toBe(2)
		expect(plan.totalCost).toBe(300)
		expect(profile.gold).toBe(1000)
	end)
end)
