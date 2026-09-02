--!strict
--[[
	Sandbox — a bare platform to test the pads on, built at start-up.

	STUDIO ONLY, and it CLEARS the workspace before it builds. Bootstrap only calls
	it in development mode, for the same reason the dev codes only exist there: a
	published server that wiped its own map would be a very short incident.

	It exists because the mechanics have to be walked on to be judged, and hand
	building a lobby to test a belt is a poor use of an afternoon. It is not the
	game's map and never will be — the real ones are built in Studio and read
	through the tags in docs/MAP.md, which is exactly what this places. The starting
	area a player actually sees is Lobby, built from the same kit.

	Everything here is tagged the same way a hand-built map would be. If a pad works
	on this platform and not in a real map, the difference is the map's tags, not
	the server.
]]

local CollectionService = game:GetService("CollectionService")

local MapBindings = require(script.Parent.MapBindings)
local MapKit = require(script.Parent.MapKit)

local Sandbox = {}

-- Everything the platform builds lives under one folder, which is also how it
-- knows not to mistake its own leftovers for a map. Named outwards so Bootstrap
-- can spot the leftovers of a run that was saved.
local FOLDER = "Sandbox"
Sandbox.FOLDER = FOLDER

local FLOOR_SIZE = Vector3.new(260, 4, 180)
local PAD = Vector3.new(16, 1, 16)

--[[ The belts to lay out, in the order the shop will eventually sell them. ]]
local BELTS = { 1.5, 3, 10, 50, 100, 200, 500 }

--[[
	Builds the platform, clearing whatever was there.

	CALLED TWO WAYS. Bootstrap calls it at server start, behind the attribute, and
	then it lives only as long as the session. From the Studio command bar it builds
	into the place you are EDITING, where it stays and where saving keeps it:

		require(game.ServerScriptService.Server.Composition.Sandbox).build()

	That is the difference worth knowing before pressing it. The first is a test
	platform; the second replaces your map with one.
]]
function Sandbox.build(logger)
	logger = MapKit.loggerOr(logger, "Sandbox")

	-- Taken aside before the wipe, which would otherwise destroy it.
	local template, source = MapKit.coinTemplate(logger, { FOLDER, "Lobby" })
	MapKit.clearWorkspace(logger, "Sandbox")
	logger:info("Remove the Sandbox attribute from the Workspace to keep your own map.")

	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder.Parent = workspace

	MapKit.part(folder, "Floor", FLOOR_SIZE, Vector3.new(0, 0, 0), MapKit.COLOURS.floor)
	MapKit.spawn(folder, Vector3.new(0, 2.5, 60), 12)

	local pads = {
		{
			name = "ShopPad",
			tag = MapBindings.TAGS.shopPad,
			colour = MapKit.COLOURS.shop,
			x = -60,
			text = "SHOP",
		},
		{
			name = "PrestigePad",
			tag = MapBindings.TAGS.prestigePad,
			colour = MapKit.COLOURS.prestige,
			x = -30,
			text = "REBIRTH",
		},
	}

	for _, pad in pads do
		local block = MapKit.part(folder, pad.name, PAD, Vector3.new(pad.x, 2.5, 20), pad.colour)
		CollectionService:AddTag(block, pad.tag)
		MapKit.label(block, pad.text)
	end

	--[[
		One finish plate per course, so the whole ladder can be walked in a minute.
		In a real map there is one of these, at the end of its course.
	]]
	for stageId = 1, 10 do
		local x = -108 + (stageId - 1) * 24
		local plate = MapKit.part(
			folder,
			`FinishPad{stageId}`,
			Vector3.new(18, 1, 18),
			Vector3.new(x, 2.5, -30),
			MapKit.COLOURS.finish
		)
		plate:SetAttribute("StageId", stageId)
		CollectionService:AddTag(plate, MapBindings.TAGS.finishPad)
		MapKit.label(plate, `FINISH {stageId}`)
	end

	--[[
		A row of Coins to run along. They carry no `Value`, so they are worth what
		Balance says — which is what a builder gets from dropping a tagged model and
		setting nothing. Said out loud either way: "why are my Coins cylinders" is a
		question the console should already have answered.
	]]
	logger:info(`Coins built from {source}`)
	for index = 1, 8 do
		MapKit.coin(folder, `Coin{index}`, Vector3.new(-42 + (index - 1) * 12, 5, 4), template)
	end
	if template then
		template:Destroy()
	end

	for index, multiplier in BELTS do
		local x = -96 + (index - 1) * 32
		MapKit.treadmill(folder, multiplier, Vector3.new(x, 2.5, -70), Vector3.new(0, 0, 1))
	end

	return folder
end

return Sandbox
