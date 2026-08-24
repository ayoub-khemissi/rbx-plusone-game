--!strict
--[[
	Container — the composition root.

	The ONLY place where the pieces are assembled: configuration -> domain objects ->
	use cases, with ports plugged into adapters. Everything else only knows what it
	is handed.

	Tests mount this very container with fake adapters, so the production wiring is
	covered by the test suite too.
]]

local Shared = require(script.Parent.Parent.Shared)

local UpgradeCatalog = require(Shared.Domain.Economy.UpgradeCatalog)
local TierLadder = require(Shared.Domain.Run.TierLadder)
local SkyLayout = require(Shared.Domain.Run.SkyLayout)
local SpeedCurve = require(Shared.Domain.Flight.SpeedCurve)
local FlightAccounting = require(Shared.Domain.Flight.FlightAccounting)
local Multipliers = require(Shared.Domain.Flight.Multipliers)
local Progression = require(Shared.Domain.Flight.Progression)
local MoltPolicy = require(Shared.Domain.Molt.MoltPolicy)
local Clutch = require(Shared.Domain.Hatchery.Clutch)
local RarityTable = require(Shared.Domain.Hatchery.RarityTable)
local DragonCatalog = require(Shared.Domain.Hatchery.DragonCatalog)
local BoostStack = require(Shared.Domain.Monetization.BoostStack)
local ProductCatalog = require(Shared.Domain.Monetization.ProductCatalog)
local RewardSchedule = require(Shared.Domain.Monetization.RewardSchedule)
local IntervalReward = require(Shared.Domain.Monetization.IntervalReward)
local PromoCodes = require(Shared.Domain.Monetization.PromoCodes)
local OfferEngine = require(Shared.Domain.Monetization.OfferEngine)

local Application = script.Parent.Parent.Application
local SessionRegistry = require(Application.SessionRegistry)
local Snapshot = require(Application.Snapshot)
local RewardApplier = require(Application.RewardApplier)
local EggRoller = require(Application.EggRoller)

local UseCases = Application.UseCases
local LoadPlayerProfile = require(UseCases.LoadPlayerProfile)
local SavePlayerProfile = require(UseCases.SavePlayerProfile)
local ReleasePlayer = require(UseCases.ReleasePlayer)
local StartFlight = require(UseCases.StartFlight)
local SampleFlight = require(UseCases.SampleFlight)
local BankPouch = require(UseCases.BankPouch)
local CrashFlight = require(UseCases.CrashFlight)
local CollectRing = require(UseCases.CollectRing)
local BuyUpgrade = require(UseCases.BuyUpgrade)
local PerformMolt = require(UseCases.PerformMolt)
local PlaceEgg = require(UseCases.PlaceEgg)
local CollectHatchling = require(UseCases.CollectHatchling)
local PerchAtNest = require(UseCases.PerchAtNest)
local ProcessReceipt = require(UseCases.ProcessReceipt)
local ClaimDailyReward = require(UseCases.ClaimDailyReward)
local ClaimSessionChest = require(UseCases.ClaimSessionChest)
local RedeemCode = require(UseCases.RedeemCode)
local ListOffers = require(UseCases.ListOffers)
local PromptPurchase = require(UseCases.PromptPurchase)

local Container = {}

local EXTRA_SLOTS_PER_PASS = 2

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
	random: any?,
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

	-- `now()` is an absolute date: incubation, boosts and the daily streak must
	-- survive a disconnection. `monotonic()` only measures durations.
	local clock = ports.clock or { now = os.time, monotonic = os.clock }
	local random = ports.random or { nextNumber = math.random }

	local catalog = UpgradeCatalog.new(config.Upgrades)
	local ladder = TierLadder.new(config.Tiers)
	local layout = SkyLayout.new(balance.sky, config.Tiers)
	local curve = SpeedCurve.new(balance.speedCurve)
	local accounting = FlightAccounting.new(balance.flight)
	local moltPolicy = MoltPolicy.new(balance.molt)
	local multipliers = Multipliers.new({
		catalog = catalog,
		moltPolicy = moltPolicy,
		passEffects = passEffectsFrom(config.Passes),
	})
	local progression = Progression.new({
		curve = curve,
		accounting = accounting,
		multipliers = multipliers,
		tuning = balance.progression,
	})

	local rarities = RarityTable.new(monetization.rarities)
	local dragons = DragonCatalog.new(config.Dragons)
	local clutch = Clutch.new(monetization.hatchery)
	local boosts = BoostStack.new(monetization.boosts)
	local products = ProductCatalog.new(config.Products)
	local daily = RewardSchedule.new(monetization.daily)
	local chest = IntervalReward.new(monetization.sessionChest)
	local codes = PromoCodes.new(monetization.codes)
	local offers = OfferEngine.new(monetization.offers)

	local domain = {
		catalog = catalog,
		ladder = ladder,
		layout = layout,
		curve = curve,
		accounting = accounting,
		multipliers = multipliers,
		progression = progression,
		moltPolicy = moltPolicy,
		rarities = rarities,
		dragons = dragons,
		clutch = clutch,
		boosts = boosts,
		products = products,
		daily = daily,
		chest = chest,
		codes = codes,
		offers = offers,
	}

	local sessions = SessionRegistry.new()
	local snapshots = Snapshot.new({
		ladder = ladder,
		progression = progression,
		multipliers = multipliers,
		moltPolicy = moltPolicy,
		boosts = boosts,
		clutch = clutch,
		dragons = dragons,
		clock = clock,
	})
	local eggRoller = EggRoller.new({ rarities = rarities, random = random })

	-- The Nest floats at the altitude of the first tier, above the origin.
	local nestPoint = { x = 0, y = config.World.nest.altitude, z = 0 }

	local base = {
		sessions = sessions,
		snapshots = snapshots,
		eggRoller = eggRoller,
		clock = clock,
		random = random,
		nestPoint = nestPoint,
		insuranceRatio = balance.run.insuranceRatio,
		extraSlotsPerPass = EXTRA_SLOTS_PER_PASS,
		chestKey = monetization.sessionChest.key,
		passes = indexById(config.Passes),

		repository = ports.repository,
		publisher = ports.publisher,
		notifier = ports.notifier,
		actuator = ports.actuator,
		teleporter = ports.teleporter,
		passGateway = ports.passGateway,
		marketplace = ports.marketplace,
		logger = ports.logger,
	}

	for key, value in domain do
		base[key] = value
	end

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
				-- Keep the save clean: expired boosts go on load.
				function(session, now)
					boosts:prune(session.profile, now)
				end,
				-- The session chest restarts from zero on every connection.
				function(session, now)
					chest:touch(session.profile, monetization.sessionChest.key, now)
				end,
			},
		})),
		saveProfile = saveProfile,
		releasePlayer = ReleasePlayer.new(deps({ save = saveProfile })),

		startFlight = StartFlight.new(deps()),
		sampleFlight = SampleFlight.new(deps()),
		bankPouch = BankPouch.new(deps({ save = saveProfile })),
		crashFlight = CrashFlight.new(deps({ save = saveProfile })),
		collectRing = CollectRing.new(deps()),

		buyUpgrade = BuyUpgrade.new(deps()),
		performMolt = PerformMolt.new(deps({ save = saveProfile })),
		placeEgg = PlaceEgg.new(deps({ save = saveProfile })),
		collectHatchling = CollectHatchling.new(deps({ save = saveProfile })),
		perchAtNest = PerchAtNest.new(deps()),

		processReceipt = ProcessReceipt.new(deps(withRewards)),
		claimDailyReward = ClaimDailyReward.new(deps(withRewards)),
		claimSessionChest = ClaimSessionChest.new(deps(withRewards)),
		redeemCode = RedeemCode.new(deps(withRewards)),
		listOffers = ListOffers.new(deps()),
		promptPurchase = PromptPurchase.new(deps()),
	}

	return {
		config = config,
		domain = domain,
		ports = ports,
		clock = clock,
		random = random,
		nestPoint = nestPoint,
		sessions = sessions,
		snapshots = snapshots,
		rewards = rewards,
		useCases = useCases,
	}
end

return Container
