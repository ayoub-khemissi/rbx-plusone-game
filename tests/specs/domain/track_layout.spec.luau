--!nocheck
local TrackLayout = require(Domain.Zones.TrackLayout)

local ZONES = {
	{ id = 1, length = 400 },
	{ id = 2, length = 400 },
	{ id = 3, length = 600 },
}

local TUNING = { trackStartX = 200, trackWidth = 60, groundY = 0, spawnInset = 25 }

describe("TrackLayout", function()
	local layout
	beforeEach(function()
		layout = TrackLayout.new(TUNING, ZONES)
	end)

	it("empile les zones bout a bout depuis le hub", function()
		expect(layout:boundsOf(1).startX).toBe(200)
		expect(layout:boundsOf(1).endX).toBe(600)
		expect(layout:boundsOf(2).startX).toBe(600)
		expect(layout:boundsOf(3).endX).toBe(1600)
	end)

	it("expose la largeur de la piste", function()
		expect(layout:boundsOf(2).width).toBe(60)
	end)

	it("place le point d'apparition juste apres la barriere", function()
		local spawn = layout:spawnOf(2)
		expect(spawn.x).toBe(625)
		expect(spawn.y).toBe(5)
		expect(spawn.z).toBe(0)
	end)

	it("retrouve la zone a partir d'une abscisse", function()
		expect(layout:zoneAt(0)).toBeNil() -- hub
		expect(layout:zoneAt(199)).toBeNil()
		expect(layout:zoneAt(200)).toBe(1)
		expect(layout:zoneAt(599)).toBe(1)
		expect(layout:zoneAt(600)).toBe(2)
		expect(layout:zoneAt(1599)).toBe(3)
		expect(layout:zoneAt(99999)).toBe(3) -- au-dela : derniere zone
	end)

	it("donne la longueur totale de la piste", function()
		expect(layout:totalLength()).toBe(1400)
	end)

	it("positionne la barriere a l'entree de chaque zone", function()
		expect(layout:gateOf(3).x).toBe(1000)
		expect(layout:gateOf(1).x).toBe(200)
	end)
end)
