--!strict
--[[
	Container — racine de composition (composition root).

	SEUL endroit du projet ou les briques sont assemblees : configuration -> objets
	de domaine -> cas d'usage, en branchant les ports sur des adaptateurs. Tout le
	reste du code ne connait que ce qu'on lui injecte.

	Les tests montent ce meme conteneur avec des adaptateurs factices : le cablage
	de production est donc couvert par la suite de tests.
]]

local Shared = require(script.Parent.Parent.Shared)

local UpgradeCatalog = require(Shared.Domain.Economy.UpgradeCatalog)
local ZoneLadder = require(Shared.Domain.Zones.ZoneLadder)
local TrackLayout = require(Shared.Domain.Zones.TrackLayout)
local SpeedCurve = require(Shared.Domain.Progression.SpeedCurve)
local MovementAccounting = require(Shared.Domain.Progression.MovementAccounting)
local Multipliers = require(Shared.Domain.Progression.Multipliers)
local Progression = require(Shared.Domain.Progression.Progression)
local RebirthPolicy = require(Shared.Domain.Rebirth.RebirthPolicy)

local SessionRegistry = require(script.Parent.Parent.Application.SessionRegistry)
local Snapshot = require(script.Parent.Parent.Application.Snapshot)

local UseCases = script.Parent.Parent.Application.UseCases
local LoadPlayerProfile = require(UseCases.LoadPlayerProfile)
local SavePlayerProfile = require(UseCases.SavePlayerProfile)
local ReleasePlayer = require(UseCases.ReleasePlayer)
local AwardMovement = require(UseCases.AwardMovement)
local EnforceZoneAccess = require(UseCases.EnforceZoneAccess)
local BuyUpgrade = require(UseCases.BuyUpgrade)
local PerformRebirth = require(UseCases.PerformRebirth)
local TravelToZone = require(UseCases.TravelToZone)
local CollectBanana = require(UseCases.CollectBanana)

local Container = {}

--[[ Transforme la liste de gamepasses en table d'effets indexee par identifiant. ]]
local function passEffectsFrom(passes)
	local effects = {}
	for _, pass in passes do
		effects[pass.id] = pass.effect
	end
	return effects
end

export type Options = {
	config: any?,
	ports: {
		repository: any,
		publisher: any,
		notifier: any,
		actuator: any,
		teleporter: any,
		passGateway: any,
		clock: any?,
		logger: any?,
	},
}

function Container.new(options: Options)
	local config = options.config or require(Shared.Config)
	local ports = options.ports
	local balance = config.Balance

	local catalog = UpgradeCatalog.new(config.Upgrades)
	local ladder = ZoneLadder.new(config.Zones)
	local layout = TrackLayout.new(balance.layout, config.Zones)
	local curve = SpeedCurve.new(balance.speedCurve)
	local accounting = MovementAccounting.new(balance.movement)
	local rebirthPolicy = RebirthPolicy.new(balance.rebirth)
	local multipliers = Multipliers.new({
		catalog = catalog,
		rebirthPolicy = rebirthPolicy,
		passEffects = passEffectsFrom(config.Passes),
	})
	local progression = Progression.new({
		curve = curve,
		accounting = accounting,
		multipliers = multipliers,
		tuning = balance.progression,
	})

	local domain = {
		catalog = catalog,
		ladder = ladder,
		layout = layout,
		curve = curve,
		accounting = accounting,
		multipliers = multipliers,
		progression = progression,
		rebirthPolicy = rebirthPolicy,
	}

	local sessions = SessionRegistry.new()
	local snapshots = Snapshot.new({
		ladder = ladder,
		progression = progression,
		multipliers = multipliers,
		rebirthPolicy = rebirthPolicy,
	})

	-- Dependances communes a tous les cas d'usage : ports + domaine + etat de session.
	local shared = {
		sessions = sessions,
		snapshots = snapshots,
		repository = ports.repository,
		publisher = ports.publisher,
		notifier = ports.notifier,
		actuator = ports.actuator,
		teleporter = ports.teleporter,
		passGateway = ports.passGateway,
		clock = ports.clock,
		logger = ports.logger,
		catalog = catalog,
		ladder = ladder,
		layout = layout,
		progression = progression,
		rebirthPolicy = rebirthPolicy,
	}

	local function deps(extra: { [string]: any }?)
		local table_ = table.clone(shared)
		for key, value in extra or {} do
			table_[key] = value
		end
		return table_
	end

	local saveProfile = SavePlayerProfile.new(deps())

	local useCases = {
		loadProfile = LoadPlayerProfile.new(deps()),
		saveProfile = saveProfile,
		releasePlayer = ReleasePlayer.new(deps({ save = saveProfile })),
		awardMovement = AwardMovement.new(deps()),
		enforceZoneAccess = EnforceZoneAccess.new(deps()),
		buyUpgrade = BuyUpgrade.new(deps()),
		performRebirth = PerformRebirth.new(deps({ save = saveProfile })),
		travelToZone = TravelToZone.new(deps()),
		collectBanana = CollectBanana.new(deps()),
	}

	return {
		config = config,
		domain = domain,
		ports = ports,
		sessions = sessions,
		snapshots = snapshots,
		useCases = useCases,
	}
end

return Container
