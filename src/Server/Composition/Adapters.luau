--!strict
--[[
	Adapters — fabrique les implementations concretes des ports.

	C'est le seul endroit qui decide QUELLE technologie realise quel port. Changer
	de solution de sauvegarde (DataStore, MemoryStore, service externe) se fait ici,
	sans toucher au domaine ni aux cas d'usage.
]]

local RunService = game:GetService("RunService")

local Shared = require(script.Parent.Parent.Shared)
local Config = require(Shared.Config)

local Adapters = script.Parent.Parent.Adapters
local DataStoreProfileRepository = require(Adapters.Persistence.DataStoreProfileRepository)
local InMemoryProfileRepository = require(Adapters.Persistence.InMemoryProfileRepository)
local AttributeStatsPublisher = require(Adapters.Replication.AttributeStatsPublisher)
local RemoteNotifier = require(Adapters.Replication.RemoteNotifier)
local HumanoidActuator = require(Adapters.Roblox.HumanoidActuator)
local CharacterTeleporter = require(Adapters.Roblox.CharacterTeleporter)
local MarketplaceGateway = require(Adapters.Roblox.MarketplaceGateway)
local Logger = require(Adapters.Roblox.Logger)

local AdaptersFactory = {}

--[[ En Studio sans acces aux API, DataStoreService leve : on bascule en memoire
	pour que le jeu reste testable au lieu de refuser toutes les sauvegardes. ]]
local function buildRepository(logger)
	local persistence = Config.Balance.persistence

	local ok, repository = pcall(function()
		local created = DataStoreProfileRepository.new(persistence)
		-- Sonde : declenche l'erreur des maintenant si l'acces est refuse.
		created.store:GetAsync("sonde_demarrage")
		return created
	end)

	if ok then
		logger:info("Sauvegarde : DataStore actif")
		return repository
	end

	logger:warn(`Sauvegarde : DataStore indisponible ({tostring(repository)}), passage en memoire`)
	return InMemoryProfileRepository.new()
end

function AdaptersFactory.build(remotes)
	local logger = Logger.new("SingeRapide")
	local clock = { now = os.time, monotonic = os.clock }

	local ports = {
		repository = buildRepository(logger),
		publisher = AttributeStatsPublisher.new(),
		notifier = RemoteNotifier.new(remotes.events.Notify, { now = os.clock }),
		actuator = HumanoidActuator.new(Config.Balance.session.obstacleSpeedPenalty),
		teleporter = CharacterTeleporter.new(),
		passGateway = MarketplaceGateway.new(Config.Passes, logger),
		clock = clock,
		logger = logger,
	}

	-- Le meme adaptateur realise les deux ports lies a la boutique Roblox.
	ports.marketplace = ports.passGateway

	if RunService:IsStudio() then
		logger:info("Mode Studio detecte")
	end

	return ports
end

return AdaptersFactory
