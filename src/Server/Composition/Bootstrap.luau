--!strict
--[[
	Bootstrap — server start-up: build, wire, then run.

	Only three loops:
	  1. SAMPLING — measures the real displacement and credits the flight;
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
local WorldBindings = require(script.Parent.WorldBindings)
local SkyBuilder = require(script.Parent.Parent.World.SkyBuilder)
local CharacterProbe = require(script.Parent.Parent.Adapters.Roblox.CharacterProbe)

local Bootstrap = {}

--[[
	Sampling loop: the server observes, the client declares nothing.

	The very same loop credits perching, because a player who is not flying is either
	at the Nest or on their way there.
]]
local function startSampling(container)
	local interval = Config.Balance.flight.sampleInterval
	local perchInterval = Config.Balance.run.perchInterval
	local accumulator = 0
	local perchAccumulator = 0

	RunService.Heartbeat:Connect(function(deltaTime)
		accumulator += deltaTime
		perchAccumulator += deltaTime

		if accumulator < interval then
			return
		end
		accumulator = 0

		local perching = perchAccumulator >= perchInterval
		if perching then
			perchAccumulator = 0
		end

		local now = container.clock.monotonic()

		for _, player in Players:GetPlayers() do
			local reading = CharacterProbe.read(player)
			if reading then
				container.useCases.sampleFlight:run(player, {
					position = reading.position,
					velocity = reading.velocity,
					at = now,
				})

				if perching then
					container.useCases.perchAtNest:run(player, perchInterval)
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

		-- Dying mid-flight ends the flight: the pouch was never theirs.
		player.CharacterAdded:Connect(function()
			local session = container.sessions:forPlayer(player)
			if session and session.flying then
				container.useCases.crashFlight:run(player)
			end
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
	local remotes = Net.server()
	local ports = AdaptersFactory.build(remotes)
	local container = Container.new({ ports = ports })

	local sky = SkyBuilder.new({
		config = container.config,
		layout = container.domain.layout,
		ladder = container.domain.ladder,
		logger = ports.logger,
	}):build()

	local world = WorldBindings.bind(container, sky)
	RemoteBindings.bind(container, remotes, world)

	bindPlayers(container)
	startSampling(container)
	startAutosave(container)

	ports.logger:info("Server ready 🐉")
	return container
end

return Bootstrap
