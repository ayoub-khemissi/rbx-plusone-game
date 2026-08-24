--!strict
--[[
	SkyBuilder — generates the archipelago from the configuration.

	No geometry is hard coded: positions come from Domain.Run.SkyLayout, settings from
	Config.World. Changing a tier length in Config is enough to regenerate a coherent
	sky.

	Interactive parts are marked with CollectionService rather than wired directly:
	the world knows nothing about the use cases, Bootstrap connects them.
]]

local CollectionService = game:GetService("CollectionService")

local Palette = require(script.Parent.Palette)

local SkyBuilder = {}
SkyBuilder.__index = SkyBuilder

export type Tags = {
	ring: string,
	wall: string,
	altar: string,
	gate: string,
	launchPad: string,
	perch: string,
	drifting: string,
	rotating: string,
}

SkyBuilder.TAGS = {
	ring = "Ring",
	wall = "Wall",
	altar = "Altar",
	gate = "Gate",
	launchPad = "LaunchPad",
	perch = "Perch",
	drifting = "Drifting",
	rotating = "Rotating",
} :: Tags

local MAP_SEED = 20260823 -- identical sky on every server

function SkyBuilder.new(dependencies)
	return setmetatable(table.clone(dependencies), SkyBuilder)
end

function SkyBuilder._nest(self, parent: Instance)
	local nest = self.config.World.nest
	local folder = Instance.new("Folder")
	folder.Name = "Nest"
	folder.Parent = parent

	Palette.block({
		name = "Floor",
		size = Vector3.new(nest.size, nest.thickness, nest.size),
		position = Vector3.new(0, nest.altitude - nest.thickness / 2, 0),
		color = Palette.color(nest.color),
		material = Enum.Material.Slate,
		parent = folder,
	})

	-- Rails: falling off the Nest by accident would be pure frustration.
	for _, side in
		{ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
	do
		local along = Vector3.new(math.abs(side.z), 0, math.abs(side.x))
		Palette.block({
			name = "Rail",
			size = along * nest.size + Vector3.new(2, nest.railHeight, 2),
			position = side * (nest.size / 2) + Vector3.new(0, nest.altitude + nest.railHeight / 2, 0),
			color = Palette.shade(Palette.color(nest.color), -0.1),
			material = Enum.Material.Wood,
			parent = folder,
		})
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "NestSpawn"
	spawn.Size = Vector3.new(28, 1, 28)
	spawn.Position = Vector3.new(-nest.size / 4, nest.altitude + 0.5, 0)
	spawn.Color = Palette.color({ 240, 214, 120 })
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Parent = folder

	-- The perch: standing here speeds incubation up.
	local perch = Palette.block({
		name = "Perch",
		size = Vector3.new(40, 1, 40),
		position = Vector3.new(-nest.size / 4, nest.altitude + 0.5, nest.size / 4),
		color = Palette.color({ 132, 176, 220 }),
		material = Enum.Material.Neon,
		parent = folder,
	})
	Palette.label(perch, "🪺 PERCH — eggs hatch faster", Color3.new(1, 1, 1), Enum.NormalId.Top)
	CollectionService:AddTag(perch, SkyBuilder.TAGS.perch)

	-- The launch pad, facing the sky.
	local pad = Palette.block({
		name = "LaunchPad",
		size = Vector3.new(36, 1, 36),
		position = Vector3.new(nest.size / 3, nest.altitude + 0.5, 0),
		color = Palette.color({ 244, 176, 96 }),
		material = Enum.Material.Neon,
		parent = folder,
	})
	Palette.label(pad, "🐉 TAKE OFF", Color3.new(1, 1, 1), Enum.NormalId.Top)
	CollectionService:AddTag(pad, SkyBuilder.TAGS.launchPad)

	return folder
end

function SkyBuilder._gate(self, tier, bounds, parent: Instance)
	local settings = self.config.World.gate
	local center = Vector3.new(bounds.startX, bounds.altitude, 0)

	local locked = tier.requiredSpeed > 0
	local ring = Palette.ring({
		name = `Gate_{tier.id}`,
		center = center,
		radius = settings.radius,
		thickness = settings.thickness,
		color = Palette.color(if locked then settings.lockedColor else settings.unlockedColor),
		segments = 18,
		parent = parent,
	})

	local sensor = Palette.sensor({
		name = "GateSensor",
		center = center,
		radius = settings.radius,
		parent = ring,
	})
	sensor:SetAttribute("TierId", tier.id)
	sensor:SetAttribute("RequiredSpeed", tier.requiredSpeed)
	sensor:SetAttribute("TierName", tier.name)
	CollectionService:AddTag(sensor, SkyBuilder.TAGS.gate)

	return ring
end

function SkyBuilder._altar(self, tier, parent: Instance)
	local settings = self.config.World.altar
	local point = self.layout:altarOf(tier.id)
	local center = Vector3.new(point.x, point.y, point.z)

	local ring = Palette.ring({
		name = `Altar_{tier.id}`,
		center = center,
		radius = settings.radius,
		thickness = settings.thickness,
		color = Palette.color(settings.color),
		segments = 14,
		parent = parent,
	})

	-- A light column: the detour has to be visible from far enough to be a choice.
	Palette.block({
		name = "Beacon",
		size = Vector3.new(3, settings.beaconHeight, 3),
		position = center - Vector3.new(0, settings.beaconHeight / 2, 0),
		color = Palette.color(settings.color),
		material = Enum.Material.Neon,
		transparency = 0.45,
		canCollide = false,
		canTouch = false,
		parent = ring,
	})

	local sensor = Palette.sensor({
		name = "AltarSensor",
		center = center,
		radius = settings.radius,
		parent = ring,
	})
	sensor:SetAttribute("TierId", tier.id)
	CollectionService:AddTag(sensor, SkyBuilder.TAGS.altar)

	return ring
end

function SkyBuilder._rings(self, tier, parent: Instance)
	local settings = self.config.World.rings
	local value = self.config.Balance.run.ringValue

	for index, point in self.layout:ringPositions(tier.id) do
		local center = Vector3.new(point.x, point.y, point.z)
		local ring = Palette.ring({
			name = `Ring_{tier.id}_{index}`,
			center = center,
			radius = settings.radius,
			thickness = settings.thickness,
			color = Palette.color(settings.color),
			parent = parent,
		})

		local sensor = Palette.sensor({
			name = "RingSensor",
			center = center,
			radius = settings.radius,
			parent = ring,
		})
		sensor:SetAttribute("Value", value)
		CollectionService:AddTag(sensor, SkyBuilder.TAGS.ring)
	end
end

--[[ One obstacle: two slabs leaving a gap the dragon has to thread. ]]
function SkyBuilder._obstacle(self, tier, bounds, x: number, random: Random, parent: Instance)
	local settings = self.config.World.walls
	local half = bounds.width / 2
	local gap = settings.minGap + random:NextInteger(0, 18)
	local gapCenter = random:NextInteger(-math.floor(half - gap), math.floor(half - gap))

	local function slab(name: string, zCenter: number, zSize: number)
		local wall = Palette.block({
			name = name,
			size = Vector3.new(settings.thickness, bounds.height, math.max(zSize, 4)),
			position = Vector3.new(x, bounds.altitude, zCenter),
			color = Palette.color(settings.color),
			material = Enum.Material.Neon,
			transparency = 0.15,
			canCollide = false, -- the dragon must not bounce: touching is fatal
			parent = parent,
		})
		CollectionService:AddTag(wall, SkyBuilder.TAGS.wall)

		if tier.hazard == "drifting" or tier.hazard == "everything" then
			wall:SetAttribute("DriftSpeed", settings.driftSpeed)
			wall:SetAttribute("DriftRange", half - gap)
			wall:SetAttribute("DriftOrigin", zCenter)
			CollectionService:AddTag(wall, SkyBuilder.TAGS.drifting)
		end

		return wall
	end

	slab("WallLeft", gapCenter - gap / 2 - (half - gapCenter + gap / 2) / 2, half - gapCenter - gap / 2)
	slab("WallRight", gapCenter + gap / 2 + (half + gapCenter + gap / 2) / 2, half + gapCenter - gap / 2)

	if tier.hazard == "rotating" or tier.hazard == "everything" then
		local bar = Palette.block({
			name = "RotatingBar",
			size = Vector3.new(settings.thickness, bounds.height * 0.9, settings.thickness),
			position = Vector3.new(x + settings.spacing / 2, bounds.altitude, 0),
			color = Palette.color(settings.color),
			material = Enum.Material.Neon,
			canCollide = false,
			parent = parent,
		})
		bar:SetAttribute("RotationSpeed", settings.rotationSpeed)
		CollectionService:AddTag(bar, SkyBuilder.TAGS.wall)
		CollectionService:AddTag(bar, SkyBuilder.TAGS.rotating)
	end
end

function SkyBuilder._obstacles(self, tier, bounds, random: Random, parent: Instance)
	local spacing = self.config.World.walls.spacing
	local cursor = bounds.startX + spacing

	while cursor < bounds.endX - 60 do
		self:_obstacle(tier, bounds, cursor, random, parent)
		cursor += spacing
	end
end

function SkyBuilder._islands(self, bounds, color: Color3, random: Random, parent: Instance)
	local settings = self.config.World.islands

	for index = 1, settings.perTier do
		local size = random:NextInteger(settings.minSize, settings.maxSize)
		local side = if index % 2 == 0 then 1 else -1

		Palette.block({
			name = "Island",
			size = Vector3.new(size, size * 0.35, size),
			position = Vector3.new(
				bounds.startX + (bounds.length / settings.perTier) * index,
				bounds.altitude + random:NextInteger(-70, 70),
				side * (bounds.width / 2 + random:NextInteger(60, settings.spread))
			),
			color = Palette.shade(color, random:NextNumber(-0.08, 0.08)),
			material = Enum.Material.Grass,
			canCollide = false,
			canTouch = false,
			parent = parent,
		})
	end
end

function SkyBuilder._tier(self, tier, parent: Instance, random: Random)
	local bounds = self.layout:boundsOf(tier.id)
	local color = Palette.color(tier.color)

	local folder = Instance.new("Folder")
	folder.Name = `Tier{tier.id}_{tier.name}`
	folder.Parent = parent

	self:_gate(tier, bounds, folder)
	self:_altar(tier, folder)
	self:_rings(tier, folder)
	self:_obstacles(tier, bounds, random, folder)
	self:_islands(bounds, color, random, folder)

	return folder
end

--[[ Builds (or rebuilds) the whole sky. ]]
function SkyBuilder.build(self): Folder
	local existing = workspace:FindFirstChild("Sky")
	if existing then
		existing:Destroy()
	end

	local sky = Instance.new("Folder")
	sky.Name = "Sky"

	self:_nest(sky)

	local tiers = Instance.new("Folder")
	tiers.Name = "Tiers"
	tiers.Parent = sky

	local random = Random.new(MAP_SEED)
	for _, tier in self.ladder:all() do
		self:_tier(tier, tiers, random)
	end

	sky.Parent = workspace

	if self.logger then
		self.logger:info(`Sky generated: {self.ladder:count()} tiers, {self.layout:totalLength()} studs long`)
	end

	return sky
end

return SkyBuilder
