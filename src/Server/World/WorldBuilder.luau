--!strict
--[[
	WorldBuilder — genere la carte a partir de la configuration.

	Aucune geometrie n'est ecrite en dur : les positions viennent de
	Domain.Zones.TrackLayout, les reglages de Config.World. Modifier une longueur de
	zone dans Config suffit a regenerer une carte coherente.

	Les elements interactifs sont marques avec CollectionService plutot que cables
	directement : le monde ne connait pas les cas d'usage, c'est Bootstrap qui les
	branche.
]]

local CollectionService = game:GetService("CollectionService")

local Palette = require(script.Parent.Palette)

local WorldBuilder = {}
WorldBuilder.__index = WorldBuilder

export type Tags = {
	banana: string,
	obstacle: string,
	gate: string,
	rebirthPad: string,
	spinner: string,
}

WorldBuilder.TAGS = {
	banana = "Banane",
	obstacle = "Obstacle",
	gate = "BarriereZone",
	rebirthPad = "PadRenaissance",
	spinner = "Rotatif",
} :: Tags

local MAP_SEED = 20260822 -- carte identique sur tous les serveurs

function WorldBuilder.new(dependencies)
	return setmetatable(table.clone(dependencies), WorldBuilder)
end

function WorldBuilder._hub(self, parent: Instance)
	local hub = self.config.World.hub
	local folder = Instance.new("Folder")
	folder.Name = "Hub"
	folder.Parent = parent

	local ground = Palette.block({
		name = "SolDuHub",
		size = Vector3.new(hub.size, hub.thickness, hub.size),
		position = Vector3.new(0, -hub.thickness / 2, 0),
		color = Palette.color(hub.color),
		material = Enum.Material.Ground,
		parent = folder,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "DepartSinge"
	spawn.Size = Vector3.new(24, 1, 24)
	spawn.Position = Vector3.new(-hub.size / 4, 0.5, 0)
	spawn.Color = Palette.color({ 240, 200, 80 })
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Duration = 0
	spawn.Parent = folder

	-- Pad de renaissance : geste classique du genre, tres lisible sans interface.
	local pad = Palette.block({
		name = "PadRenaissance",
		size = Vector3.new(18, 1, 18),
		position = Vector3.new(hub.size / 4, 0.5, -hub.size / 4),
		color = Palette.color({ 186, 104, 200 }),
		material = Enum.Material.Neon,
		parent = folder,
	})
	Palette.label(pad, "🔥 RENAISSANCE", Color3.new(1, 1, 1), Enum.NormalId.Top)
	CollectionService:AddTag(pad, WorldBuilder.TAGS.rebirthPad)

	return { folder = folder, ground = ground, spawn = spawn }
end

function WorldBuilder._gate(self, zone, bounds, parent: Instance)
	local gateConfig = self.config.World.gate

	local gate = Palette.block({
		name = `Barriere_{zone.id}`,
		size = Vector3.new(gateConfig.thickness, gateConfig.height, bounds.width),
		position = Vector3.new(bounds.startX, gateConfig.height / 2, 0),
		color = Palette.color(gateConfig.lockedColor),
		material = Enum.Material.ForceField,
		transparency = gateConfig.transparency,
		canCollide = zone.requiredSpeed > 0,
		parent = parent,
	})

	gate:SetAttribute("ZoneId", zone.id)
	gate:SetAttribute("RequiredSpeed", zone.requiredSpeed)
	gate:SetAttribute("ZoneName", zone.name)
	CollectionService:AddTag(gate, WorldBuilder.TAGS.gate)

	if zone.requiredSpeed > 0 then
		Palette.label(gate, `{zone.name}\n⚡ {zone.requiredSpeed}`, Color3.new(1, 1, 1), Enum.NormalId.Left)
		Palette.label(gate, `{zone.name}\n⚡ {zone.requiredSpeed}`, Color3.new(1, 1, 1), Enum.NormalId.Right)
	end

	return gate
end

function WorldBuilder._walls(self, bounds, color: Color3, parent: Instance)
	local track = self.config.World.track
	local half = bounds.width / 2
	local cursor = bounds.startX + 20

	while cursor + track.wallSegmentLength < bounds.endX do
		for _, side in { -1, 1 } do
			Palette.block({
				name = "MurDeCourse",
				size = Vector3.new(track.wallSegmentLength, track.wallHeight, track.wallThickness),
				position = Vector3.new(
					cursor + track.wallSegmentLength / 2,
					track.wallHeight / 2,
					side * (half + track.wallThickness / 2)
				),
				color = Palette.shade(color, -0.12),
				material = Enum.Material.Slate,
				parent = parent,
			})
		end
		cursor += track.wallSegmentLength + track.wallGapLength
	end
end

function WorldBuilder._obstacles(self, bounds, random: Random, parent: Instance)
	local track = self.config.World.track
	local cursor = bounds.startX + track.hurdleSpacing

	while cursor < bounds.endX - 40 do
		local width = random:NextInteger(14, math.floor(bounds.width * 0.55))
		local offset = random:NextInteger(-1, 1) * (bounds.width / 4)

		-- Haie franchissable : elle bloque, mais ne penalise pas.
		Palette.block({
			name = "Haie",
			size = Vector3.new(4, track.hurdleHeight, width),
			position = Vector3.new(cursor, track.hurdleHeight / 2, offset),
			color = Palette.color({ 120, 84, 56 }),
			material = Enum.Material.WoodPlanks,
			parent = parent,
		})

		-- Une haie sur trois recoit un rotor : traverse le joueur et l'etourdit.
		if random:NextNumber() < 0.34 then
			local spinner = Palette.block({
				name = "Rotor",
				size = Vector3.new(3, 3, bounds.width * 0.75),
				position = Vector3.new(cursor + 30, 6, 0),
				color = Palette.color({ 214, 78, 74 }),
				material = Enum.Material.Neon,
				canCollide = false,
				parent = parent,
			})
			spinner:SetAttribute("SpinSpeed", random:NextNumber(0.6, 1.8))
			CollectionService:AddTag(spinner, WorldBuilder.TAGS.obstacle)
			CollectionService:AddTag(spinner, WorldBuilder.TAGS.spinner)
		end

		-- Plateforme haute : recompense les joueurs qui maitrisent le saut mural.
		if random:NextNumber() < track.platformChance then
			Palette.block({
				name = "Plateforme",
				size = Vector3.new(34, 2, 16),
				position = Vector3.new(cursor + 45, random:NextInteger(14, 22), offset),
				color = Palette.color({ 150, 130, 96 }),
				material = Enum.Material.WoodPlanks,
				parent = parent,
			})
		end

		cursor += track.hurdleSpacing
	end
end

function WorldBuilder._bananas(self, zone, bounds, random: Random, parent: Instance)
	local track = self.config.World.track
	local amount = math.floor(self.config.Balance.session.bananaCollectAmount * zone.bananaMultiplier)
	local cursor = bounds.startX + 30

	while cursor < bounds.endX - 20 do
		local banana = Palette.block({
			name = "Banane",
			size = Vector3.new(2.4, 2.4, 2.4),
			position = Vector3.new(
				cursor,
				track.bananaHeight,
				random:NextInteger(-1, 1) * (bounds.width / 4)
			),
			color = Palette.color({ 250, 214, 76 }),
			material = Enum.Material.Neon,
			canCollide = false,
			shape = Enum.PartType.Ball,
			parent = parent,
		})

		banana:SetAttribute("Valeur", amount)
		CollectionService:AddTag(banana, WorldBuilder.TAGS.banana)
		cursor += track.bananaSpacing
	end
end

function WorldBuilder._decor(self, bounds, color: Color3, random: Random, parent: Instance)
	local decor = self.config.World.decor
	local half = bounds.width / 2

	for index = 1, decor.treesPerZone do
		local side = if index % 2 == 0 then 1 else -1
		local x = bounds.startX + (bounds.length / decor.treesPerZone) * index
		local z = side * (half + decor.sideOffset + random:NextInteger(0, 14))

		Palette.block({
			name = "Tronc",
			size = Vector3.new(5, decor.trunkHeight, 5),
			position = Vector3.new(x, decor.trunkHeight / 2, z),
			color = Palette.color({ 92, 64, 44 }),
			material = Enum.Material.Wood,
			parent = parent,
		})

		Palette.block({
			name = "Feuillage",
			size = Vector3.new(decor.foliageSize, decor.foliageSize, decor.foliageSize),
			position = Vector3.new(x, decor.trunkHeight + decor.foliageSize / 3, z),
			color = Palette.shade(color, 0.08),
			material = Enum.Material.Grass,
			shape = Enum.PartType.Ball,
			canCollide = false,
			parent = parent,
		})
	end
end

function WorldBuilder._zone(self, zone, parent: Instance, random: Random)
	local bounds = self.layout:boundsOf(zone.id)
	local color = Palette.color(zone.color)

	local folder = Instance.new("Folder")
	folder.Name = `Zone{zone.id}_{zone.name}`
	folder.Parent = parent

	Palette.block({
		name = "Sol",
		size = Vector3.new(bounds.length, self.config.World.track.thickness, bounds.width),
		position = Vector3.new((bounds.startX + bounds.endX) / 2, -self.config.World.track.thickness / 2, 0),
		color = color,
		material = Enum.Material.Grass,
		parent = folder,
	})

	self:_gate(zone, bounds, folder)
	self:_walls(bounds, color, folder)
	self:_obstacles(bounds, random, folder)
	self:_bananas(zone, bounds, random, folder)
	self:_decor(bounds, color, random, folder)

	return folder
end

--[[ Construit (ou reconstruit) toute la carte. ]]
function WorldBuilder.build(self): Folder
	local existing = workspace:FindFirstChild("Monde")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "Monde"

	self:_hub(world)

	local zones = Instance.new("Folder")
	zones.Name = "Zones"
	zones.Parent = world

	local random = Random.new(MAP_SEED)
	for _, zone in self.ladder:all() do
		self:_zone(zone, zones, random)
	end

	world.Parent = workspace

	if self.logger then
		self.logger:info(
			`Carte generee : {self.ladder:count()} zones, {self.layout:totalLength()} studs de piste`
		)
	end

	return world
end

return WorldBuilder
