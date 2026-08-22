--!nocheck
local Container = require(Server.Composition.Container)
local Config = require(Config)

local STATION = Config.Monetization.afk.station
local INSIDE = { x = STATION.x, y = 5, z = STATION.z }
local OUTSIDE = { x = STATION.x + STATION.radius + 30, y = 5, z = STATION.z }

local function build()
	local ports = {
		repository = Fakes.repository(),
		publisher = Fakes.publisher(),
		notifier = Fakes.notifier(),
		actuator = Fakes.actuator(),
		teleporter = Fakes.teleporter(),
		passGateway = Fakes.passGateway(),
		marketplace = Fakes.marketplace(),
		clock = Fakes.clock(1000),
	}
	local container = Container.new({ ports = ports })
	local player = Fakes.player(1)
	container.useCases.loadProfile:run(player)
	return container, ports, player, container.sessions:get(1)
end

describe("AccrueAfkReward", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports, player, session = build()
	end)

	it("ne rapporte rien hors de la zone", function()
		local result = container.useCases.accrueAfkReward:run(player, OUTSIDE, 120)
		expect(result.value.active).toBe(false)
		expect(session.profile.bananas).toBe(0)
	end)

	it("signale l'entree dans la zone", function()
		container.useCases.accrueAfkReward:run(player, INSIDE, 1)
		expect(session.afkActive).toBe(true)
		expect(ports.notifier:lastMessage()).toContain("AFK")
	end)

	it("credite des bananes a chaque minute passee sur le pad", function()
		container.useCases.accrueAfkReward:run(player, INSIDE, 60)
		expect(session.profile.bananas).toBe(Config.Monetization.afk.bananasPerMinute)
	end)

	it("n'accorde jamais de vitesse", function()
		container.useCases.accrueAfkReward:run(player, INSIDE, 600)
		expect(session.profile.speed).toBe(0)
	end)

	it("ne profite d'aucun multiplicateur", function()
		session.profile.rebirths = 10
		session.profile.upgrades.bananaGain = 20
		container.useCases.accrueAfkReward:run(player, INSIDE, 60)
		expect(session.profile.bananas).toBe(Config.Monetization.afk.bananasPerMinute)
	end)

	it("perd le temps partiel quand le joueur repart courir", function()
		container.useCases.accrueAfkReward:run(player, INSIDE, 45)
		container.useCases.accrueAfkReward:run(player, OUTSIDE, 1)
		container.useCases.accrueAfkReward:run(player, INSIDE, 30)
		expect(session.profile.bananas).toBe(0)
	end)

	it("respecte le plafond de session", function()
		local afk = Config.Monetization.afk
		container.useCases.accrueAfkReward:run(player, INSIDE, afk.sessionCapSeconds * 3)
		local maximum = (afk.sessionCapSeconds / 60) * afk.bananasPerMinute
		expect(session.profile.bananas).toBe(maximum)

		container.useCases.accrueAfkReward:run(player, INSIDE, 600)
		expect(session.profile.bananas).toBe(maximum)
	end)

	it("expose l'etat AFK a l'interface", function()
		container.useCases.accrueAfkReward:run(player, INSIDE, 60)
		expect(ports.publisher.last.afkActive).toBe(true)
		expect(ports.publisher.last.afkRemaining).toBeLessThan(Config.Monetization.afk.sessionCapSeconds)
	end)
end)
