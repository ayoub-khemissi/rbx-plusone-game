--!nocheck
--[[
	Tests d'integration de la couche Application : le conteneur reel est monte avec
	des adaptateurs factices. On verifie donc AUSSI le cablage de production.
]]

local Container = require(Server.Composition.Container)
local Config = require(Config)

local function build()
	local ports = {
		repository = Fakes.repository(),
		publisher = Fakes.publisher(),
		notifier = Fakes.notifier(),
		actuator = Fakes.actuator(),
		teleporter = Fakes.teleporter(),
		passGateway = Fakes.passGateway(),
		clock = Fakes.clock(),
	}
	local container = Container.new({ ports = ports })
	return container, ports
end

local function joinedPlayer(container, userId)
	local player = Fakes.player(userId or 1)
	container.useCases.loadProfile:run(player)
	return player, container.sessions:get(player.UserId)
end

local ZONE_1_X = Config.Balance.layout.trackStartX + 10

describe("AwardMovement", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container)
	end)

	it("ne credite rien sur le premier echantillon (amorçage)", function()
		local result = container.useCases.awardMovement:run(player, {
			position = { x = ZONE_1_X, y = 5, z = 0 },
			walkSpeed = 16,
			at = 10,
		})
		expect(result.ok).toBe(true)
		expect(result.value.warmup).toBe(true)
		expect(session.profile.speed).toBe(0)
	end)

	it("credite la vitesse et les bananes au deuxieme echantillon", function()
		container.useCases.awardMovement:run(player, {
			position = { x = ZONE_1_X, y = 5, z = 0 },
			walkSpeed = 16,
			at = 10,
		})
		local result = container.useCases.awardMovement:run(player, {
			position = { x = ZONE_1_X + 3, y = 5, z = 0 },
			walkSpeed = 16,
			at = 10.2,
		})

		local expectedSteps = 3 / Config.Balance.movement.studsPerStep
		expect(result.value.steps).toBeCloseTo(expectedSteps, 1e-9)
		expect(session.profile.speed).toBeCloseTo(
			expectedSteps * Config.Balance.progression.speedPerStep,
			1e-9
		)
		expect(session.profile.bananas).toBeCloseTo(
			expectedSteps * Config.Balance.progression.bananasPerStep,
			1e-9
		)
	end)

	it("applique la vitesse de deplacement au personnage", function()
		container.useCases.awardMovement:run(
			player,
			{ position = { x = ZONE_1_X, y = 5, z = 0 }, walkSpeed = 16, at = 0 }
		)
		container.useCases.awardMovement:run(player, {
			position = { x = ZONE_1_X + 3, y = 5, z = 0 },
			walkSpeed = 16,
			at = 0.2,
		})

		expect(ports.actuator.last.walkSpeed).toBeGreaterThan(Config.Balance.speedCurve.baseWalkSpeed)
		expect(ports.actuator.last.jumpPower).toBe(Config.Balance.speedCurve.baseJumpPower)
	end)

	it("publie un instantane a jour", function()
		container.useCases.awardMovement:run(
			player,
			{ position = { x = ZONE_1_X, y = 5, z = 0 }, walkSpeed = 16, at = 0 }
		)
		container.useCases.awardMovement:run(player, {
			position = { x = ZONE_1_X + 3, y = 5, z = 0 },
			walkSpeed = 16,
			at = 0.2,
		})
		expect(ports.publisher.last.speed).toBeGreaterThan(0)
		expect(ports.publisher.last.walkSpeed).toBeGreaterThan(0)
	end)

	it("neutralise un deplacement impossible (teleport / speed hack)", function()
		container.useCases.awardMovement:run(
			player,
			{ position = { x = ZONE_1_X, y = 5, z = 0 }, walkSpeed = 16, at = 0 }
		)
		local result = container.useCases.awardMovement:run(player, {
			position = { x = ZONE_1_X + 5000, y = 5, z = 0 },
			walkSpeed = 16,
			at = 0.2,
		})

		expect(result.value.clamped).toBe(true)
		expect(session.profile.speed).toBeLessThan(2)
	end)

	it("refuse un joueur sans session", function()
		local result = container.useCases.awardMovement:run(Fakes.player(999), {
			position = { x = 0, y = 5, z = 0 },
			walkSpeed = 16,
			at = 1,
		})
		expect(result.ok).toBe(false)
		expect(result.code).toBe("NO_SESSION")
	end)
end)

describe("EnforceZoneAccess", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container)
	end)

	it("laisse circuler dans le hub", function()
		local result = container.useCases.enforceZoneAccess:run(player, { x = 0, y = 5, z = 0 })
		expect(result.ok).toBe(true)
		expect(#ports.teleporter.destinations).toBe(0)
	end)

	it("renvoie le joueur qui entre dans une zone verrouillee", function()
		local zone2 = container.domain.layout:boundsOf(2)
		local result =
			container.useCases.enforceZoneAccess:run(player, { x = zone2.startX + 20, y = 5, z = 0 })

		expect(result.ok).toBe(false)
		expect(result.code).toBe("ZONE_LOCKED")
		expect(ports.teleporter.last.x).toBe(container.domain.layout:spawnOf(1).x)
		expect(ports.notifier:lastMessage()).never.toBeNil()
	end)

	it("autorise l'entree une fois la vitesse atteinte", function()
		session.profile.speed = Config.Zones[2].requiredSpeed
		local zone2 = container.domain.layout:boundsOf(2)

		local result =
			container.useCases.enforceZoneAccess:run(player, { x = zone2.startX + 20, y = 5, z = 0 })

		expect(result.ok).toBe(true)
		expect(session.zoneId).toBe(2)
		expect(session.profile.highestZone).toBe(2)
		expect(#ports.teleporter.destinations).toBe(0)
	end)
end)

describe("BuyUpgrade", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container)
	end)

	it("refuse une amelioration inconnue", function()
		local result = container.useCases.buyUpgrade:run(player, "jetpack")
		expect(result.code).toBe("UNKNOWN_UPGRADE")
	end)

	it("refuse un solde insuffisant et previent le joueur", function()
		local result = container.useCases.buyUpgrade:run(player, "speedGain")
		expect(result.code).toBe("INSUFFICIENT_FUNDS")
		expect(ports.notifier:lastMessage()).never.toBeNil()
	end)

	it("debite le solde et monte le niveau", function()
		local cost = container.domain.catalog:costFor("speedGain", 0)
		session.profile.bananas = cost

		local result = container.useCases.buyUpgrade:run(player, "speedGain")

		expect(result.ok).toBe(true)
		expect(session.profile.bananas).toBe(0)
		expect(session.profile.upgrades.speedGain).toBe(1)
		expect(ports.publisher.last.upgrades.speedGain).toBe(1)
	end)

	it("rejette un identifiant non textuel venu du reseau", function()
		local result = container.useCases.buyUpgrade:run(player, { exploit = true })
		expect(result.ok).toBe(false)
	end)
end)

describe("PerformRebirth", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container)
	end)

	it("refuse sous le seuil", function()
		local result = container.useCases.performRebirth:run(player)
		expect(result.code).toBe("SPEED_TOO_LOW")
		expect(session.profile.rebirths).toBe(0)
	end)

	it("renaissance : remise a zero, bonus permanent et retour au hub", function()
		session.profile.speed = container.domain.rebirthPolicy:requirementFor(0)

		local result = container.useCases.performRebirth:run(player)

		expect(result.ok).toBe(true)
		expect(session.profile.rebirths).toBe(1)
		expect(session.profile.speed).toBe(0)
		expect(ports.teleporter.last).never.toBeNil()
		expect(ports.publisher.last.rebirths).toBe(1)
	end)
end)

describe("TravelToZone", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container)
	end)

	it("teleporte vers une zone debloquee", function()
		session.profile.speed = Config.Zones[3].requiredSpeed
		local result = container.useCases.travelToZone:run(player, 3)

		expect(result.ok).toBe(true)
		expect(ports.teleporter.last.x).toBe(container.domain.layout:spawnOf(3).x)
	end)

	it("refuse une zone verrouillee", function()
		local result = container.useCases.travelToZone:run(player, 5)
		expect(result.code).toBe("ZONE_LOCKED")
		expect(#ports.teleporter.destinations).toBe(0)
	end)

	it("refuse une zone inexistante", function()
		expect(container.useCases.travelToZone:run(player, 99).code).toBe("UNKNOWN_ZONE")
		expect(container.useCases.travelToZone:run(player, "2").code).toBe("UNKNOWN_ZONE")
	end)
end)

describe("CollectBanana", function()
	it("credite le ramassage avec les multiplicateurs du joueur", function()
		local container, ports = build()
		local player, session = joinedPlayer(container)
		session.profile.upgrades.bananaGain = 1 -- +20%

		local result = container.useCases.collectBanana:run(player, 100)

		expect(result.ok).toBe(true)
		expect(result.value.granted).toBeCloseTo(120, 1e-9)
		expect(session.profile.bananas).toBeCloseTo(120, 1e-9)
		expect(ports.publisher.last.bananas).toBeCloseTo(120, 1e-9)
	end)
end)
