--!nocheck
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)

local DEFINITIONS = {
	{
		id = "speedGain",
		name = "Foulee du singe",
		icon = "👟",
		maxLevel = 3,
		baseCost = 100,
		costGrowth = 2,
		effectPerLevel = 0.2,
		effect = "speedMultiplier",
	},
	{
		id = "bananaGain",
		name = "Flair a bananes",
		icon = "🍌",
		maxLevel = 0, -- 0 = illimite
		baseCost = 50,
		costGrowth = 1.5,
		effectPerLevel = 0.1,
		effect = "bananaMultiplier",
	},
}

describe("UpgradeCatalog", function()
	local catalog
	beforeEach(function()
		catalog = UpgradeCatalog.new(DEFINITIONS)
	end)

	it("liste les identifiants dans l'ordre de definition", function()
		expect(catalog:ids()).toEqual({ "speedGain", "bananaGain" })
	end)

	it("retrouve une definition", function()
		expect(catalog:get("speedGain").name).toBe("Foulee du singe")
		expect(catalog:get("inconnu")).toBeNil()
	end)

	it("calcule un cout geometrique a partir du niveau courant", function()
		expect(catalog:costFor("speedGain", 0)).toBe(100)
		expect(catalog:costFor("speedGain", 1)).toBe(200)
		expect(catalog:costFor("speedGain", 2)).toBe(400)
	end)

	it("arrondit les couts a l'entier inferieur", function()
		expect(catalog:costFor("bananaGain", 1)).toBe(75)
		expect(catalog:costFor("bananaGain", 3)).toBe(168)
	end)

	it("detecte le niveau maximum", function()
		expect(catalog:isMaxed("speedGain", 2)).toBe(false)
		expect(catalog:isMaxed("speedGain", 3)).toBe(true)
		expect(catalog:isMaxed("bananaGain", 9999)).toBe(false)
	end)

	it("cumule l'effet lineairement", function()
		expect(catalog:effectFor("speedGain", 0)).toBe(0)
		expect(catalog:effectFor("speedGain", 3)).toBeCloseTo(0.6, 1e-9)
	end)

	it("refuse deux definitions avec le meme identifiant", function()
		expect(function()
			UpgradeCatalog.new({ DEFINITIONS[1], DEFINITIONS[1] })
		end).toThrow("speedGain")
	end)
end)
