--!nocheck
local SkyLayout = require(Domain.Run.SkyLayout)

local TIERS = {
	{ id = 1, length = 400 },
	{ id = 2, length = 400 },
	{ id = 3, length = 600 },
}

local TUNING = {
	launchX = 200,
	corridorWidth = 120,
	corridorHeight = 90,
	baseAltitude = 150,
	altitudeStep = 120,
	altarOffset = 90,
	ringSpacing = 50,
	ringWeave = 30,
}

describe("SkyLayout", function()
	local layout
	beforeEach(function()
		layout = SkyLayout.new(TUNING, TIERS)
	end)

	it("stacks the tiers end to end from the launch point", function()
		expect(layout:boundsOf(1).startX).toBe(200)
		expect(layout:boundsOf(1).endX).toBe(600)
		expect(layout:boundsOf(2).startX).toBe(600)
		expect(layout:boundsOf(3).endX).toBe(1600)
	end)

	it("raises each tier higher than the last", function()
		expect(layout:boundsOf(1).altitude).toBe(150)
		expect(layout:boundsOf(2).altitude).toBe(270)
		expect(layout:boundsOf(3).altitude).toBe(390)
	end)

	it("gives the launch point in front of the first tier", function()
		local launch = layout:launchPoint()
		expect(launch.x).toBeLessThan(200)
		expect(launch.y).toBe(150)
	end)

	it("places the wind barrier at the tier entrance, on the fast line", function()
		local gate = layout:gateOf(2)
		expect(gate.x).toBe(600)
		expect(gate.y).toBe(270)
		expect(gate.z).toBe(0)
	end)

	-- L'Autel doit couter un ecart : s'il etait sur la ligne rapide, on encaisserait
	-- par accident au lieu de choisir.
	it("pushes the altar off the fast line", function()
		local altar = layout:altarOf(2)
		expect(math.abs(altar.z)).toBe(TUNING.altarOffset)
		expect(altar.x).toBeGreaterThan(layout:boundsOf(2).startX)
		expect(altar.x).toBeLessThan(layout:boundsOf(2).endX)
	end)

	it("alternates the altar side so the flight never becomes a habit", function()
		expect(layout:altarOf(1).z).never.toBe(layout:altarOf(2).z)
	end)

	it("finds the tier from an abscissa", function()
		expect(layout:tierAt(0)).toBeNil()
		expect(layout:tierAt(199)).toBeNil()
		expect(layout:tierAt(200)).toBe(1)
		expect(layout:tierAt(599)).toBe(1)
		expect(layout:tierAt(600)).toBe(2)
		expect(layout:tierAt(99999)).toBe(3)
	end)

	it("gives the total length of the sky", function()
		expect(layout:totalLength()).toBe(1400)
	end)

	it("lays rings along the tier at its altitude", function()
		local rings = layout:ringPositions(1)
		expect(#rings).toBeGreaterThan(4)
		for _, ring in rings do
			expect(ring.y).toBe(150)
			expect(ring.x).toBeGreaterThanOrEqual(200)
			expect(ring.x).toBeLessThanOrEqual(600)
			expect(math.abs(ring.z)).toBeLessThanOrEqual(TUNING.ringWeave)
		end
	end)

	it("weaves the ring line instead of drawing it straight", function()
		local rings = layout:ringPositions(1)
		local offsets = {}
		for _, ring in rings do
			offsets[tostring(ring.z)] = true
		end
		local distinct = 0
		for _ in offsets do
			distinct += 1
		end
		expect(distinct).toBeGreaterThan(2)
	end)
end)
