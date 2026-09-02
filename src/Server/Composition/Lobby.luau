--!strict
--[[
	Lobby — the starting area, and the first Stage leading out of it.

	AN ENCLOSED ROOM. The player spawns in the exact middle of it, with the
	scoreboard on the left wall and the treadmills along the right, and the only
	way out is the doorway ahead, which opens onto Stage 1. There is no shop pad and
	no rebirth pad: those windows open from the sidebar, and a pad that acts on
	contact was a wrong step waiting to happen.

	STAGE 1 IS BUILT FOR LEVELS 1 TO 20. A character at level 1 walks at 16 studs a
	second and jumps with a power of 50, which clears about eight studs; by level 20
	it walks at 31 and clears about fifteen. The gaps start at four and grow to nine,
	so the first platforms are safe at level 1 and the last ones ask for the speed a
	player has by the end of the stage. The void underneath needs no tag.

	Built in code so it is versioned, re-runnable and identical every time. Run from
	the Studio command bar it builds into the place being edited, where it stays:

		require(game.ServerScriptService.Server.Composition.Lobby).build()

	It clears the workspace first. Decorate what it makes; do not decorate first.
]]

local CollectionService = game:GetService("CollectionService")

local MapBindings = require(script.Parent.MapBindings)
local MapKit = require(script.Parent.MapKit)
local Sandbox = require(script.Parent.Sandbox)

local Lobby = {}

local FOLDER = "Lobby"
Lobby.FOLDER = FOLDER

-- The room, in studs. Wide enough for seven belts down one side with air between.
local ROOM = Vector3.new(90, 4, 70)
local WALL_HEIGHT = 18
local WALL_THICKNESS = 2
local DOOR_WIDTH = 16
local FLOOR_TOP = ROOM.Y / 2

local BELTS = { 1.5, 3, 10, 50, 100, 200, 500 }
local BELT_X = 33
local BELT_SPACING = 9

-- The platforms of Stage 1, doorway to finish plate. `gap` is the jump before it.
local PLATFORM = Vector3.new(14, 2, 12)
local COURSE: { { gap: number, dx: number, dy: number } } = {
	{ gap = 4, dx = 0, dy = 0 },
	{ gap = 4, dx = 4, dy = 0 },
	{ gap = 5, dx = -4, dy = 1 },
	{ gap = 5, dx = 0, dy = 0 },
	{ gap = 6, dx = 6, dy = -1 },
	{ gap = 6, dx = -6, dy = 0 },
	{ gap = 7, dx = 0, dy = 2 },
	{ gap = 7, dx = 5, dy = 0 },
	{ gap = 8, dx = -5, dy = -1 },
	{ gap = 8, dx = 0, dy = 1 },
	{ gap = 9, dx = 6, dy = 0 },
	{ gap = 9, dx = -6, dy = 0 },
}

local function walls(folder: Folder)
	local colour = MapKit.COLOURS.wall
	local y = FLOOR_TOP + WALL_HEIGHT / 2
	local halfX, halfZ = ROOM.X / 2, ROOM.Z / 2
	local built: { BasePart } = {}
	local function wall(...)
		local block = MapKit.part(...)
		table.insert(built, block)
		return block
	end

	-- Back wall, and the two side walls.
	wall(
		folder,
		"WallBack",
		Vector3.new(ROOM.X + WALL_THICKNESS * 2, WALL_HEIGHT, WALL_THICKNESS),
		Vector3.new(0, y, halfZ + WALL_THICKNESS / 2),
		colour
	)
	wall(
		folder,
		"WallLeft",
		Vector3.new(WALL_THICKNESS, WALL_HEIGHT, ROOM.Z),
		Vector3.new(-halfX - WALL_THICKNESS / 2, y, 0),
		colour
	)
	wall(
		folder,
		"WallRight",
		Vector3.new(WALL_THICKNESS, WALL_HEIGHT, ROOM.Z),
		Vector3.new(halfX + WALL_THICKNESS / 2, y, 0),
		colour
	)

	-- The front wall is two pieces with the doorway between them, and a lintel
	-- over the door so the room reads as closed rather than as three walls.
	local sideWidth = (ROOM.X + WALL_THICKNESS * 2 - DOOR_WIDTH) / 2
	local z = -halfZ - WALL_THICKNESS / 2
	for _, side in { -1, 1 } do
		local x = side * (DOOR_WIDTH / 2 + sideWidth / 2)
		wall(
			folder,
			"WallFront",
			Vector3.new(sideWidth, WALL_HEIGHT, WALL_THICKNESS),
			Vector3.new(x, y, z),
			colour
		)
	end
	local lintelHeight = WALL_HEIGHT - 12
	wall(
		folder,
		"Lintel",
		Vector3.new(DOOR_WIDTH, lintelHeight, WALL_THICKNESS),
		Vector3.new(0, FLOOR_TOP + 12 + lintelHeight / 2, z),
		colour
	)

	-- A band of the accent colour along the top of every wall: the room's trim.
	local trimY = FLOOR_TOP + WALL_HEIGHT + 0.5
	MapKit.part(
		folder,
		"Trim",
		Vector3.new(ROOM.X + WALL_THICKNESS * 2, 1, WALL_THICKNESS),
		Vector3.new(0, trimY, halfZ + WALL_THICKNESS / 2),
		MapKit.COLOURS.trim
	)
	MapKit.part(
		folder,
		"Trim",
		Vector3.new(ROOM.X + WALL_THICKNESS * 2, 1, WALL_THICKNESS),
		Vector3.new(0, trimY, z),
		MapKit.COLOURS.trim
	)
	MapKit.part(
		folder,
		"Trim",
		Vector3.new(WALL_THICKNESS, 1, ROOM.Z),
		Vector3.new(-halfX - WALL_THICKNESS / 2, trimY, 0),
		MapKit.COLOURS.trim
	)
	MapKit.part(
		folder,
		"Trim",
		Vector3.new(WALL_THICKNESS, 1, ROOM.Z),
		Vector3.new(halfX + WALL_THICKNESS / 2, trimY, 0),
		MapKit.COLOURS.trim
	)

	-- Brick, on every wall at once, and only the walls: the trim stays gold plastic.
	for _, block in built do
		MapKit.surface(block, "LobbyWall", Color3.fromRGB(190, 176, 168))
	end
end

--[[
	The scoreboard: a panel on the inside of the left wall, tagged so MapBindings
	fills it. The map draws the board; the server decides who is on it.
]]
local function scoreboard(folder: Folder)
	local panel = MapKit.part(
		folder,
		"Scoreboard",
		Vector3.new(0.6, 16, 30),
		Vector3.new(-ROOM.X / 2 + 0.4, FLOOR_TOP + 10, 0),
		MapKit.COLOURS.beltSurface
	)
	panel.Material = Enum.Material.SmoothPlastic

	local frame = MapKit.part(
		folder,
		"ScoreboardFrame",
		Vector3.new(0.8, 17.2, 31.2),
		Vector3.new(-ROOM.X / 2 + 0.2, FLOOR_TOP + 10, 0),
		MapKit.COLOURS.trim
	)
	frame.Material = Enum.Material.SmoothPlastic

	CollectionService:AddTag(panel, MapBindings.TAGS.scoreboard)
end

local function course(folder: Folder, template: PVInstance?)
	-- A landing outside the door, so the first jump is not taken from a doorway.
	local z = -ROOM.Z / 2 - 12
	local landing = MapKit.part(
		folder,
		"Landing",
		Vector3.new(20, 2, 20),
		Vector3.new(0, FLOOR_TOP - 1, z),
		MapKit.COLOURS.floor
	)
	MapKit.surface(landing, "CourseWood")
	z -= 10

	local x, y = 0, FLOOR_TOP - 1
	for index, step in COURSE do
		z -= step.gap + PLATFORM.Z / 2
		x += step.dx
		y += step.dy
		local platform =
			MapKit.part(folder, `Platform{index}`, PLATFORM, Vector3.new(x, y, z), MapKit.COLOURS.floor)
		-- Planks, and every other one a shade darker so the eye counts them.
		MapKit.surface(platform, "CourseWood", if index % 2 == 0 then nil else Color3.fromRGB(200, 190, 178))
		z -= PLATFORM.Z / 2

		if index % 2 == 1 then
			MapKit.coin(folder, `Coin{index}`, Vector3.new(x, y + 4, z + PLATFORM.Z / 2), template)
		end
	end

	-- The finish, on a plate of its own at the end.
	z -= 10 + 12
	local finishFloor =
		MapKit.part(folder, "FinishFloor", Vector3.new(24, 2, 24), Vector3.new(x, y, z), MapKit.COLOURS.floor)
	MapKit.surface(finishFloor, "FinishStone")
	local plate = MapKit.part(
		folder,
		"FinishPad1",
		Vector3.new(18, 1, 18),
		Vector3.new(x, y + 1.5, z),
		MapKit.COLOURS.finish
	)
	plate:SetAttribute("StageId", 1)
	CollectionService:AddTag(plate, MapBindings.TAGS.finishPad)
	MapKit.label(plate, "FINISH 1", 60)
	finishFloor.Name = "FinishFloor"
end

function Lobby.build(logger)
	logger = MapKit.loggerOr(logger, "Lobby")

	-- Taken aside before the wipe, which would otherwise destroy it.
	local template, source = MapKit.coinTemplate(logger, { FOLDER, Sandbox.FOLDER })
	MapKit.clearWorkspace(logger, "Lobby")

	MapKit.materials()

	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder.Parent = workspace

	local floor = MapKit.part(folder, "Floor", ROOM, Vector3.new(0, 0, 0), MapKit.COLOURS.floor)
	MapKit.surface(floor, "LobbyFloor")
	walls(folder)

	-- Dead centre. The Hub is wherever this is, and a fall comes back here.
	local spawn = MapKit.spawn(folder, Vector3.new(0, FLOOR_TOP + 0.5, 0), 10)

	-- A strip of light from the spawn to the door: the one direction that matters.
	local runway = MapKit.part(
		folder,
		"Runway",
		Vector3.new(3, 0.2, ROOM.Z / 2 - 8),
		Vector3.new(0, FLOOR_TOP + 0.1, -(ROOM.Z / 4) - 3),
		MapKit.COLOURS.trim
	)
	runway.Material = Enum.Material.Neon
	runway.CanCollide = false
	MapKit.light(spawn, Color3.fromRGB(255, 236, 190), 1.2, 60)

	scoreboard(folder)

	-- The belts down the right side, all facing the back wall, heaviest last.
	for index, multiplier in BELTS do
		local z = -(#BELTS - 1) * BELT_SPACING / 2 + (index - 1) * BELT_SPACING
		MapKit.treadmill(folder, multiplier, Vector3.new(BELT_X, FLOOR_TOP + 0.5, z), Vector3.new(-1, 0, 0))
	end

	course(folder, template)
	if template then
		template:Destroy()
	end

	logger:info(`Lobby built. Coins from {source}.`)
	return folder
end

return Lobby
