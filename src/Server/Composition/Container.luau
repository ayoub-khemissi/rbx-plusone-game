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
local StageLadder = require(Shared.Domain.Run.StageLadder)
local LevelCurve = require(Shared.Domain.Run.LevelCurve)
local SpeedCurve = require(Shared.Domain.Movement.SpeedCurve)
local MovementAccounting = require(Shared.Domain.Movement.MovementAccounting)
local JumpBudget = require(Shared.Domain.Movement.JumpBudget)
local DashPolicy = require(Shared.Domain.Movement.DashPolicy)
local Multipliers = require(Shared.Domain.Movement.Multipliers)
local Progression = require(Shared.Domain.Movement.Progression)
local PrestigePolicy = require(Shared.Domain.Prestige.PrestigePolicy)
local IdleAccrual = require(Shared.Domain.Idle.IdleAccrual)
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

local UseCases = Application.UseCases
local LoadPlayerProfile = require(UseCases.LoadPlayerProfile)
local SavePlayerProfile = require(UseCases.SavePlayerProfile)
local ReleasePlayer = require(UseCases.ReleasePlayer)
local SampleMovement = require(UseCases.SampleMovement)
local ReachCheckpoint = require(UseCases.ReachCheckpoint)
local FallToCheckpoint = require(UseCases.FallToCheckpoint)
local RequestJump = require(UseCases.RequestJump)
local NoteLanded = require(UseCases.NoteLanded)
local RequestDash = require(UseCases.RequestDash)
local CollectCoin = require(UseCases.CollectCoin)
local PerformPrestige = require(UseCases.PerformPrestige)
local AccrueIdleReward = require(UseCases.AccrueIdleReward)
local BuyUpgrade = require(UseCases.BuyUpgrade)
local ProcessReceipt = require(UseCases.ProcessReceipt)
local ClaimDailyReward = require(UseCases.ClaimDailyReward)
local ClaimSessionChest = require(UseCases.ClaimSessionChest)
local RedeemCode = require(UseCases.RedeemCode)
local ListOffers = require(UseCases.ListOffers)
local PromptPurchase = require(UseCases.PromptPurchase)

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
	devMode: boolean?,
}

--[[
	The redeemable codes of this server.

	The dev codes are appended, never merged in by default: a published server is
	built without them, so no flag left on by accident can hand a player a million
	Coins.
]]
local function codesFor(monetization, devMode: boolean?)
	local list = table.create(#monetization.codes)
	for _, entry in monetization.codes do
		table.insert(list, entry)
	end

	if devMode then
		for _, entry in monetization.devCodes or {} do
			table.insert(list, entry)
		end
	end

	return list
end

function Container.new(options: Options)
	local config = options.config or require(Shared.Config)
	local ports = options.ports
	local balance = config.Balance
	local monetization = config.Monetization

	-- `now()` is an absolute date: boosts and the daily streak must survive a
	-- disconnection. `monotonic()` only measures durations, like the dash cooldown.
	local clock = ports.clock or { now = os.time, monotonic = os.clock }

	local catalog = UpgradeCatalog.new(config.Upgrades)
	local ladder = StageLadder.new(config.Stages)
	local levels = LevelCurve.new(balance.level)
	local curve = SpeedCurve.new(balance.speedCurve)
	local accounting = MovementAccounting.new(balance.movement)
	local jumpBudget = JumpBudget.new(balance.movement)
	local dashPolicy = DashPolicy.new(balance.dash)
	local prestigePolicy = PrestigePolicy.new(balance.prestige)
	local multipliers = Multipliers.new({
		catalog = catalog,
		prestigePolicy = prestigePolicy,
		passEffects = passEffectsFrom(config.Passes),
	})
	local progression = Progression.new({
		curve = curve,
		accounting = accounting,
		multipliers = multipliers,
		jumpBudget = jumpBudget,
		dashPolicy = dashPolicy,
		tuning = balance.progression,
	})

	local idle = IdleAccrual.new(balance.afk)
	local boosts = BoostStack.new(monetization.boosts)
	local products = ProductCatalog.new(config.Products)
	local daily = RewardSchedule.new(monetization.daily)
	local chest = IntervalReward.new(monetization.sessionChest)
	local codes = PromoCodes.new(codesFor(monetization, options.devMode))
	local offers = OfferEngine.new(monetization.offers)

	local domain = {
		catalog = catalog,
		ladder = ladder,
		levels = levels,
		curve = curve,
		accounting = accounting,
		jumpBudget = jumpBudget,
		dashPolicy = dashPolicy,
		multipliers = multipliers,
		progression = progression,
		prestigePolicy = prestigePolicy,
		idle = idle,
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
		levels = levels,
		progression = progression,
		multipliers = multipliers,
		prestigePolicy = prestigePolicy,
		jumpBudget = jumpBudget,
		dashPolicy = dashPolicy,
		boosts = boosts,
		idle = idle,
		clock = clock,
	})

	-- Where a player goes with no checkpoint yet. The map owns the real position:
	-- Bootstrap mutates this table once it has found the SpawnLocation.
	local hubPoint = { x = 0, y = 0, z = 0 }

	local base = {
		sessions = sessions,
		snapshots = snapshots,
		clock = clock,
		hubPoint = hubPoint,
		chestKey = monetization.sessionChest.key,
		labels = config.Theme.labels,
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

		sampleMovement = SampleMovement.new(deps()),
		reachCheckpoint = ReachCheckpoint.new(deps()),
		fallToCheckpoint = FallToCheckpoint.new(deps()),
		requestJump = RequestJump.new(deps()),
		noteLanded = NoteLanded.new(deps()),
		requestDash = RequestDash.new(deps()),
		collectCoin = CollectCoin.new(deps()),
		performPrestige = PerformPrestige.new(deps({ save = saveProfile })),
		accrueIdleReward = AccrueIdleReward.new(deps(withRewards)),

		buyUpgrade = BuyUpgrade.new(deps()),
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
		hubPoint = hubPoint,
		sessions = sessions,
		snapshots = snapshots,
		rewards = rewards,
		useCases = useCases,
	}
end

return Container
