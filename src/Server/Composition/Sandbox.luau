--!strict
--[[
	Sandbox — a bare platform to test the pads on, built at start-up.

	STUDIO ONLY, and it CLEARS the workspace before it builds. Bootstrap only calls
	it in development mode, for the same reason the dev codes only exist there: a
	published server that wiped its own map would be a very short incident.

	It exists because the mechanics have to be walked on to be judged, and hand
	building a lobby to test a belt is a poor use of an afternoon. It is not the
	game's map and never will be — the real ones are built in Studio and read
	through the tags in docs/MAP.md, which is exactly what this places.

	Everything here is tagged the same way a hand-built map would be. If a pad works
	on this platform and not in a real map, the difference is the map's tags, not
	the server.
]]

local CollectionService = game:GetService("CollectionService")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local MapBindings = require(script.Parent.MapBindings)

local Sandbox = {}

-- Everything the platform builds lives under one folder, which is also how it
-- knows not to mistake its own leftovers for a map.
local FOLDER = "Sandbox"

local FLOOR_SIZE = Vector3.new(260, 4, 180)
local PAD = Vector3.new(16, 1, 16)
local BELT = Vector3.new(14, 1, 26)

local COLOURS = {
	floor = Color3.fromRGB(74, 82, 104),
	shop = Color3.fromRGB(229, 51, 60),
	prestige = Color3.fromRGB(59, 178, 240),
	finish = Color3.fromRGB(92, 201, 74),
	belt = Color3.fromRGB(150, 60, 220),
	coin = Color3.fromRGB(247, 197, 37),
}

--[[
	The Coin to build the row from, in order of preference.

	1. ONE ALREADY IN THE PLACE. If the map contains a tagged Coin, that is the one
	   the author wants and it needs no fetching. It is taken aside BEFORE the
	   workspace is cleared, because the wipe would otherwise destroy the very thing
	   being asked for.
	2. THE ONE THE THEME NAMES, fetched once and cloned for every pickup. LoadAsset
	   is a web request, so eight Coins would otherwise be eight round trips.
	3. A CYLINDER. The fetch can fail — the asset may be private, deleted, or the
	   request may simply not come back — and a test platform that refuses to build
	   over an unavailable model helps nobody.
]]
local function taggedCoin(): PVInstance?
	for _, instance in CollectionService:GetTagged(MapBindings.TAGS.coin) do
		--[[
			A Model or a MeshPart, never a bare Part — and never one of these.

			A bare Part is exactly what this file builds when it has nothing better,
			so accepting one means that the first time somebody SAVES a place after
			the platform has run, the platform starts cloning its own cylinders and
			never reaches for a real model again. Ignoring its own folder covers the
			same trap from the other side.
		]]
		local usable = instance:IsA("Model") or instance:IsA("MeshPart")
		if usable and instance:IsDescendantOf(workspace) and not instance:FindFirstAncestor(FOLDER) then
			local template = instance:Clone()
			-- Held aside, so it must not look like a Coin in play while it waits.
			CollectionService:RemoveTag(template, MapBindings.TAGS.coin)
			return template
		end
	end
	return nil
end

local function fetchedCoin(logger): PVInstance?
	local id = Config.Theme.models and Config.Theme.models.coin
	if typeof(id) ~= "number" or id <= 0 then
		return nil
	end

	local ok, result = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if not ok then
		logger:warn(`Coin model {id} could not be loaded ({result})`)
		return nil
	end

	--[[
		LoadAsset always hands back a Model to hold the asset, but what is INSIDE it
		is whatever was published: a Model for a built assembly, a bare MeshPart for
		a single mesh. Looking only for a Model finds nothing at all for the second
		kind, which is most of the Coins anybody would use.
	]]
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
	end
	return template
end

--[[ The belts to lay out, in the order the shop will eventually sell them. ]]
local BELTS = { 1.5, 3, 10, 50, 100, 200, 500 }

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, colour: Color3): Part
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

--[[ A label floating over a pad, so the platform explains itself. ]]
local function label(anchor: BasePart, text: string)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(220, 60)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
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
end

function Sandbox.build(logger)
	-- Taken aside before the wipe: see `taggedCoin`.
	local template = taggedCoin()

	-- Everything the previous map left behind, including a previous sandbox.
	for _, child in workspace:GetChildren() do
		if not child:IsA("Terrain") and not child:IsA("Camera") then
			child:Destroy()
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder.Parent = workspace

	part(folder, "Floor", FLOOR_SIZE, Vector3.new(0, 0, 0), COLOURS.floor)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 2.5, 60)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(247, 197, 37)
	spawn.Parent = folder

	local pads = {
		{ name = "ShopPad", tag = MapBindings.TAGS.shopPad, colour = COLOURS.shop, x = -60, text = "SHOP" },
		{
			name = "PrestigePad",
			tag = MapBindings.TAGS.prestigePad,
			colour = COLOURS.prestige,
			x = -30,
			text = "REBIRTH",
		},
	}

	for _, pad in pads do
		local block = part(folder, pad.name, PAD, Vector3.new(pad.x, 2.5, 20), pad.colour)
		CollectionService:AddTag(block, pad.tag)
		label(block, pad.text)
	end

	--[[
		One finish plate per course, so the whole ladder can be walked in a minute.
		In a real map there is one of these, at the end of its course.
	]]
	for stageId = 1, 10 do
		local x = -108 + (stageId - 1) * 24
		local plate = part(
			folder,
			`FinishPad{stageId}`,
			Vector3.new(18, 1, 18),
			Vector3.new(x, 2.5, -30),
			COLOURS.finish
		)
		plate:SetAttribute("StageId", stageId)
		CollectionService:AddTag(plate, MapBindings.TAGS.finishPad)
		label(plate, `FINISH {stageId}`)
	end

	--[[
		A row of Coins to run along. They carry no `Value`, so they are worth what
		Balance says — which is what a builder gets from dropping a tagged model and
		setting nothing.
	]]
	local source = if template then "the map's own tagged Coin" else nil
	if not template then
		template = fetchedCoin(logger)
		source = if template then `asset {Config.Theme.models.coin}` else nil
	end
	-- Said out loud either way: "why are my Coins cylinders" is a question the
	-- console should already have answered.
	logger:info(`Coins built from {source or "cylinders — no model was available"}`)

	for index = 1, 8 do
		local position = Vector3.new(-42 + (index - 1) * 12, 5, 4)
		local coin: Instance

		if template then
			local clone = template:Clone()
			clone.Name = `Coin{index}`
			clone.Parent = folder
			clone:PivotTo(CFrame.new(position))
			coin = clone
		else
			-- A cylinder's axis runs along X, so a thin X makes a disc standing on
			-- edge: the client's turn around Y then reads as a coin spinning rather
			-- than a wheel rolling.
			local block = part(folder, `Coin{index}`, Vector3.new(0.6, 3, 3), position, COLOURS.coin)
			block.Shape = Enum.PartType.Cylinder
			block.Material = Enum.Material.Metal
			coin = block
		end

		CollectionService:AddTag(coin, MapBindings.TAGS.coin)
	end

	if template then
		template:Destroy()
	end

	for index, multiplier in BELTS do
		local x = -96 + (index - 1) * 32
		local belt = part(folder, `Treadmill{multiplier}`, BELT, Vector3.new(x, 2.5, -70), COLOURS.belt)
		belt:SetAttribute("Multiplier", multiplier)
		CollectionService:AddTag(belt, MapBindings.TAGS.treadmill)
		label(belt, `x{multiplier}`)
	end

	return folder
end

return Sandbox
