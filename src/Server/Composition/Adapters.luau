--!strict
--[[
	Adapters — builds the concrete implementations of the ports.

	The only place that decides WHICH technology realises which port. Swapping the
	persistence solution (DataStore, MemoryStore, an external service) happens here,
	without touching the domain or the use cases.
]]

local RunService = game:GetService("RunService")

local Shared = require(script.Parent.Parent.Shared)
local Config = require(Shared.Config)

local Adapters = script.Parent.Parent.Adapters
local DataStoreProfileRepository = require(Adapters.Persistence.DataStoreProfileRepository)
local InMemoryProfileRepository = require(Adapters.Persistence.InMemoryProfileRepository)
local AttributeStatsPublisher = require(Adapters.Replication.AttributeStatsPublisher)
local RemoteNotifier = require(Adapters.Replication.RemoteNotifier)
local CharacterActuator = require(Adapters.Roblox.CharacterActuator)
local CharacterTeleporter = require(Adapters.Roblox.CharacterTeleporter)
local MarketplaceGateway = require(Adapters.Roblox.MarketplaceGateway)
local Logger = require(Adapters.Roblox.Logger)

local AdaptersFactory = {}

--[[
	In Studio without API access DataStoreService throws: fall back to memory so the
	game stays testable instead of refusing every save.
]]
local function buildRepository(logger)
	local persistence = Config.Balance.persistence

	local ok, repository = pcall(function()
		local created = DataStoreProfileRepository.new(persistence)
		-- Probe: triggers the error now if access is denied.
		created.store:GetAsync("startup_probe")
		return created
	end)

	if ok then
		logger:info("Persistence: DataStore active")
		return repository
	end

	logger:warn(`Persistence: DataStore unavailable ({tostring(repository)}), falling back to memory`)
	return InMemoryProfileRepository.new()
end

function AdaptersFactory.build(remotes)
	local logger = Logger.new("Runner")

	local ports = {
		repository = buildRepository(logger),
		publisher = AttributeStatsPublisher.new(),
		notifier = RemoteNotifier.new(remotes.events.Notify, { now = os.clock }),
		actuator = CharacterActuator.new(),
		teleporter = CharacterTeleporter.new(),
		passGateway = MarketplaceGateway.new(Config.Passes, logger),
		clock = { now = os.time, monotonic = os.clock },
		logger = logger,
	}

	-- The same adapter realises both ports tied to the Roblox store.
	ports.marketplace = ports.passGateway

	if RunService:IsStudio() then
		logger:info("Studio detected")
	end

	return ports
end

return AdaptersFactory
