--!nocheck
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)

local DEFINITIONS = {
	{
		id = "speedGain",
		name = "Wingbeat",
		icon = "💨",
		maxLevel = 3,
		baseCost = 100,
		costGrowth = 2,
		effectPerLevel = 0.2,
		effect = "speedMultiplier",
	},
	{
		id = "goldGain",
		name = "Gold Sense",
		icon = "🪙",
		maxLevel = 0, -- 0 = unlimited
		baseCost = 50,
		costGrowth = 1.5,
		effectPerLevel = 0.1,
		effect = "goldMultiplier",
	},
}

describe("UpgradeCatalog", function()
	local catalog
	beforeEach(function()
		catalog = UpgradeCatalog.new(DEFINITIONS)
	end)

	it("lists ids in definition order", function()
		expect(catalog:ids()).toEqual({ "speedGain", "goldGain" })
	end)

	it("finds a definition", function()
		expect(catalog:get("speedGain").name).toBe("Wingbeat")
		expect(catalog:get("inconnu")).toBeNil()
	end)

	it("computes a geometric cost from the current level", function()
		expect(catalog:costFor("speedGain", 0)).toBe(100)
		expect(catalog:costFor("speedGain", 1)).toBe(200)
		expect(catalog:costFor("speedGain", 2)).toBe(400)
	end)

	it("floors the costs", function()
		expect(catalog:costFor("goldGain", 1)).toBe(75)
		expect(catalog:costFor("goldGain", 3)).toBe(168)
	end)

	it("detects the maximum level", function()
		expect(catalog:isMaxed("speedGain", 2)).toBe(false)
		expect(catalog:isMaxed("speedGain", 3)).toBe(true)
		expect(catalog:isMaxed("goldGain", 9999)).toBe(false)
	end)

	it("stacks the effect linearly", function()
		expect(catalog:effectFor("speedGain", 0)).toBe(0)
		expect(catalog:effectFor("speedGain", 3)).toBeCloseTo(0.6, 1e-9)
	end)

	it("refuses two definitions sharing an id", function()
		expect(function()
			UpgradeCatalog.new({ DEFINITIONS[1], DEFINITIONS[1] })
		end).toThrow("speedGain")
	end)
end)
