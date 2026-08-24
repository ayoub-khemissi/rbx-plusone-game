--!nocheck
local LevelCurve = require(Domain.Run.LevelCurve)

local FIXTURE = { base = 20, exponent = 1.7 }

describe("LevelCurve", function()
	local curve
	beforeEach(function()
		curve = LevelCurve.new(FIXTURE)
	end)

	it("starts everyone at level 1, which costs nothing", function()
		expect(curve:requirementFor(1)).toBe(0)
		expect(curve:levelFor(0)).toBe(1)
	end)

	it("asks for more speed at every level", function()
		local previous = -1
		for level = 1, 60 do
			local requirement = curve:requirementFor(level)
			expect(requirement).toBeGreaterThan(previous)
			previous = requirement
		end
	end)

	--[[
		The pair must agree at every step, and the boundary is where an inverted
		formula drifts: a level is reached the instant its requirement is met, not a
		point of speed later.
	]]
	it("agrees with itself on both sides of every boundary", function()
		for level = 2, 60 do
			local requirement = curve:requirementFor(level)
			expect(curve:levelFor(requirement)).toBe(level)
			expect(curve:levelFor(requirement - 1)).toBe(level - 1)
		end
	end)

	it("never drops below level 1, whatever it is handed", function()
		expect(curve:levelFor(-500)).toBe(1)
		expect(curve:levelFor(0)).toBe(1)
	end)

	it("keeps climbing far past the last stage", function()
		expect(curve:levelFor(15000)).toBeGreaterThan(40)
	end)

	describe("progressFor", function()
		it("reports the distance covered inside the current level", function()
			local floor = curve:requirementFor(9)
			local ceiling = curve:requirementFor(10)
			local progress = curve:progressFor(floor + 5)

			expect(progress.level).toBe(9)
			expect(progress.current).toBe(5)
			expect(progress.required).toBe(ceiling - floor)
			expect(progress.ratio).toBeCloseTo(5 / (ceiling - floor))
		end)

		it("sits at zero the instant a level is reached", function()
			local progress = curve:progressFor(curve:requirementFor(12))
			expect(progress.level).toBe(12)
			expect(progress.current).toBe(0)
			expect(progress.ratio).toBe(0)
		end)

		it("never reports a full bar, which would mean the level had not counted", function()
			for level = 1, 40 do
				local progress = curve:progressFor(curve:requirementFor(level + 1) - 1)
				expect(progress.ratio).toBeLessThan(1)
				expect(progress.level).toBe(level)
			end
		end)
	end)

	--[[
		The point of the curve: early levels come quickly enough to be felt, and the
		pace stretches out instead of stopping. A curve that flattens has nothing
		left to give; one that explodes strands the player.
	]]
	it("hands out the first levels fast and the later ones slowly", function()
		local early = curve:requirementFor(3) - curve:requirementFor(2)
		local mid = curve:requirementFor(20) - curve:requirementFor(19)
		local late = curve:requirementFor(50) - curve:requirementFor(49)

		expect(early).toBeLessThan(mid)
		expect(mid).toBeLessThan(late)
		expect(curve:requirementFor(2)).toBeLessThan(100)
	end)
end)
