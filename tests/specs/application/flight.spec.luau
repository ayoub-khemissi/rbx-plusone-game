--!nocheck
--[[
	Integration tests of the Application layer: the real container is mounted with
	fake adapters, so the production wiring is covered too.
]]

local Container = require(Server.Composition.Container)
local Config = require(Config)

local SKY = Config.Balance.sky

local function build(overrides)
	local ports = {
		repository = Fakes.repository(),
		publisher = Fakes.publisher(),
		notifier = Fakes.notifier(),
		actuator = Fakes.actuator(),
		teleporter = Fakes.teleporter(),
		passGateway = Fakes.passGateway(),
		marketplace = Fakes.marketplace(),
		clock = Fakes.clock(1000),
		random = Fakes.random(overrides and overrides.rolls),
	}
	local container = Container.new({ ports = ports })
	return container, ports
end

local function joined(container, userId)
	local player = Fakes.player(userId or 1)
	container.useCases.loadProfile:run(player)
	return player, container.sessions:get(player.UserId)
end

--[[ Position inside a tier, on the fast line. ]]
local function inside(container, tierId, offset)
	local bounds = container.domain.layout:boundsOf(tierId)
	return { x = bounds.startX + (offset or 20), y = bounds.altitude, z = 0 }
end

local function fly(container, player, position, at)
	return container.useCases.sampleFlight:run(player, {
		position = position,
		velocity = 100,
		at = at,
	})
end

describe("StartFlight", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joined(container)
	end)

	it("opens a pouch and sends the dragon to the launch point", function()
		local result = container.useCases.startFlight:run(player)

		expect(result.ok).toBe(true)
		expect(session.flying).toBe(true)
		expect(session.pouch).never.toBeNil()
		expect(ports.teleporter.last.x).toBe(container.domain.layout:launchPoint().x)
	end)

	it("counts the flight in the lifetime statistics", function()
		container.useCases.startFlight:run(player)
		expect(session.profile.totals.flights).toBe(1)
	end)

	it("refuses to start a flight already under way", function()
		container.useCases.startFlight:run(player)
		expect(container.useCases.startFlight:run(player).code).toBe("ALREADY_FLYING")
	end)

	it("arms a phoenix feather when the pass is owned", function()
		session.passes.phoenixFeather = true
		container.useCases.startFlight:run(player)
		expect(session.feathers).toBe(1)
	end)

	it("consumes one insured flight when the player bought insurance", function()
		session.profile.insuredFlights = 2
		container.useCases.startFlight:run(player)
		expect(session.insured).toBe(true)
		expect(session.profile.insuredFlights).toBe(1)
	end)
end)

describe("SampleFlight", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joined(container)
		container.useCases.startFlight:run(player)
	end)

	it("credits nothing on the first sample", function()
		local result = fly(container, player, inside(container, 1), 10)
		expect(result.value.warmup).toBe(true)
		expect(session.profile.speed).toBe(0)
	end)

	it("credits speed to the profile and gold to the pouch", function()
		fly(container, player, inside(container, 1, 20), 10)
		fly(container, player, inside(container, 1, 28), 10.2)

		local expectedSteps = 8 / Config.Balance.flight.studsPerStep
		expect(session.profile.speed).toBeCloseTo(
			expectedSteps * Config.Balance.progression.speedPerStep,
			1e-9
		)
		expect(session.pouch.gold).toBeCloseTo(expectedSteps * Config.Balance.progression.goldPerStep, 1e-9)
		expect(session.profile.gold).toBe(0)
	end)

	it("applies the flight state to the dragon", function()
		fly(container, player, inside(container, 1, 20), 0)
		fly(container, player, inside(container, 1, 28), 0.2)
		expect(ports.actuator.last.velocity).toBeGreaterThan(Config.Balance.speedCurve.baseVelocity)
		expect(ports.actuator.last.agility).toBeGreaterThanOrEqual(Config.Balance.speedCurve.baseAgility)
	end)

	it("neutralises impossible displacement inside a tier", function()
		local bounds = container.domain.layout:boundsOf(1)
		fly(container, player, inside(container, 1, 20), 0)
		-- Meme tier, mais 5000 studs plus haut en 0,2 s : impossible.
		local result =
			fly(container, player, { x = bounds.startX + 25, y = bounds.altitude + 5000, z = 0 }, 0.2)

		-- Credite exactement le plafond : 100 studs/s x 1,4 de marge x 0,2 s = 28 studs,
		-- soit 28 / 8 = 3,5 pas. Le reste du saut ne rapporte rien.
		local clampedSteps = (100 * Config.Balance.flight.toleranceFactor * 0.2)
			/ Config.Balance.flight.studsPerStep

		expect(result.value.clamped).toBe(true)
		expect(session.profile.speed).toBeCloseTo(clampedSteps, 1e-9)
	end)

	-- Un teleport lointain est arrete encore plus tot : par la barriere de vent.
	it("stops a long range teleport at the first locked barrier", function()
		fly(container, player, inside(container, 1, 20), 0)
		local result = fly(container, player, { x = 99999, y = 5000, z = 0 }, 0.2)

		expect(result.code).toBe("BARRIER_BLOCKED")
		expect(session.profile.speed).toBe(0)
	end)

	it("records the tier reached into the pouch", function()
		fly(container, player, inside(container, 1, 20), 0)
		fly(container, player, inside(container, 1, 28), 0.2)
		expect(session.pouch.tierId).toBe(1)
		expect(session.tierId).toBe(1)
	end)

	-- La barriere de vent : trop lent, on ne passe pas.
	it("pushes back a dragon too slow for the next barrier", function()
		fly(container, player, inside(container, 1, 20), 0)
		local result = fly(container, player, inside(container, 2, 30), 0.2)

		expect(result.code).toBe("BARRIER_BLOCKED")
		expect(session.pouch.tierId).toBe(0)
		expect(ports.notifier:lastMessage()).never.toBeNil()
		expect(#ports.teleporter.destinations).toBeGreaterThan(1)
	end)

	it("lets a fast enough dragon through the barrier", function()
		session.profile.speed = Config.Tiers[2].requiredSpeed
		fly(container, player, inside(container, 2, 20), 0)
		fly(container, player, inside(container, 2, 28), 0.2)

		expect(session.pouch.tierId).toBe(2)
		expect(session.profile.deepestTier).toBe(0) -- rien n'est acquis avant l'encaissement
	end)

	it("ignores samples when the dragon is resting at the Nest", function()
		container.useCases.crashFlight:run(player)
		local result = fly(container, player, inside(container, 1), 5)
		expect(result.value.idle).toBe(true)
	end)
end)

describe("BankPouch", function()
	local container, ports, player, session
	beforeEach(function()
		-- Un tirage bas garantit la rarete la plus commune autorisee.
		container, ports = build({ rolls = { 0 } })
		player, session = joined(container)
		container.useCases.startFlight:run(player)
	end)

	it("refuses to bank a pouch that never reached a tier", function()
		local result = container.useCases.bankPouch:run(player)
		expect(result.code).toBe("EMPTY_POUCH")
	end)

	it("moves gold and eggs into the profile", function()
		fly(container, player, inside(container, 1, 20), 0)
		fly(container, player, inside(container, 1, 28), 0.2)

		local result = container.useCases.bankPouch:run(player)

		expect(result.ok).toBe(true)
		expect(session.profile.gold).toBeGreaterThan(0)
		expect(session.profile.eggs.common).toBe(Config.Tiers[1].eggs)
		expect(session.profile.deepestTier).toBe(1)
	end)

	it("ends the flight and brings the dragon home", function()
		fly(container, player, inside(container, 1, 20), 0)
		fly(container, player, inside(container, 1, 28), 0.2)
		container.useCases.bankPouch:run(player)

		expect(session.flying).toBe(false)
		expect(session.pouch).toBeNil()
		expect(ports.teleporter.last.y).toBe(Config.World.nest.altitude)
	end)

	it("saves immediately: a banked pouch must survive a crash", function()
		fly(container, player, inside(container, 1, 20), 0)
		fly(container, player, inside(container, 1, 28), 0.2)
		container.useCases.bankPouch:run(player)

		expect(ports.repository:raw(1).gold).toBeGreaterThan(0)
	end)

	it("honours the guaranteed rarity of a deep tier", function()
		session.profile.speed = Config.Tiers[5].requiredSpeed
		fly(container, player, inside(container, 5, 20), 0)
		fly(container, player, inside(container, 5, 28), 0.2)
		container.useCases.bankPouch:run(player)

		-- Le tier 5 garantit "rare", meme avec le tirage le plus bas possible.
		expect(session.profile.eggs.rare).toBe(Config.Tiers[5].eggs)
		expect(session.profile.eggs.common).toBeNil()
	end)
end)

describe("CrashFlight", function()
	local container, ports, player, session

	local function reachTierOne()
		fly(container, player, inside(container, 1, 20), 0)
		fly(container, player, inside(container, 1, 28), 0.2)
	end

	beforeEach(function()
		container, ports = build()
		player, session = joined(container)
		container.useCases.startFlight:run(player)
	end)

	it("empties the pouch and sends the dragon home", function()
		reachTierOne()
		local carried = session.pouch.gold

		local result = container.useCases.crashFlight:run(player)

		expect(result.ok).toBe(true)
		expect(carried).toBeGreaterThan(0)
		expect(session.profile.gold).toBe(0)
		expect(session.flying).toBe(false)
	end)

	-- Le filet de securite : un vol rate rend quand meme plus rapide.
	it("never takes back the speed earned during the flight", function()
		reachTierOne()
		local speed = session.profile.speed
		container.useCases.crashFlight:run(player)
		expect(session.profile.speed).toBe(speed)
	end)

	it("counts the wall in the lifetime statistics", function()
		reachTierOne()
		container.useCases.crashFlight:run(player)
		expect(session.profile.totals.walls).toBe(1)
	end)

	it("burns a phoenix feather instead of the pouch", function()
		session.feathers = 1
		reachTierOne()
		local carried = session.pouch.gold

		local result = container.useCases.crashFlight:run(player)

		expect(result.value.saved).toBe(true)
		expect(session.feathers).toBe(0)
		expect(session.flying).toBe(true)
		expect(session.pouch.gold).toBe(carried)
	end)

	it("refunds half the pouch when the flight is insured", function()
		session.insured = true
		reachTierOne()
		session.pouch.gold = 1000 -- une poche consequente rend le calcul lisible

		container.useCases.crashFlight:run(player)

		expect(session.profile.gold).toBe(500)
	end)

	-- Le moment de regret : c'est la que l'offre a du sens.
	it("triggers the insurance offer after a loss", function()
		reachTierOne()
		container.useCases.crashFlight:run(player)

		local offers = container.useCases.listOffers:run(player)
		expect(session.profile.offers.seen.wallOffer).never.toBeNil()
		expect(offers.ok).toBe(true)
	end)

	it("does nothing when the dragon is not flying", function()
		container.useCases.crashFlight:run(player)
		expect(container.useCases.crashFlight:run(player).code).toBe("NOT_FLYING")
	end)
end)
