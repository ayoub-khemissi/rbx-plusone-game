--!nocheck
local SpeedCurve = require(Domain.Progression.SpeedCurve)

local TUNING = {
	baseWalkSpeed = 16,
	maxBonusWalkSpeed = 234,
	softness = 900,
	baseJumpPower = 50,
	jumpPowerPerLevel = 4,
	maxJumpPower = 140,
}

describe("SpeedCurve", function()
	local curve
	beforeEach(function()
		curve = SpeedCurve.new(TUNING)
	end)

	it("part de la vitesse de base a zero point de vitesse", function()
		expect(curve:walkSpeedFor(0)).toBe(16)
	end)

	it("croit de facon monotone", function()
		local previous = curve:walkSpeedFor(0)
		for speed = 50, 5000, 50 do
			local current = curve:walkSpeedFor(speed)
			expect(current).toBeGreaterThan(previous)
			previous = current
		end
	end)

	it("sature sous le plafond physique quelle que soit la vitesse", function()
		local ceiling = TUNING.baseWalkSpeed + TUNING.maxBonusWalkSpeed
		expect(curve:walkSpeedFor(1e12)).toBeLessThanOrEqual(ceiling)
		expect(curve:walkSpeedFor(1e12)).toBeGreaterThan(ceiling - 0.001)
	end)

	it("suit la courbe exponentielle inverse attendue", function()
		-- 16 + 234 * (1 - e^-1) au point d'inflexion (speed == softness)
		expect(curve:walkSpeedFor(900)).toBeCloseTo(16 + 234 * (1 - math.exp(-1)), 0.01)
	end)

	it("traite les valeurs invalides comme zero", function()
		expect(curve:walkSpeedFor(-500)).toBe(16)
		expect(curve:walkSpeedFor(0 / 0)).toBe(16)
	end)

	it("calcule la puissance de saut par niveau", function()
		expect(curve:jumpPowerFor(0)).toBe(50)
		expect(curve:jumpPowerFor(5)).toBe(70)
		expect(curve:jumpPowerFor(1000)).toBe(140)
	end)

	it("rend la progression relative vers le plafond", function()
		expect(curve:saturationFor(0)).toBe(0)
		expect(curve:saturationFor(1e12)).toBeCloseTo(1, 0.001)
	end)
end)
