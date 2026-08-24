--!nocheck
local TierLadder = require(Domain.Run.TierLadder)

local TIERS = {
	{ id = 1, name = "Meadows", requiredSpeed = 0, goldMultiplier = 1, eggs = 1, maxRarity = "common" },
	{ id = 2, name = "Ruins", requiredSpeed = 150, goldMultiplier = 2, eggs = 3, maxRarity = "common" },
	{ id = 3, name = "Falls", requiredSpeed = 450, goldMultiplier = 3, eggs = 6, maxRarity = "rare" },
}

describe("TierLadder", function()
	local ladder
	beforeEach(function()
		ladder = TierLadder.new(TIERS)
	end)

	it("counts the tiers", function()
		expect(ladder:count()).toBe(3)
	end)

	it("returns a tier by id", function()
		expect(ladder:get(2).name).toBe("Ruins")
		expect(ladder:get(99)).toBeNil()
	end)

	it("gates entry behind a wind barrier", function()
		expect(ladder:isUnlocked(2, 149)).toBe(false)
		expect(ladder:isUnlocked(2, 150)).toBe(true)
		expect(ladder:isUnlocked(99, 1e9)).toBe(false)
	end)

	it("finds the deepest tier a speed can reach", function()
		expect(ladder:highestUnlocked(0)).toBe(1)
		expect(ladder:highestUnlocked(449)).toBe(2)
		expect(ladder:highestUnlocked(1e6)).toBe(3)
	end)

	it("exposes the next tier and its entry price", function()
		expect(ladder:nextOf(1).id).toBe(2)
		expect(ladder:nextOf(3)).toBeNil()
		expect(ladder:requirementOf(3)).toBe(450)
	end)

	it("measures progress towards the next barrier", function()
		expect(ladder:progressToNext(1, 75)).toBeCloseTo(0.5, 1e-9)
		expect(ladder:progressToNext(2, 450)).toBe(1)
		expect(ladder:progressToNext(3, 1e9)).toBe(1)
	end)

	it("hands out the loot of a tier", function()
		local loot = ladder:lootOf(3)
		expect(loot.eggs).toBe(6)
		expect(loot.goldMultiplier).toBe(3)
		expect(loot.maxRarity).toBe("rare")
	end)

	it("rejects a ladder whose barriers do not rise", function()
		expect(function()
			TierLadder.new({
				{ id = 1, requiredSpeed = 100, goldMultiplier = 1, eggs = 1, maxRarity = "common" },
				{ id = 2, requiredSpeed = 50, goldMultiplier = 2, eggs = 2, maxRarity = "common" },
			})
		end).toThrow("rising")
	end)

	-- Si le butin ne montait pas, continuer serait un pur malus : le jeu s'effondre.
	it("rejects a ladder whose loot does not grow with the risk", function()
		expect(function()
			TierLadder.new({
				{ id = 1, requiredSpeed = 0, goldMultiplier = 2, eggs = 5, maxRarity = "common" },
				{ id = 2, requiredSpeed = 150, goldMultiplier = 2, eggs = 5, maxRarity = "common" },
			})
		end).toThrow("loot")
	end)
end)

describe("TierLadder guarantees", function()
	it("carries the guaranteed floor of a deep tier into its loot", function()
		local ladder = TierLadder.new({
			{ id = 1, requiredSpeed = 0, goldMultiplier = 1, eggs = 1, maxRarity = "common" },
			{
				id = 2,
				requiredSpeed = 150,
				goldMultiplier = 4,
				eggs = 25,
				maxRarity = "epic",
				minRarity = "rare",
			},
		})

		expect(ladder:lootOf(1).minRarity).toBeNil()
		expect(ladder:lootOf(2).minRarity).toBe("rare")
	end)
end)
