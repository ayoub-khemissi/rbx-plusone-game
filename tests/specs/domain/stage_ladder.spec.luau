--!nocheck
local StageLadder = require(Domain.Run.StageLadder)

local STAGES = {
	{ id = 1, name = "Start", requiredSpeed = 0, coinMultiplier = 1 },
	{ id = 2, name = "Middle", requiredSpeed = 150, coinMultiplier = 1.8 },
	{ id = 3, name = "Deep", requiredSpeed = 450, coinMultiplier = 3 },
}

describe("StageLadder", function()
	local ladder
	beforeEach(function()
		ladder = StageLadder.new(STAGES)
	end)

	it("counts the stages", function()
		expect(ladder:count()).toBe(3)
	end)

	it("returns a stage by id", function()
		expect(ladder:get(2).name).toBe("Middle")
		expect(ladder:get(99)).toBeNil()
	end)

	it("gates entry behind a speed requirement", function()
		expect(ladder:isUnlocked(2, 149)).toBe(false)
		expect(ladder:isUnlocked(2, 150)).toBe(true)
		expect(ladder:isUnlocked(99, 1e9)).toBe(false)
	end)

	it("finds the deepest stage a speed can reach", function()
		expect(ladder:highestUnlocked(0)).toBe(1)
		expect(ladder:highestUnlocked(449)).toBe(2)
		expect(ladder:highestUnlocked(1e6)).toBe(3)
	end)

	it("exposes the next stage and its entry price", function()
		expect(ladder:nextOf(1).id).toBe(2)
		expect(ladder:nextOf(3)).toBeNil()
		expect(ladder:requirementOf(3)).toBe(450)
	end)

	it("measures progress towards the next gate", function()
		expect(ladder:progressToNext(1, 75)).toBeCloseTo(0.5, 1e-9)
		expect(ladder:progressToNext(2, 450)).toBe(1)
		expect(ladder:progressToNext(3, 1e9)).toBe(1)
	end)

	it("rejects a ladder whose gates do not rise", function()
		expect(function()
			StageLadder.new({
				{ id = 1, requiredSpeed = 100, coinMultiplier = 1 },
				{ id = 2, requiredSpeed = 50, coinMultiplier = 2 },
			})
		end).toThrow("rising")
	end)

	-- Si le gain ne montait pas, aller plus loin serait un pur malus.
	it("rejects a ladder whose reward does not grow with the risk", function()
		expect(function()
			StageLadder.new({
				{ id = 1, requiredSpeed = 0, coinMultiplier = 2 },
				{ id = 2, requiredSpeed = 150, coinMultiplier = 2 },
			})
		end).toThrow("rising")
	end)
end)
