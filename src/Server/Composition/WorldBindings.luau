--!strict
--[[
	WorldBindings — connects the tagged parts of the sky to the use cases.

	The generator drops tags (Ring, Wall, Altar, Gate, LaunchPad, Perch); here, and
	only here, does touching one become a game action.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SkyBuilder = require(script.Parent.Parent.World.SkyBuilder)

local WorldBindings = {}

local TAGS = SkyBuilder.TAGS
local RING_COOLDOWN = 1.5
local WALL_COOLDOWN = 1.5

local function playerFromTouch(hit: BasePart): Player?
	local character = hit.Parent
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

--[[ Connects a tag to a handler, for the parts already there and the ones to come. ]]
local function onTagged(tag: string, handler: (Instance) -> ())
	for _, instance in CollectionService:GetTagged(tag) do
		handler(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(handler)
end

function WorldBindings.bind(container, sky: Folder)
	local useCases = container.useCases
	local ringSeen: { [Player]: { [BasePart]: number } } = {}
	local lastWall: { [Player]: number } = {}

	local function touchedRecently(memory, player: Player, part: BasePart, cooldown: number): boolean
		local now = os.clock()
		memory[player] = memory[player] or {}
		local previous = memory[player][part]
		if previous and now - previous < cooldown then
			return true
		end
		memory[player][part] = now
		return false
	end

	--[[
		Collecting a ring, shared by the physical touch and the magnet.

		A ring is wide: without a cooldown a single crossing fires many times, and the
		magnet would otherwise let a player farm the same ring from a distance.
	]]
	local function collectRing(player: Player, sensor: BasePart)
		if touchedRecently(ringSeen, player, sensor, RING_COOLDOWN) then
			return
		end
		useCases.collectRing:run(player, sensor:GetAttribute("Value") or 0)
	end

	onTagged(TAGS.ring, function(instance)
		local sensor = instance :: BasePart
		sensor.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if player then
				collectRing(player, sensor)
			end
		end)
	end)

	onTagged(TAGS.altar, function(instance)
		local sensor = instance :: BasePart
		sensor.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if player then
				useCases.bankPouch:run(player)
			end
		end)
	end)

	onTagged(TAGS.wall, function(instance)
		local wall = instance :: BasePart
		wall.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if not player then
				return
			end
			-- One wall, one death: a body brushing along a slab touches it every frame.
			local now = os.clock()
			if lastWall[player] and now - lastWall[player] < WALL_COOLDOWN then
				return
			end
			lastWall[player] = now
			useCases.crashFlight:run(player)
		end)
	end)

	onTagged(TAGS.launchPad, function(instance)
		local pad = instance :: BasePart
		pad.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if player then
				useCases.startFlight:run(player)
			end
		end)
	end)

	-- Moving hazards: a single loop for the whole sky.
	local drifting = CollectionService:GetTagged(TAGS.drifting)
	local rotating = CollectionService:GetTagged(TAGS.rotating)
	CollectionService:GetInstanceAddedSignal(TAGS.drifting):Connect(function(instance)
		table.insert(drifting, instance)
	end)
	CollectionService:GetInstanceAddedSignal(TAGS.rotating):Connect(function(instance)
		table.insert(rotating, instance)
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime

		for _, instance in drifting do
			local wall = instance :: BasePart
			if wall.Parent then
				local origin = wall:GetAttribute("DriftOrigin") or 0
				local range = wall:GetAttribute("DriftRange") or 0
				local speed = wall:GetAttribute("DriftSpeed") or 0
				local offset = math.sin(elapsed * speed * 0.1) * range * 0.5
				wall.Position = Vector3.new(wall.Position.X, wall.Position.Y, origin + offset)
			end
		end

		for _, instance in rotating do
			local bar = instance :: BasePart
			if bar.Parent then
				bar.CFrame *= CFrame.Angles((bar:GetAttribute("RotationSpeed") or 1) * deltaTime, 0, 0)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		ringSeen[player] = nil
		lastWall[player] = nil
	end)

	return { folder = sky, collectRing = collectRing }
end

return WorldBindings
