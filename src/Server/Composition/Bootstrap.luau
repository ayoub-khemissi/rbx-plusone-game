--!strict
--[[
	Bootstrap — demarrage du serveur : construit, branche, puis fait tourner.

	Trois boucles seulement :
	  1. ECHANTILLONNAGE : mesure le deplacement reel et credite les pas ;
	  2. SAUVEGARDE      : ecrit periodiquement les profils ;
	  3. ARRET           : sauvegarde tout le monde avant la fermeture du serveur.
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
local WorldBuilder = require(script.Parent.Parent.World.WorldBuilder)
local CharacterProbe = require(script.Parent.Parent.Adapters.Roblox.CharacterProbe)

local Bootstrap = {}

--[[ Boucle d'echantillonnage : le serveur observe, le client ne declare rien. ]]
local function startSampling(container)
	local interval = Config.Balance.movement.sampleInterval
	local accumulator = 0

	RunService.Heartbeat:Connect(function(deltaTime)
		accumulator += deltaTime
		if accumulator < interval then
			return
		end
		accumulator = 0

		local now = container.clock.monotonic()

		for _, player in Players:GetPlayers() do
			local reading = CharacterProbe.read(player)
			if reading then
				container.useCases.awardMovement:run(player, {
					position = reading.position,
					walkSpeed = reading.walkSpeed,
					at = now,
				})
				container.useCases.enforceZoneAccess:run(player, reading.position)
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
			container.ports.logger:warn(`Chargement du profil de {player.Name} : {result.code}`)
		end

		-- A chaque reapparition, on repart d'une position de reference propre.
		player.CharacterAdded:Connect(function()
			local session = container.sessions:forPlayer(player)
			if session then
				session.lastPosition = nil
				session.lastSampleAt = nil
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

	local worldFolder = WorldBuilder.new({
		config = container.config,
		layout = container.domain.layout,
		ladder = container.domain.ladder,
		logger = ports.logger,
	}):build()

	local world = WorldBindings.bind(container, worldFolder)
	RemoteBindings.bind(container, remotes, world)

	bindPlayers(container)
	startSampling(container)
	startAutosave(container)

	ports.logger:info("Serveur pret 🐒")
	return container
end

return Bootstrap
