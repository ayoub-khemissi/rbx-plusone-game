--!nocheck
--[[
	Monetisation : le chemin critique du revenu. Ces tests couvrent le cas ou Roblox
	rejoue un recu, ou la sauvegarde tombe, ou le joueur essaie de tricher.
]]

local Container = require(Server.Composition.Container)
local BaseConfig = require(Config)

local TEST_PRODUCTS = {
	{ id = "bananaMedium", productId = 1001, name = "Regime", robux = 199, grant = { bananas = 8000 } },
	{
		id = "speedRush",
		productId = 1002,
		name = "Ruee",
		robux = 149,
		grant = { boost = { id = "speedRush", duration = 1200 } },
	},
	{
		id = "serverParty",
		productId = 1003,
		name = "Fete",
		robux = 299,
		grant = { serverBoost = { id = "serverParty", duration = 600 } },
	},
	{ id = "instantRebirth", productId = 1004, name = "Renaissance", robux = 399, grant = { rebirths = 1 } },
	{
		id = "starterPack",
		productId = 1005,
		name = "Pack",
		robux = 199,
		grant = { bananas = 5000, boost = { id = "speedRush", duration = 1800 } },
	},
}

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

	local config = {
		Balance = BaseConfig.Balance,
		Upgrades = BaseConfig.Upgrades,
		Zones = BaseConfig.Zones,
		Passes = BaseConfig.Passes,
		World = BaseConfig.World,
		Monetization = BaseConfig.Monetization,
		Products = TEST_PRODUCTS,
	}

	local container = Container.new({ config = config, ports = ports })
	return container, ports
end

local function joinedPlayer(container, userId)
	local player = Fakes.player(userId or 1)
	container.useCases.loadProfile:run(player)
	return player, container.sessions:get(player.UserId)
end

local function receipt(userId, productId, purchaseId)
	return {
		PlayerId = userId,
		ProductId = productId,
		PurchaseId = purchaseId or "achat-1",
		CurrencySpent = 199,
	}
end

describe("ProcessReceipt", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container, 1)
	end)

	it("credite le produit achete", function()
		local result = container.useCases.processReceipt:run(receipt(1, 1001))

		expect(result.ok).toBe(true)
		expect(session.profile.bananas).toBe(8000)
		expect(ports.notifier:lastMessage()).never.toBeNil()
	end)

	it("sauvegarde immediatement apres un achat", function()
		container.useCases.processReceipt:run(receipt(1, 1001))
		expect(ports.repository:raw(1).bananas).toBe(8000)
	end)

	it("ne credite jamais deux fois le meme recu", function()
		container.useCases.processReceipt:run(receipt(1, 1001, "achat-A"))
		local second = container.useCases.processReceipt:run(receipt(1, 1001, "achat-A"))

		expect(second.ok).toBe(true)
		expect(second.value.duplicate).toBe(true)
		expect(session.profile.bananas).toBe(8000)
	end)

	it("distingue deux achats differents du meme produit", function()
		container.useCases.processReceipt:run(receipt(1, 1001, "achat-A"))
		container.useCases.processReceipt:run(receipt(1, 1001, "achat-B"))
		expect(session.profile.bananas).toBe(16000)
	end)

	it("refuse de confirmer si la sauvegarde echoue (Roblox rejouera)", function()
		ports.repository.failNext = true
		local result = container.useCases.processReceipt:run(receipt(1, 1001))

		expect(result.ok).toBe(false)
		expect(result.code).toBe("SAVE_FAILED")
	end)

	it("finit par persister l'achat quand la sauvegarde revient", function()
		ports.repository.failNext = true
		container.useCases.processReceipt:run(receipt(1, 1001, "achat-A"))
		local retry = container.useCases.processReceipt:run(receipt(1, 1001, "achat-A"))

		expect(retry.ok).toBe(true)
		expect(ports.repository:raw(1).bananas).toBe(8000)
	end)

	it("attend le chargement du profil plutot que de perdre l'achat", function()
		local result = container.useCases.processReceipt:run(receipt(4242, 1001))
		expect(result.ok).toBe(false)
		expect(result.code).toBe("NO_SESSION")
	end)

	it("signale un produit inconnu", function()
		expect(container.useCases.processReceipt:run(receipt(1, 999999)).code).toBe("UNKNOWN_PRODUCT")
	end)

	it("active un boost temporaire", function()
		container.useCases.processReceipt:run(receipt(1, 1002))
		expect(container.domain.boosts:isActive(session.profile, "speedRush", 1000)).toBe(true)
		expect(ports.publisher.last.speedMultiplier).toBe(2)
	end)

	it("applique le boost de serveur a tous les joueurs connectes", function()
		local _, otherSession = joinedPlayer(container, 2)
		container.useCases.processReceipt:run(receipt(1, 1003))

		expect(container.domain.boosts:isActive(session.profile, "serverParty", 1000)).toBe(true)
		expect(container.domain.boosts:isActive(otherSession.profile, "serverParty", 1000)).toBe(true)
	end)

	it("accorde une renaissance immediate", function()
		session.profile.upgrades.speedGain = 5
		container.useCases.processReceipt:run(receipt(1, 1004))

		expect(session.profile.rebirths).toBe(1)
		expect(session.profile.speed).toBe(0)
		-- l'interet du produit : on garde ses ameliorations
		expect(session.profile.upgrades.speedGain).toBe(5)
	end)

	it("consomme l'offre de bienvenue une fois achetee", function()
		container.useCases.processReceipt:run(receipt(1, 1005))
		expect(session.profile.offers.purchased.starterPack).toBe(true)
	end)
end)

describe("ClaimDailyReward", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container, 1)
	end)

	it("accorde la recompense du jour 1", function()
		local result = container.useCases.claimDailyReward:run(player)
		expect(result.ok).toBe(true)
		expect(session.profile.daily.streak).toBe(1)
		expect(session.profile.bananas).toBeGreaterThan(0)
	end)

	it("refuse une seconde reclamation le meme jour", function()
		container.useCases.claimDailyReward:run(player)
		local second = container.useCases.claimDailyReward:run(player)
		expect(second.code).toBe("ALREADY_CLAIMED")
	end)

	it("fait progresser la serie le lendemain", function()
		container.useCases.claimDailyReward:run(player)
		ports.clock.advance(86400 + 10)
		container.useCases.claimDailyReward:run(player)
		expect(session.profile.daily.streak).toBe(2)
	end)
end)

describe("ClaimPlaytimeChest", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container, 1)
	end)

	it("n'est pas disponible des la connexion", function()
		expect(container.useCases.claimPlaytimeChest:run(player).code).toBe("NOT_READY")
	end)

	it("se debloque apres l'intervalle de jeu", function()
		ports.clock.advance(BaseConfig.Monetization.playtimeChest.interval + 1)
		local result = container.useCases.claimPlaytimeChest:run(player)
		expect(result.ok).toBe(true)
		expect(session.profile.bananas).toBe(BaseConfig.Monetization.playtimeChest.grant.bananas)
	end)
end)

describe("RedeemCode", function()
	local container, player, session
	beforeEach(function()
		container = build()
		player, session = joinedPlayer(container, 1)
	end)

	it("accepte un code valide", function()
		local result = container.useCases.redeemCode:run(player, "singe2026")
		expect(result.ok).toBe(true)
		expect(session.profile.bananas).toBeGreaterThan(0)
	end)

	it("refuse un code deja utilise", function()
		container.useCases.redeemCode:run(player, "SINGE2026")
		expect(container.useCases.redeemCode:run(player, "SINGE2026").code).toBe("ALREADY_REDEEMED")
	end)

	it("refuse un code invente", function()
		expect(container.useCases.redeemCode:run(player, "cheat").code).toBe("UNKNOWN_CODE")
	end)
end)

describe("Offres a duree limitee", function()
	local container, ports, player, session
	beforeEach(function()
		container, ports = build()
		player, session = joinedPlayer(container, 1)
	end)

	it("ne propose rien au tout debut de la partie", function()
		expect(#container.useCases.listOffers:run(player).value.offers).toBe(0)
	end)

	it("propose le pack de bienvenue apres quelques minutes", function()
		session.profile.totals.playtime = BaseConfig.Monetization.offers[1].triggerAfterSeconds + 1
		local offers = container.useCases.listOffers:run(player).value.offers
		expect(#offers).toBe(1)
		expect(offers[1].id).toBe("starterPack")
	end)

	it("propose un boost quand le joueur bute sur une barriere", function()
		local zone2 = container.domain.layout:boundsOf(2)
		container.useCases.enforceZoneAccess:run(player, { x = zone2.startX + 15, y = 5, z = 0 })

		local offers = container.useCases.listOffers:run(player).value.offers
		expect(#offers).toBe(1)
		expect(offers[1].id).toBe("gateBooster")
	end)

	it("demande l'ouverture de la fenetre d'achat Roblox", function()
		container.useCases.promptPurchase:run(player, "product", "bananaMedium")
		expect(ports.marketplace.prompts[1].productId).toBe(1001)
	end)

	it("ignore un produit non configure", function()
		local result = container.useCases.promptPurchase:run(player, "product", "inexistant")
		expect(result.ok).toBe(false)
		expect(#ports.marketplace.prompts).toBe(0)
	end)
end)
