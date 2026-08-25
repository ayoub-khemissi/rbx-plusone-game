--!nocheck
--[[
	Integration tests of the Application layer: the real container is mounted with
	fake adapters, so the production wiring is covered too.
]]

local Container = require(Server.Composition.Container)
local Config = require(Config)
local LevelCurve = require(Domain.Run.LevelCurve)

local function build(options)
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
	return Container.new({ ports = ports, devMode = options and options.devMode }), ports
end

local function joined(container, userId)
	local player = Fakes.player(userId or 1)
	container.useCases.loadProfile:run(player)
	return player, container.sessions:get(player.UserId)
end

local function run(container, player, from, to, at)
	container.useCases.sampleMovement:run(player, { position = from, walkSpeed = 50, at = at - 0.2 })
	return container.useCases.sampleMovement:run(player, { position = to, walkSpeed = 50, at = at })
end

describe("SampleMovement", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joined(container)
	end)

	it("credits nothing on the first sample", function()
		local result = container.useCases.sampleMovement:run(player, {
			position = { x = 0, y = 5, z = 0 },
			walkSpeed = 16,
			at = 10,
		})
		expect(result.value.warmup).toBe(true)
		expect(session.profile.speed).toBe(0)
	end)

	-- Courir credite tout de suite et definitivement : une chute ne reprend rien.
	it("credits speed and coins straight to the profile", function()
		run(container, player, { x = 0, y = 5, z = 0 }, { x = 8, y = 5, z = 0 }, 10)

		local expectedSteps = 8 / Config.Balance.movement.studsPerStep
		expect(session.profile.speed).toBeCloseTo(
			expectedSteps * Config.Balance.progression.speedPerStep,
			1e-9
		)
		expect(session.profile.coins).toBeCloseTo(
			expectedSteps * Config.Balance.progression.coinsPerStep,
			1e-9
		)
	end)

	it("applies the movement state to the character", function()
		run(container, player, { x = 0, y = 5, z = 0 }, { x = 8, y = 5, z = 0 }, 10)
		expect(ports.actuator.last.walkSpeed).toBe(Config.Balance.speedCurve.baseWalkSpeed)
		expect(ports.actuator.last.jumpLevel).toBe(1)
		expect(ports.actuator.last.dashLevel).toBe(0)
	end)

	-- The character speeds up when a LEVEL lands, not on every stride: eight studs
	-- is still level 1, and the acceleration has to be attributable to something
	-- the player saw happen.
	it("speeds the character up once a level is gained", function()
		session.profile.speed = LevelCurve.new(Config.Balance.level):requirementFor(6)
		run(container, player, { x = 0, y = 5, z = 0 }, { x = 8, y = 5, z = 0 }, 10)

		expect(ports.actuator.last.walkSpeed).toBeGreaterThan(Config.Balance.speedCurve.baseWalkSpeed)
	end)

	-- Jumping on the spot is not running.
	it("pays nothing for vertical movement", function()
		run(container, player, { x = 0, y = 5, z = 0 }, { x = 0, y = 60, z = 0 }, 10)
		expect(session.profile.speed).toBe(0)
	end)

	it("neutralises impossible displacement", function()
		local result = run(container, player, { x = 0, y = 5, z = 0 }, { x = 5000, y = 5, z = 0 }, 10)
		expect(result.value.clamped).toBe(true)
		expect(session.profile.speed).toBeLessThan(20)
	end)

	it("refuses a player without a session", function()
		local result = container.useCases.sampleMovement:run(Fakes.player(999), {
			position = { x = 0, y = 5, z = 0 },
			walkSpeed = 16,
			at = 1,
		})
		expect(result.code).toBe("NO_SESSION")
	end)
end)

describe("ReachCheckpoint", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joined(container)
	end)

	it("records where the player will come back", function()
		local result = container.useCases.reachCheckpoint:run(player, {
			stageId = 1,
			position = { x = 100, y = 10, z = 0 },
		})

		expect(result.ok).toBe(true)
		expect(session.checkpoint.x).toBe(100)
		expect(session.stageId).toBe(1)
		expect(session.profile.totals.checkpoints).toBe(1)
	end)

	it("remembers the deepest stage reached", function()
		session.profile.speed = Config.Stages[2].requiredSpeed
		container.useCases.reachCheckpoint:run(player, { stageId = 2, position = { x = 0, y = 0, z = 0 } })
		expect(session.profile.highestStage).toBe(2)
	end)

	-- La barriere de vitesse : le client la rend traversable, le serveur tranche.
	it("refuses a stage the player is too slow for", function()
		local result = container.useCases.reachCheckpoint:run(player, {
			stageId = 2,
			position = { x = 500, y = 10, z = 0 },
		})

		expect(result.code).toBe("STAGE_LOCKED")
		expect(session.stageId).toBe(1)
		expect(ports.notifier:lastMessage()).never.toBeNil()
	end)

	it("stays quiet when the same checkpoint is touched again", function()
		local checkpoint = { stageId = 1, position = { x = 100, y = 10, z = 0 } }
		container.useCases.reachCheckpoint:run(player, checkpoint)
		local again = container.useCases.reachCheckpoint:run(player, checkpoint)

		expect(again.value.unchanged).toBe(true)
		expect(session.profile.totals.checkpoints).toBe(1)
	end)

	it("rejects a malformed checkpoint from the map", function()
		expect(container.useCases.reachCheckpoint:run(player, { position = { x = 0, y = 0, z = 0 } }).ok).toBe(
			false
		)
		expect(container.useCases.reachCheckpoint:run(player, { stageId = "2" }).ok).toBe(false)
	end)
end)

describe("FallToCheckpoint", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joined(container)
	end)

	it("sends the player back to the last checkpoint", function()
		container.useCases.reachCheckpoint:run(player, { stageId = 1, position = { x = 100, y = 10, z = 0 } })
		container.useCases.fallToCheckpoint:run(player)

		expect(ports.teleporter.last.x).toBe(100)
		expect(session.profile.totals.falls).toBe(1)
	end)

	-- La promesse du jeu : une chute coute du temps, jamais de la progression.
	it("never takes back speed or coins", function()
		run(container, player, { x = 0, y = 5, z = 0 }, { x = 8, y = 5, z = 0 }, 10)
		local speed, coins = session.profile.speed, session.profile.coins

		container.useCases.fallToCheckpoint:run(player)

		expect(session.profile.speed).toBe(speed)
		expect(session.profile.coins).toBe(coins)
	end)

	it("refills the air jumps on the way back", function()
		session.profile.upgrades.jump = 2
		container.useCases.requestJump:run(player)
		container.useCases.requestJump:run(player)
		container.useCases.fallToCheckpoint:run(player)

		expect(container.useCases.requestJump:run(player).ok).toBe(true)
	end)

	it("falls back to the hub when no checkpoint was reached", function()
		container.useCases.fallToCheckpoint:run(player)
		expect(ports.teleporter.last).never.toBeNil()
	end)
end)

describe("RequestJump", function()
	local container, player, session
	beforeEach(function()
		container = build()
		player, session = joined(container)
	end)

	it("refuses an air jump at jump level 1", function()
		expect(container.useCases.requestJump:run(player).code).toBe("NO_JUMP_LEFT")
	end)

	it("grants one air jump at level 2", function()
		session.profile.upgrades.jump = 1
		expect(container.useCases.requestJump:run(player).ok).toBe(true)
		expect(container.useCases.requestJump:run(player).code).toBe("NO_JUMP_LEFT")
	end)

	it("grants two air jumps at level 3", function()
		session.profile.upgrades.jump = 2
		expect(container.useCases.requestJump:run(player).ok).toBe(true)
		expect(container.useCases.requestJump:run(player).ok).toBe(true)
		expect(container.useCases.requestJump:run(player).code).toBe("NO_JUMP_LEFT")
	end)

	it("refills on landing", function()
		session.profile.upgrades.jump = 1
		container.useCases.requestJump:run(player)
		container.useCases.noteLanded:run(player)
		expect(container.useCases.requestJump:run(player).ok).toBe(true)
	end)

	it("hands the jump power back to the client", function()
		session.profile.upgrades.jump = 1
		session.profile.upgrades.jumpPower = 4
		local result = container.useCases.requestJump:run(player)
		expect(result.value.jumpPower).toBeGreaterThan(Config.Balance.speedCurve.baseJumpPower)
	end)
end)

describe("RequestDash", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joined(container)
	end)

	it("refuses a dash that was never bought", function()
		expect(container.useCases.requestDash:run(player).code).toBe("NO_DASH")
	end)

	-- Dash Power is what the player is buying: the dash itself only unlocks it.
	it("returns more power on a higher power level", function()
		session.profile.upgrades.dash = 1
		local weak = container.useCases.requestDash:run(player).value.power

		local other, otherSession = joined(container, 2)
		otherSession.profile.upgrades.dash = 1
		otherSession.profile.upgrades.dashPower = 3
		local strong = container.useCases.requestDash:run(other).value.power

		expect(strong).toBeGreaterThan(weak)
	end)

	--[[
		And it grows with the character. Two players at the same Dash Power but
		different speeds must not get the same burst — that is the whole reason the
		impulse is a multiple rather than a number.
	]]
	it("returns more power to a faster character", function()
		session.profile.upgrades.dash = 1
		local slow = container.useCases.requestDash:run(player).value.power

		local other, otherSession = joined(container, 2)
		otherSession.profile.upgrades.dash = 1
		otherSession.profile.speed = 20000
		local fast = container.useCases.requestDash:run(other).value.power

		expect(fast).toBeGreaterThan(slow)
	end)

	it("refuses a second dash during the cooldown", function()
		session.profile.upgrades.dash = 1
		expect(container.useCases.requestDash:run(player).ok).toBe(true)
		expect(container.useCases.requestDash:run(player).code).toBe("DASH_COOLDOWN")
	end)

	it("allows it again once the cooldown is over", function()
		session.profile.upgrades.dash = 1
		container.useCases.requestDash:run(player)
		ports.clock.advance(Config.Balance.dash.cooldown + 0.1)
		expect(container.useCases.requestDash:run(player).ok).toBe(true)
	end)
end)

describe("CollectCoin", function()
	it("credits the pickup with the player multipliers", function()
		local container, ports = build()
		local player, session = joined(container)
		session.profile.upgrades.coinGain = 1 -- +20%

		local result = container.useCases.collectCoin:run(player, 100)

		expect(result.value.granted).toBeCloseTo(120, 1e-9)
		expect(session.profile.coins).toBeCloseTo(120, 1e-9)
		expect(ports.publisher.last.coins).toBeCloseTo(120, 1e-9)
	end)

	it("uses the stage multiplier of the checkpoint the player is on", function()
		local container = build()
		local player, session = joined(container)
		session.profile.speed = Config.Stages[3].requiredSpeed
		container.useCases.reachCheckpoint:run(player, { stageId = 3, position = { x = 0, y = 0, z = 0 } })

		local result = container.useCases.collectCoin:run(player, 100)
		expect(result.value.granted).toBeCloseTo(100 * Config.Stages[3].coinMultiplier, 1e-9)
	end)
end)

describe("PerformPrestige", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joined(container)
	end)

	it("refuses below the requirement", function()
		expect(container.useCases.performPrestige:run(player).code).toBe("SPEED_TOO_LOW")
		expect(session.profile.prestiges).toBe(0)
	end)

	it("resets progress, grants the multiplier and sends the player home", function()
		session.profile.speed = container.domain.prestigePolicy:requirementFor(0)

		local result = container.useCases.performPrestige:run(player)

		expect(result.ok).toBe(true)
		expect(session.profile.prestiges).toBe(1)
		expect(session.profile.speed).toBe(0)
		expect(session.checkpoint).toBeNil()
		expect(ports.teleporter.last).never.toBeNil()
	end)
end)

describe("Dev codes", function()
	local devCode = Config.Monetization.devCodes[1]

	it("stay unknown on a published server", function()
		local container = build()
		local player = joined(container)

		local result = container.useCases.redeemCode:run(player, devCode.code)

		expect(result.ok).toBe(false)
		expect(result.code).toBe("UNKNOWN_CODE")
	end)

	it("credit the profile in Studio, as many times as needed", function()
		local container = build({ devMode = true })
		local player, session = joined(container)

		container.useCases.redeemCode:run(player, devCode.code)
		container.useCases.redeemCode:run(player, devCode.code)

		expect(session.profile.coins).toBe(devCode.grant.coins * 2)
	end)

	it("leaves the published codes working either way", function()
		local container = build({ devMode = true })
		local player, session = joined(container)

		container.useCases.redeemCode:run(player, Config.Monetization.codes[1].code)

		expect(session.profile.coins).toBe(Config.Monetization.codes[1].grant.coins)
	end)
end)

describe("Level", function()
	it("reaches the client through the snapshot", function()
		local container, ports = build()
		local player, session = joined(container)

		session.profile.speed = 3000
		container.useCases.saveProfile:run(session.userId)
		ports.publisher:publish(player, container.snapshots:build(session))

		local snapshot = container.snapshots:build(session)
		expect(snapshot.level).toBeGreaterThan(1)
		expect(snapshot.levelCurrent).toBeLessThan(snapshot.levelRequired)
		expect(snapshot.levelProgress).toBeLessThan(1)
	end)

	--[[
		A prestige wipes the Speed, so the rank has to fall with it. Reading level 40
		on an empty profile would be the first sign the two had drifted apart.
	]]
	it("falls back to 1 when a prestige clears the speed", function()
		local container = build()
		local _, session = joined(container)

		session.profile.speed = 20000
		expect(container.snapshots:build(session).level).toBeGreaterThan(20)

		session.profile.speed = 0
		expect(container.snapshots:build(session).level).toBe(1)
	end)
end)

--[[
	The audio cues travel on the notification, so they are part of that contract
	rather than a client-side guess. These specs exist because the two moments they
	cover have no signal the client could trust on its own.
]]
describe("Sound cues", function()
	it("names the moment when a player falls back to a checkpoint", function()
		local container, ports = build()
		local player = joined(container)

		container.useCases.fallToCheckpoint:run(player)

		expect(ports.notifier:cues()).toContain("fall")
	end)

	-- A fall carries no message on purpose: a toast on every miss would nag. The
	-- anti-spam must not read two empty messages as one repeat and go silent.
	it("still fires on a second fall inside the anti-spam window", function()
		local container, ports = build()
		local player = joined(container)

		container.useCases.fallToCheckpoint:run(player)
		container.useCases.fallToCheckpoint:run(player)

		expect(#ports.notifier:cues()).toBe(2)
	end)
end)

--[[
	The gate the whole game will hang off: an upgrade, an idle pad, the next map.
	These cover the seam rather than the conditions themselves, which have their own
	spec — what matters here is that a use case cannot buy past it.
]]
describe("Requirements", function()
	it("refuses an upgrade whose prerequisite is missing", function()
		local container, ports = build()
		local player, session = joined(container)
		session.profile.coins = 1000000

		local result = container.useCases.buyUpgrade:run(player, "dashPower")

		expect(result.ok).toBe(false)
		expect(result.code).toBe("LOCKED")
		expect(session.profile.upgrades.dashPower).toBeNil()
		expect(ports.notifier:lastMessage()).never.toBeNil()
	end)

	-- And it must not be mistaken for a money problem: the player has plenty.
	it("says locked rather than too expensive", function()
		local container = build()
		local player, session = joined(container)
		session.profile.coins = 1000000

		expect(container.useCases.buyUpgrade:run(player, "dashPower").code).never.toBe("INSUFFICIENT_FUNDS")
	end)

	it("opens once the prerequisite is owned", function()
		local container = build()
		local player, session = joined(container)
		session.profile.coins = 1000000
		session.profile.upgrades.dash = 1

		expect(container.useCases.buyUpgrade:run(player, "dashPower").ok).toBe(true)
		expect(session.profile.upgrades.dashPower).toBe(1)
	end)
end)
