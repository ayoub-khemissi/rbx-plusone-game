--!nocheck
local MovementAccounting = require(Domain.Progression.MovementAccounting)

local TUNING = {
	studsPerStep = 4,
	deadzone = 0.15,
	toleranceFactor = 1.35,
	minimumSpeedAllowance = 16,
}

describe("MovementAccounting", function()
	local accounting
	beforeEach(function()
		accounting = MovementAccounting.new(TUNING)
	end)

	it("convertit la distance parcourue en pas", function()
		local reading = accounting:measure(40, 1, 50)
		expect(reading.steps).toBe(10)
		expect(reading.clamped).toBe(false)
	end)

	it("ignore le bruit sous la zone morte", function()
		local reading = accounting:measure(0.1, 0.1, 50)
		expect(reading.steps).toBe(0)
		expect(reading.distance).toBe(0)
	end)

	it("plafonne les deplacements impossibles (teleport / exploit)", function()
		-- 50 studs/s pendant 0.1 s ne peut pas depasser 50 * 0.1 * 1.35 = 6.75 studs
		local reading = accounting:measure(5000, 0.1, 50)
		expect(reading.clamped).toBe(true)
		expect(reading.distance).toBeCloseTo(6.75, 1e-6)
		expect(reading.steps).toBeCloseTo(6.75 / 4, 1e-6)
	end)

	it("accorde une allocation minimale aux joueurs lents", function()
		local reading = accounting:measure(100, 1, 0)
		expect(reading.distance).toBeCloseTo(16 * 1.35, 1e-6)
	end)

	it("refuse les pas de temps nuls ou negatifs", function()
		expect(accounting:measure(10, 0, 50).steps).toBe(0)
		expect(accounting:measure(10, -1, 50).steps).toBe(0)
	end)

	it("neutralise les valeurs non finies", function()
		expect(accounting:measure(0 / 0, 1, 50).steps).toBe(0)
		expect(accounting:measure(math.huge, 1, 50).clamped).toBe(true)
	end)

	it("mesure une distance horizontale a partir de deux positions", function()
		local distance = accounting:horizontalDistance({ x = 0, y = 100, z = 0 }, { x = 3, y = 0, z = 4 })
		expect(distance).toBe(5) -- la composante verticale est ignoree (chutes / sauts)
	end)
end)
