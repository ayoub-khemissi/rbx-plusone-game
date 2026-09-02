--!strict
--[[
	MapKit — the pieces a map is built from, for anything that builds one in code.

	Two builders share this: the test platform (Sandbox) and the starting lobby
	(Lobby). Each used to carry its own copy of "make an anchored part", "float a
	label over it", "find a Coin to clone" — and two copies of a rule is how one of
	them drifts. Everything here is tagged exactly the way a hand-built map would be,
	so a pad that works when built by code works when placed by hand, and the other
	way round.

	Nothing here knows the game's rules. It places parts and sets tags; MapBindings
	reads them like any other map.
]]

local CollectionService = game:GetService("CollectionService")
local InsertService = game:GetService("InsertService")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local MapBindings = require(script.Parent.MapBindings)

local MapKit = {}

export type Logger = { info: (any, string) -> (), warn: (any, string) -> () }

MapKit.COLOURS = {
	floor = Color3.fromRGB(74, 82, 104),
	wall = Color3.fromRGB(58, 64, 88),
	trim = Color3.fromRGB(247, 197, 37),
	shop = Color3.fromRGB(229, 51, 60),
	prestige = Color3.fromRGB(59, 178, 240),
	finish = Color3.fromRGB(92, 201, 74),
	belt = Color3.fromRGB(150, 60, 220),
	coin = Color3.fromRGB(247, 197, 37),
	beltSurface = Color3.fromRGB(28, 30, 40),
	beltBase = Color3.fromRGB(96, 102, 124),
}

--[[
	The surfaces a built map is made of, as Material Variants.

	A variant is a material the engine tiles across every face of a part on its own,
	whatever the part's size — one instance in MaterialService, and any number of
	parts wearing it by name. The textures are the ones in docs/TEXTURES.md, already
	in the place; nothing is fetched.

	Flat colour was the difference between a room and a diagram. A floor that is
	tiles, a wall that is brick and a belt that is steel read as a place somebody
	could stand in, before a single prop is added.
]]
MapKit.SURFACES = {
	{ name = "LobbyFloor", map = "rbxassetid://4621495999", studs = 8 }, -- large_floor_tiles
	{ name = "LobbyWall", map = "rbxassetid://4621497703", studs = 6 }, -- brick_floor
	{ name = "CourseWood", map = "rbxassetid://4621506509", studs = 6 }, -- planks_brown
	{ name = "Steel", map = "rbxassetid://4549727994", studs = 4 }, -- metal
	{ name = "FinishStone", map = "rbxassetid://4621489901", studs = 8 }, -- marble
}

--[[ Declares every surface once. Safe to call again: existing ones are kept. ]]
function MapKit.materials()
	for _, surface in MapKit.SURFACES do
		if not MaterialService:FindFirstChild(surface.name) then
			local variant = Instance.new("MaterialVariant")
			variant.Name = surface.name
			variant.BaseMaterial = Enum.Material.Plastic
			variant.ColorMap = surface.map
			variant.StudsPerTile = surface.studs
			variant.Parent = MaterialService
		end
	end
end

--[[
	Dresses a part in a surface. The colour goes to near white, because a variant's
	texture is MULTIPLIED by the part's colour: brick tinted navy is navy, and the
	whole point was to stop painting things navy.
]]
function MapKit.surface(part: BasePart, name: string, tint: Color3?)
	part.Material = Enum.Material.Plastic
	part.MaterialVariant = name
	part.Color = tint or Color3.fromRGB(235, 232, 226)
end

--[[ A soft light, for a room that would otherwise be lit only by the sky. ]]
function MapKit.light(parent: BasePart, colour: Color3, brightness: number, range: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = colour
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

--[[
	Somewhere to say things when nobody passed a logger.

	Builders are called by Bootstrap with the real one, and by a human from the
	Studio command bar with nothing at all — and the second caller is the one that
	most needs to be told what happened.
]]
function MapKit.loggerOr(logger: Logger?, prefix: string): Logger
	if logger then
		return logger
	end
	return {
		info = function(_self, message: string)
			print(`[{prefix}] {message}`)
		end,
		warn = function(_self, message: string)
			warn(`[{prefix}] {message}`)
		end,
	}
end

function MapKit.part(parent: Instance, name: string, size: Vector3, position: Vector3, colour: Color3): Part
	local block = Instance.new("Part")
	block.Name = name
	block.Size = size
	block.Position = position
	block.Anchored = true
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.Color = colour
	block.Material = Enum.Material.SmoothPlastic
	block.Parent = parent
	return block
end

--[[
	A label floating over something, so the map explains itself.

	`maxDistance` is how far away it stops being drawn. A lobby with seven belts is
	seven labels, and a wall of floating words the player can read from across the
	room is exactly the clutter the HUD went to some trouble to avoid — so a belt
	says its name to whoever is standing near it and to nobody else.
]]
function MapKit.label(anchor: BasePart, text: string, maxDistance: number?): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(220, 60)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	--[[
		NOT on top. A label drawn through walls and rails is read from anywhere,
		which is the opposite of what `maxDistance` is for — and in practice an
		AlwaysOnTop billboard did not draw at all in this place while a plain one
		did, tested side by side on the same belt. Plain is what a sign is anyway:
		if the belt is behind something, so is its name.
	]]
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = maxDistance or math.huge
	billboard.Parent = anchor

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Text = text
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0
	title.Parent = billboard

	return billboard
end

--[[
	Clears the workspace, keeping only what is not a map.

	Said out loud first: a map that declares tags is a map somebody BUILT, and from
	the inside a wipe looks like their work vanished. The count is taken before the
	first thing is destroyed.
]]
function MapKit.clearWorkspace(logger: Logger, builder: string)
	local tagged = 0
	for _, name in MapBindings.TAGS do
		for _, tag in (if typeof(name) == "table" then name else { name }) do
			tagged += #CollectionService:GetTagged(tag)
		end
	end
	if tagged > 0 then
		logger:warn(`{builder} cleared a map that declared {tagged} tagged objects.`)
	end

	for _, child in workspace:GetChildren() do
		if not child:IsA("Terrain") and not child:IsA("Camera") then
			child:Destroy()
		end
	end
end

--[[
	The Coin to build from, in order of preference.

	1. ONE ALREADY IN THE PLACE — a Model or a MeshPart, never a bare Part, and
	   never one inside a builder's own folder. A bare Part is what the fallback
	   makes, so accepting one means a saved place starts cloning its own cylinders.
	   Taken aside BEFORE any wipe, because the wipe would destroy it.
	2. THE ONE THE THEME NAMES, fetched once and cloned for every pickup.
	3. Nothing — the caller falls back to a cylinder.
]]
function MapKit.coinTemplate(logger: Logger, ownFolders: { string }): (PVInstance?, string)
	for _, instance in CollectionService:GetTagged(MapBindings.TAGS.coin) do
		local usable = instance:IsA("Model") or instance:IsA("MeshPart")
		local ours = false
		for _, folder in ownFolders do
			if instance:FindFirstAncestor(folder) then
				ours = true
			end
		end
		if usable and instance:IsDescendantOf(workspace) and not ours then
			local template = instance:Clone()
			CollectionService:RemoveTag(template, MapBindings.TAGS.coin)
			return template, "the map's own tagged Coin"
		end
	end

	local id = Config.Theme.models and Config.Theme.models.coin
	if typeof(id) ~= "number" or id <= 0 then
		return nil, "cylinders — no model was available"
	end

	local ok, result = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if not ok then
		logger:warn(`Coin model {id} could not be loaded ({result})`)
		return nil, "cylinders — the model could not be loaded"
	end

	-- LoadAsset hands back a Model holding whatever was published: a Model for an
	-- assembly, a bare MeshPart for a single mesh. Either is placeable.
	local container = result :: Model
	local template: PVInstance? = nil
	for _, child in container:GetChildren() do
		if child:IsA("PVInstance") then
			template = child
			child.Parent = nil
			break
		end
	end
	container:Destroy()

	if not template then
		logger:warn(`Coin model {id} holds nothing that can be placed`)
		return nil, "cylinders — the model held nothing placeable"
	end
	return template, `asset {id}`
end

--[[ One Coin, from the template or as a cylinder standing on edge. ]]
function MapKit.coin(parent: Instance, name: string, position: Vector3, template: PVInstance?): Instance
	local coin: Instance
	if template then
		local clone = template:Clone()
		clone.Name = name
		clone.Parent = parent
		clone:PivotTo(CFrame.new(position))
		coin = clone
	else
		-- A cylinder's axis runs along X, so a thin X is a disc on edge: the
		-- client's turn around Y then reads as a coin spinning, not a wheel rolling.
		local block = MapKit.part(parent, name, Vector3.new(0.6, 3, 3), position, MapKit.COLOURS.coin)
		block.Shape = Enum.PartType.Cylinder
		block.Material = Enum.Material.Metal
		coin = block
	end
	CollectionService:AddTag(coin, MapBindings.TAGS.coin)
	return coin
end

--[[ The colour a belt's rails wear: the tier, readable from the far side of a lobby. ]]
local TIER_COLOURS: { { at: number, colour: Color3 } } = {
	{ at = 500, colour = Color3.fromRGB(247, 197, 37) },
	{ at = 200, colour = Color3.fromRGB(229, 51, 60) },
	{ at = 100, colour = Color3.fromRGB(255, 140, 40) },
	{ at = 50, colour = Color3.fromRGB(150, 60, 220) },
	{ at = 10, colour = Color3.fromRGB(59, 178, 240) },
	{ at = 3, colour = Color3.fromRGB(92, 201, 74) },
	{ at = 0, colour = Color3.fromRGB(140, 150, 176) },
}

local function tierColour(multiplier: number): Color3
	for _, tier in TIER_COLOURS do
		if multiplier >= tier.at then
			return tier.colour
		end
	end
	return TIER_COLOURS[#TIER_COLOURS].colour
end

--[[
	A treadmill that looks like one: a base, a dark belt with a moving grain, two
	rails in the colour of its tier, and its multiplier floating above.

	THE BASE CARRIES THE TAG. MapBindings measures the belt by the tagged part's box
	plus a margin, and the base is the whole footprint; tagging the rails as well
	would count a player brushing past one as standing on it.

	`facing` is the direction the belt runs — the way the player faces to use it.
]]
function MapKit.treadmill(parent: Instance, multiplier: number, position: Vector3, facing: Vector3): Model
	local model = Instance.new("Model")
	model.Name = `Treadmill{multiplier}`
	model.Parent = parent

	local look = CFrame.lookAt(position, position + facing)
	local function place(block: BasePart, offset: Vector3)
		block.CFrame = look * CFrame.new(offset)
	end

	local base = MapKit.part(model, "Base", Vector3.new(8, 1, 16), position, MapKit.COLOURS.beltBase)
	place(base, Vector3.zero)
	MapKit.surface(base, "Steel", Color3.fromRGB(200, 204, 214))
	base:SetAttribute("Multiplier", multiplier)
	CollectionService:AddTag(base, MapBindings.TAGS.treadmill)

	local belt = MapKit.part(model, "Belt", Vector3.new(6, 0.3, 15), position, MapKit.COLOURS.beltSurface)
	belt.Material = Enum.Material.Fabric
	place(belt, Vector3.new(0, 0.6, 0))

	-- The grain the client scrolls: what turns a black rectangle into a belt.
	local grain = Instance.new("Texture")
	grain.Name = "Belt"
	grain.Face = Enum.NormalId.Top
	grain.Texture = "rbxassetid://4621488899"
	grain.StudsPerTileU = 3
	grain.StudsPerTileV = 3
	grain.Transparency = 0.55
	grain.Parent = belt

	local colour = tierColour(multiplier)
	for _, side in { -1, 1 } do
		local rail = MapKit.part(model, "Rail", Vector3.new(0.8, 1.4, 16), position, colour)
		rail.Material = Enum.Material.Metal
		place(rail, Vector3.new(side * 3.6, 0.9, 0))
	end

	-- A console at the FAR end of the belt — the end the player runs towards, not
	-- the end they step on from. At the near end it stood between the room and the
	-- belt and hid the thing it was meant to dress.
	local console = MapKit.part(model, "Console", Vector3.new(7, 3.2, 1), position, colour)
	MapKit.surface(console, "Steel", colour)
	place(console, Vector3.new(0, 2, 8.2))

	-- A neon bar along the top of the console and a light in its colour: the
	-- machine is on, and a row of them reads as a row of machines from the door.
	local bar = MapKit.part(model, "Glow", Vector3.new(7, 0.35, 0.35), position, colour)
	bar.Material = Enum.Material.Neon
	place(bar, Vector3.new(0, 3.8, 8.2))
	MapKit.light(bar, colour, 1.6, 16)

	model.PrimaryPart = base
	MapKit.label(base, `x{multiplier}`, 30)

	return model
end

--[[ The Roblox spawn, which is also the Hub. ]]
function MapKit.spawn(parent: Instance, position: Vector3, size: number): SpawnLocation
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(size, 1, size)
	spawn.Position = position
	spawn.Anchored = true
	spawn.Color = MapKit.COLOURS.trim
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = parent
	return spawn
end

return MapKit
