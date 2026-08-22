--!nocheck
local ZoneLadder = require(Domain.Zones.ZoneLadder)

local ZONES = {
	{ id = 1, name = "Clairiere", requiredSpeed = 0, stepMultiplier = 1, bananaMultiplier = 1 },
	{ id = 2, name = "Canopee", requiredSpeed = 250, stepMultiplier = 1.5, bananaMultiplier = 2 },
	{ id = 3, name = "Ravin", requiredSpeed = 900, stepMultiplier = 2.2, bananaMultiplier = 3.5 },
}

describe("ZoneLadder", function()
	local ladder
	beforeEach(function()
		ladder = ZoneLadder.new(ZONES)
	end)

	it("compte les zones", function()
		expect(ladder:count()).toBe(3)
	end)

	it("retourne une zone par identifiant", function()
		expect(ladder:get(2).name).toBe("Canopee")
		expect(ladder:get(99)).toBeNil()
	end)

	it("determine la zone la plus haute accessible", function()
		expect(ladder:highestUnlocked(0)).toBe(1)
		expect(ladder:highestUnlocked(249)).toBe(1)
		expect(ladder:highestUnlocked(250)).toBe(2)
		expect(ladder:highestUnlocked(50000)).toBe(3)
	end)

	it("verifie l'acces a une zone donnee", function()
		expect(ladder:isUnlocked(3, 900)).toBe(true)
		expect(ladder:isUnlocked(3, 899)).toBe(false)
		expect(ladder:isUnlocked(99, 1e9)).toBe(false)
	end)

	it("expose la zone suivante et son cout d'entree", function()
		expect(ladder:nextOf(1).id).toBe(2)
		expect(ladder:nextOf(3)).toBeNil()
		expect(ladder:requirementOf(2)).toBe(250)
	end)

	it("mesure la progression vers la zone suivante", function()
		expect(ladder:progressToNext(1, 125)).toBeCloseTo(0.5, 1e-9)
		expect(ladder:progressToNext(2, 900)).toBe(1)
		expect(ladder:progressToNext(3, 1e9)).toBe(1)
	end)

	it("refuse une echelle non croissante", function()
		expect(function()
			ZoneLadder.new({
				{ id = 1, requiredSpeed = 100, stepMultiplier = 1, bananaMultiplier = 1 },
				{ id = 2, requiredSpeed = 50, stepMultiplier = 1, bananaMultiplier = 1 },
			})
		end).toThrow("croissant")
	end)
end)
