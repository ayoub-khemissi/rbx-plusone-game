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
local BoostStack = require(Shared.Domain.Monetization.BoostStack)
local ProductCatalog = require(Shared.Domain.Monetization.ProductCatalog)
local RewardSchedule = require(Shared.Domain.Monetization.RewardSchedule)
local IntervalReward = require(Shared.Domain.Monetization.IntervalReward)
local PromoCodes = require(Shared.Domain.Monetization.PromoCodes)
local OfferEngine = require(Shared.Domain.Monetization.OfferEngine)
local IdleAccrual = require(Shared.Domain.Progression.IdleAccrual)

local Application = script.Parent.Parent.Application
local SessionRegistry = require(Application.SessionRegistry)
local Snapshot = require(Application.Snapshot)
local RewardApplier = require(Application.RewardApplier)

local UseCases = Application.UseCases
local LoadPlayerProfile = require(UseCases.LoadPlayerProfile)
local SavePlayerProfile = require(UseCases.SavePlayerProfile)
local ReleasePlayer = require(UseCases.ReleasePlayer)
local AwardMovement = require(UseCases.AwardMovement)
local EnforceZoneAccess = require(UseCases.EnforceZoneAccess)
local BuyUpgrade = require(UseCases.BuyUpgrade)
local PerformRebirth = require(UseCases.PerformRebirth)
local TravelToZone = require(UseCases.TravelToZone)
local CollectBanana = require(UseCases.CollectBanana)
local ProcessReceipt = require(UseCases.ProcessReceipt)
local ClaimDailyReward = require(UseCases.ClaimDailyReward)
local ClaimPlaytimeChest = require(UseCases.ClaimPlaytimeChest)
local RedeemCode = require(UseCases.RedeemCode)
local ListOffers = require(UseCases.ListOffers)
local PromptPurchase = require(UseCases.PromptPurchase)
local AccrueAfkReward = require(UseCases.AccrueAfkReward)

local Container = {}

local function indexById(entries)
	local byId = {}
	for _, entry in entries do
		byId[entry.id] = entry
	end
	return byId
end

local function passEffectsFrom(passes)
	local effects = {}
	for _, pass in passes do
		effects[pass.id] = pass.effect
	end
	return effects
end

export type Ports = {
	repository: any,
	publisher: any,
	notifier: any,
	actuator: any,
	teleporter: any,
	passGateway: any,
	marketplace: any?,
	clock: any?,
	logger: any?,
}

export type Options = {
	config: any?,
	ports: Ports,
}

function Container.new(options: Options)
	local config = options.config or require(Shared.Config)
	local ports = options.ports
	local balance = config.Balance
	local monetization = config.Monetization

	-- `now()` est une date absolue (epoch) : les boosts et le quotidien doivent
	-- survivre a une deconnexion. `monotonic()` sert aux mesures de duree.
	local clock = ports.clock or { now = os.time, monotonic = os.clock }

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

	local boosts = BoostStack.new(monetization.boosts)
	local products = ProductCatalog.new(config.Products)
	local daily = RewardSchedule.new(monetization.daily)
	local chest = IntervalReward.new(monetization.playtimeChest)
	local codes = PromoCodes.new(monetization.codes)
	local offers = OfferEngine.new(monetization.offers)
	local idle = IdleAccrual.new(monetization.afk)

	local domain = {
		catalog = catalog,
		ladder = ladder,
		layout = layout,
		curve = curve,
		accounting = accounting,
		multipliers = multipliers,
		progression = progression,
		rebirthPolicy = rebirthPolicy,
		boosts = boosts,
		products = products,
		daily = daily,
		chest = chest,
		codes = codes,
		offers = offers,
		idle = idle,
	}

	local sessions = SessionRegistry.new()
	local snapshots = Snapshot.new({
		ladder = ladder,
		progression = progression,
		multipliers = multipliers,
		rebirthPolicy = rebirthPolicy,
		boosts = boosts,
		clock = clock,
		afkCapSeconds = monetization.afk.sessionCapSeconds,
	})

	-- Dependances communes a tous les cas d'usage : ports + domaine + etat de session.
	local base = {
		sessions = sessions,
		snapshots = snapshots,
		clock = clock,
		repository = ports.repository,
		publisher = ports.publisher,
		notifier = ports.notifier,
		actuator = ports.actuator,
		teleporter = ports.teleporter,
		passGateway = ports.passGateway,
		marketplace = ports.marketplace,
		logger = ports.logger,
		catalog = catalog,
		ladder = ladder,
		layout = layout,
		progression = progression,
		rebirthPolicy = rebirthPolicy,
		boosts = boosts,
		products = products,
		daily = daily,
		chest = chest,
		chestKey = monetization.playtimeChest.key,
		codes = codes,
		offers = offers,
		idle = idle,
		passes = indexById(config.Passes),
	}

	local function deps(extra: { [string]: any }?)
		local merged = table.clone(base)
		for key, value in extra or {} do
			merged[key] = value
		end
		return merged
	end

	local saveProfile = SavePlayerProfile.new(deps())
	local rewards = RewardApplier.new(deps({ save = saveProfile }))

	local withRewards = { save = saveProfile, rewards = rewards }

	local useCases = {
		loadProfile = LoadPlayerProfile.new(deps({
			sessionHooks = {
				-- Sauvegarde propre : on jette les boosts expires au chargement.
				function(session, now)
					boosts:prune(session.profile, now)
				end,
				-- Le coffre de session repart de zero a chaque connexion.
				function(session, now)
					chest:touch(session.profile, monetization.playtimeChest.key, now)
				end,
			},
		})),
		saveProfile = saveProfile,
		releasePlayer = ReleasePlayer.new(deps({ save = saveProfile })),
		awardMovement = AwardMovement.new(deps()),
		enforceZoneAccess = EnforceZoneAccess.new(deps()),
		buyUpgrade = BuyUpgrade.new(deps()),
		performRebirth = PerformRebirth.new(deps({ save = saveProfile })),
		travelToZone = TravelToZone.new(deps()),
		collectBanana = CollectBanana.new(deps()),
		processReceipt = ProcessReceipt.new(deps(withRewards)),
		claimDailyReward = ClaimDailyReward.new(deps(withRewards)),
		claimPlaytimeChest = ClaimPlaytimeChest.new(deps(withRewards)),
		redeemCode = RedeemCode.new(deps(withRewards)),
		accrueAfkReward = AccrueAfkReward.new(deps(withRewards)),
		listOffers = ListOffers.new(deps()),
		promptPurchase = PromptPurchase.new(deps()),
	}

	return {
		config = config,
		domain = domain,
		ports = ports,
		clock = clock,
		sessions = sessions,
		snapshots = snapshots,
		rewards = rewards,
		useCases = useCases,
	}
end

return Container
