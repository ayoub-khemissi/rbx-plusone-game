--!nocheck
local LevelCurve = require(Domain.Run.LevelCurve)

local TUNING = { base = 20.6, exponent = 1.9, knownDiscount = 0.08 }

describe("LevelCurve, re-earning known ground", function()
	local curve
	beforeEach(function()
		curve = LevelCurve.new(TUNING)
	end)

	--[[
		THE PROBLEM THIS SOLVES. With an exponent near two, nine tenths of a world's
		experience sits in the last tenth of its levels, so a rebirth spends most of
		its time re-walking ground the player already covered. Boosting the gain
		cannot fix that — the gain is not what is expensive, the price is.
	]]
	it("charges a fraction for a level already reached", function()
		local full = curve:requirementFor(200)
		expect(curve:requirementFor(200, 200)).toBe(math.floor(full * TUNING.knownDiscount))
	end)

	it("charges full price for ground never covered", function()
		expect(curve:requirementFor(200, 0)).toBe(curve:requirementFor(200))
		expect(curve:requirementFor(200, 100)).toBeGreaterThan(curve:requirementFor(200, 200))
	end)

	--[[
		Past the best, the discount stops. New ground is what a world is made of, so
		it has to cost what it costs or the whole pace collapses with it.
	]]
	it("only discounts up to the best, never past it", function()
		local best = 100
		local discounted = curve:requirementFor(best, best)
		local beyond = curve:requirementFor(150, best)
		local newGround = curve:requirementFor(150) - curve:requirementFor(best)

		expect(beyond).toBe(math.floor(discounted + newGround))
	end)

	it("still rises with every level", function()
		local previous = -1
		for level = 1, 260 do
			local price = curve:requirementFor(level, 200)
			expect(price).toBeGreaterThan(previous)
			previous = price
		end
	end)

	-- The pair has to agree, on both sides of the point where the discount stops.
	it("reads back the level it charged for", function()
		for _, best in { 0, 100, 200 } do
			for level = 2, 240, 7 do
				expect(curve:levelFor(curve:requirementFor(level, best), best)).toBe(level)
			end
		end
	end)

	it("leaves a player with no history exactly where they were", function()
		for level = 2, 200, 13 do
			expect(curve:requirementFor(level, 0)).toBe(curve:requirementFor(level))
		end
	end)

	it("reports progress inside the level it is standing in", function()
		local best = 200
		local floor = curve:requirementFor(120, best)
		local progress = curve:progressFor(floor + 1, best)

		expect(progress.level).toBe(120)
		expect(progress.ratio).toBeGreaterThan(0)
		expect(progress.ratio).toBeLessThan(1)
	end)
end)
