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

local MapBindings = require(script.Parent.MapBindings)

local Sandbox = {}

local FLOOR_SIZE = Vector3.new(260, 4, 180)
local PAD = Vector3.new(16, 1, 16)
local BELT = Vector3.new(14, 1, 26)

local COLOURS = {
	floor = Color3.fromRGB(74, 82, 104),
	shop = Color3.fromRGB(229, 51, 60),
	prestige = Color3.fromRGB(59, 178, 240),
	idle = Color3.fromRGB(152, 156, 172),
	finish = Color3.fromRGB(92, 201, 74),
	belt = Color3.fromRGB(150, 60, 220),
}

--[[ The belts to lay out, in the order the shop will eventually sell them. ]]
local BELTS = { 1.5, 3, 10, 50, 100, 200, 500 }

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	colour: Color3
): BasePart
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

function Sandbox.build()
	-- Everything the previous map left behind, including a previous sandbox.
	for _, child in workspace:GetChildren() do
		if not child:IsA("Terrain") and not child:IsA("Camera") then
			child:Destroy()
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = "Sandbox"
	folder.Parent = workspace

	part(folder, "Floor", FLOOR_SIZE, Vector3.new(0, 0, 0), COLOURS.floor)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 2.5, 60)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(247, 197, 37)
	spawn.Parent = folder

	-- A checkpoint at the spawn, so a fall has somewhere to return to.
	local checkpoint = part(folder, "Checkpoint", PAD, Vector3.new(0, 2.5, 44), COLOURS.floor)
	checkpoint.Transparency = 0.6
	checkpoint.CanCollide = false
	checkpoint:SetAttribute("StageId", 1)
	CollectionService:AddTag(checkpoint, MapBindings.TAGS.checkpoint)

	local pads = {
		{ name = "ShopPad", tag = MapBindings.TAGS.shopPad, colour = COLOURS.shop, x = -60, text = "SHOP" },
		{
			name = "PrestigePad",
			tag = MapBindings.TAGS.prestigePad,
			colour = COLOURS.prestige,
			x = -30,
			text = "REBIRTH",
		},
		{ name = "AfkPad", tag = MapBindings.TAGS.idlePad, colour = COLOURS.idle, x = 0, text = "AFK" },
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
