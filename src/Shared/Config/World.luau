--!strict
--[[ World — map generation settings. No logic here, only tuning. ]]

return table.freeze({
	nest = table.freeze({
		size = 320, -- side of the Nest platform, centred on the origin
		thickness = 8,
		altitude = 180, -- the Nest floats at the altitude of the first tier
		color = { 138, 116, 92 },
		railHeight = 6,
	}),

	corridor = table.freeze({
		markerThickness = 2, -- translucent guides drawing the flight corridor
		markerSpacing = 120,
		floorTransparency = 0.85,
	}),

	rings = table.freeze({
		radius = 11,
		thickness = 2.2,
		color = { 250, 214, 120 },
	}),

	walls = table.freeze({
		thickness = 4,
		spacing = 110, -- distance between two obstacles along a tier
		minGap = 34, -- narrowest passage left for the dragon
		driftSpeed = 6, -- studs per second for drifting walls
		rotationSpeed = 0.8, -- radians per second for rotating hazards
		color = { 214, 96, 88 },
	}),

	altar = table.freeze({
		radius = 16,
		thickness = 3,
		color = { 250, 236, 150 },
		beaconHeight = 70, -- light column making the detour visible from far away
	}),

	gate = table.freeze({
		radius = 34,
		thickness = 3,
		transparency = 0.5,
		lockedColor = { 214, 78, 74 },
		unlockedColor = { 120, 214, 150 },
	}),

	islands = table.freeze({
		perTier = 10,
		minSize = 40,
		maxSize = 120,
		spread = 320, -- how far islands drift from the corridor
	}),
})
