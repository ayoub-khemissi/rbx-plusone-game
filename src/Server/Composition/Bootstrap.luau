--!strict
--[[
	Bootstrap — server start-up: wire, then run.

	No world is generated here: the map is hand built and read through tags, per
	docs/MAP.md. The server only discovers what the map declares.

	Three loops:
	  1. SAMPLING — measures the real displacement, or pays the belt underfoot;
	  2. AUTOSAVE — writes the profiles periodically;
	  3. SHUTDOWN — saves everyone before the server closes.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = require(script.Parent.Parent.Shared)
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local Container = require(script.Parent.Container)
local AdaptersFactory = require(script.Parent.Adapters)
local RemoteBindings = require(script.Parent.RemoteBindings)
local MapBindings = require(script.Parent.MapBindings)
local Sandbox = require(script.Parent.Sandbox)
local CharacterProbe = require(script.Parent.Parent.Adapters.Roblox.CharacterProbe)

local Bootstrap = {}

--[[
	The Hub is wherever the map put its SpawnLocation. Falling with no checkpoint
	sends the player there, so the server has to find it rather than assume it.
]]
local function findHubPoint(container, logger)
	local spawn = nil
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			spawn = descendant
			break
		end
	end

	if not spawn then
		logger:warn("No SpawnLocation in the map: falls with no checkpoint will land at the origin")
		return
	end

	container.hubPoint.x = spawn.Position.X
	container.hubPoint.y = spawn.Position.Y + Config.Balance.run.respawnHeight
	container.hubPoint.z = spawn.Position.Z
end

--[[
	The floor of the world.

	A map does not need an invisible slab under it to catch falls: the server finds
	the lowest part of the map and treats anything below it as a fall. One less thing
	to remember when building, and it cannot be forgotten.

	A Killzone is not floor. Counting one would push the void below the very thing
	meant to catch the player — so a map that DOES lay a slab under itself and tags
	it keeps the void where it belongs, and either one kills.
]]
local function findVoidLevel(logger): number
	local lowest = math.huge
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("BasePart") and not MapBindings.isKillzone(descendant) then
			local bottom = descendant.Position.Y - descendant.Size.Y / 2
			if bottom < lowest then
				lowest = bottom
			end
		end
	end

	if lowest == math.huge then
		logger:warn("Empty map: no floor found, falls will not be detected")
		return -math.huge
	end

	local level = lowest - Config.Balance.run.voidMargin
	logger:info(`Void level set to {math.floor(level)} studs`)
	return level
end

--[[ Sampling loop: the server observes, the client declares nothing. ]]
local function startSampling(container, map, voidLevel: number)
	local interval = Config.Balance.movement.sampleInterval
	local accumulator = 0

	RunService.Heartbeat:Connect(function(deltaTime)
		accumulator += deltaTime
		if accumulator < interval then
			return
		end

		local elapsed = accumulator
		accumulator = 0
		local now = container.clock.monotonic()

		for _, player in Players:GetPlayers() do
			local reading = CharacterProbe.read(player)
			if reading then
				-- Falling out of the world is checked before crediting: the plunge
				-- itself must not pay for the distance it covers.
				if reading.position.y < voidLevel then
					map.fall(player)
				else
					--[[
						A belt REPLACES the measurement rather than adding to it.
						Crediting both would pay a player twice for walking on the
						spot, and the belt is the server's own number anyway.
					]]
					local belt = map.treadmillAt(reading.position)
					-- The client animates from this, so it is written every tick
					-- whether or not there is a belt.
					container.ports.actuator:setTreadmill(player, belt)

					if belt then
						container.useCases.runOnTreadmill:run(player, belt, elapsed)

						-- Stepping off must not read as a leap from wherever the
						-- player was standing before they got on.
						local session = container.sessions:forPlayer(player)
						if session then
							session.lastPosition = nil
							session.lastSampleAt = nil
						end
					else
						container.useCases.sampleMovement:run(player, {
							position = reading.position,
							walkSpeed = reading.walkSpeed,
							at = now,
						})
					end
				end
			end
		end
	end)
end

local function startAutosave(container)
	local interval = Config.Balance.persistence.autosaveInterval

	task.spawn(function()
		while true do
			task.wait(interval)
			container.sessions:forEach(function(session)
				container.useCases.saveProfile:run(session.userId)
			end)
		end
	end)
end

local function bindPlayers(container)
	local function onPlayerAdded(player: Player)
		container.ports.publisher:setupPlayer(player)

		local result = container.useCases.loadProfile:run(player)
		if not result.ok then
			container.ports.logger:warn(`Loading the profile of {player.Name}: {result.code}`)
		end

		-- Every new body, whatever ended the last one, goes back to the run where it
		-- left off.
		player.CharacterAdded:Connect(function()
			container.useCases.spawnAtCheckpoint:run(player)
		end)
	end

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		container.useCases.releasePlayer:run(player)
	end)

	game:BindToClose(function()
		container.sessions:forEach(function(session)
			container.useCases.saveProfile:run(session.userId)
		end)
	end)
end

function Bootstrap.start()
	-- How long a fall costs. Roblox brings the character back on its own; the
	-- server only says when, and every death in the game is paid at this rate.
	Players.RespawnTime = Config.Balance.run.respawnDelay

	local remotes = Net.server()
	local ports = AdaptersFactory.build(remotes)
	-- Studio is the only place the dev codes exist. See Config/Monetization.luau.
	local devMode = RunService:IsStudio()
	local container = Container.new({ ports = ports, devMode = devMode })

	--[[
		The sandbox CLEARS the workspace, so it is fenced behind the same flag as the
		dev codes and behind an attribute on top. A published server that wiped its
		own map would be a very short incident, and one flag is not enough fence for
		something that destructive.
	]]
	if devMode and workspace:GetAttribute("Sandbox") == true then
		Sandbox.build()
		ports.logger:info("Sandbox built: the previous workspace was cleared")
	end

	-- MapBindings needs the remotes to open a panel from a hub pad.
	container.remotes = remotes

	local map = MapBindings.bind(container)
	RemoteBindings.bind(container, remotes)

	findHubPoint(container, ports.logger)
	map.report()

	bindPlayers(container)
	startSampling(container, map, findVoidLevel(ports.logger))
	startAutosave(container)

	ports.logger:info("Server ready")
	return container
end

return Bootstrap
