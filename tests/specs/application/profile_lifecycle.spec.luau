--!nocheck
local LoadPlayerProfile = require(Application.UseCases.LoadPlayerProfile)
local SavePlayerProfile = require(Application.UseCases.SavePlayerProfile)
local ReleasePlayer = require(Application.UseCases.ReleasePlayer)
local SessionRegistry = require(Application.SessionRegistry)
local Profile = require(Domain.Profile.Profile)

local function buildContext()
	local context = {
		repository = Fakes.repository(),
		sessions = SessionRegistry.new(),
		publisher = Fakes.publisher(),
		passGateway = Fakes.passGateway(),
		notifier = Fakes.notifier(),
		snapshots = Fakes.snapshots(),
	}
	context.load = LoadPlayerProfile.new(context)
	context.save = SavePlayerProfile.new(context)
	context.release = ReleasePlayer.new(context)
	return context
end

describe("LoadPlayerProfile", function()
	local ctx, player
	beforeEach(function()
		ctx = buildContext()
		player = Fakes.player(101, "Zoubi")
	end)

	it("cree un profil neuf pour un nouveau joueur", function()
		local result = ctx.load:run(player)
		expect(result.ok).toBe(true)
		expect(result.value.profile.speed).toBe(0)
		expect(ctx.sessions:get(101)).never.toBeNil()
	end)

	it("restaure et normalise une sauvegarde existante", function()
		ctx.repository:seed(101, { speed = 4200, bananas = -10, upgrades = { speedGain = 3 } })
		local result = ctx.load:run(player)
		expect(result.value.profile.speed).toBe(4200)
		expect(result.value.profile.bananas).toBe(0)
		expect(result.value.profile.upgrades.speedGain).toBe(3)
	end)

	it("publie un premier instantane pour l'interface", function()
		ctx.load:run(player)
		expect(ctx.publisher.last.speed).toBe(0)
		expect(ctx.publisher.last.zoneId).toBe(1)
	end)

	it("charge les gamepasses possedes", function()
		ctx.passGateway.owned = { doubleSpeed = true }
		local result = ctx.load:run(player)
		expect(result.value.passes.doubleSpeed).toBe(true)
	end)

	it("protege la sauvegarde quand le datastore est en panne", function()
		ctx.repository.failNext = true
		local result = ctx.load:run(player)

		expect(result.ok).toBe(false)
		expect(result.code).toBe("LOAD_FAILED")
		-- Le joueur peut jouer, mais on n'ecrasera jamais sa vraie sauvegarde.
		local session = ctx.sessions:get(101)
		expect(session).never.toBeNil()
		expect(session.savable).toBe(false)
	end)
end)

describe("SavePlayerProfile", function()
	local ctx, player
	beforeEach(function()
		ctx = buildContext()
		player = Fakes.player(202)
	end)

	it("refuse de sauvegarder sans session", function()
		local result = ctx.save:run(202)
		expect(result.ok).toBe(false)
		expect(result.code).toBe("NO_SESSION")
		expect(ctx.repository.saves).toBe(0)
	end)

	it("ecrit le profil dans le depot", function()
		ctx.load:run(player)
		ctx.sessions:get(202).profile.speed = 999

		local result = ctx.save:run(202)
		expect(result.ok).toBe(true)
		expect(ctx.repository:raw(202).speed).toBe(999)
	end)

	it("n'ecrit jamais une session marquee non sauvegardable", function()
		ctx.repository:seed(202, { speed = 50000 })
		ctx.repository.failNext = true
		ctx.load:run(player)

		local result = ctx.save:run(202)
		expect(result.ok).toBe(false)
		expect(result.code).toBe("READ_ONLY")
		expect(ctx.repository:raw(202).speed).toBe(50000)
	end)

	it("remonte une panne d'ecriture", function()
		ctx.load:run(player)
		ctx.repository.failNext = true
		local result = ctx.save:run(202)
		expect(result.ok).toBe(false)
		expect(result.code).toBe("SAVE_FAILED")
	end)
end)

describe("ReleasePlayer", function()
	it("sauvegarde puis ferme la session au depart du joueur", function()
		local ctx = buildContext()
		local player = Fakes.player(303)
		ctx.load:run(player)
		ctx.sessions:get(303).profile.bananas = 1234

		local result = ctx.release:run(player)

		expect(result.ok).toBe(true)
		expect(ctx.repository:raw(303).bananas).toBe(1234)
		expect(ctx.sessions:get(303)).toBeNil()
	end)

	it("reste sans effet pour un joueur sans session", function()
		local ctx = buildContext()
		local result = ctx.release:run(Fakes.player(404))
		expect(result.ok).toBe(false)
		expect(ctx.repository.saves).toBe(0)
	end)
end)
