--!nocheck
local BoostStack = require(Domain.Monetization.BoostStack)
local PurchaseLedger = require(Domain.Monetization.PurchaseLedger)
local ProductCatalog = require(Domain.Monetization.ProductCatalog)
local Grants = require(Domain.Monetization.Grants)
local RewardSchedule = require(Domain.Monetization.RewardSchedule)
local IntervalReward = require(Domain.Monetization.IntervalReward)
local PromoCodes = require(Domain.Monetization.PromoCodes)
local OfferEngine = require(Domain.Monetization.OfferEngine)
local Profile = require(Domain.Profile.Profile)

local HOUR = 3600
local DAY = 86400

describe("BoostStack", function()
	local stack, profile
	beforeEach(function()
		stack = BoostStack.new({
			definitions = {
				speedRush = { name = "Ruee", speed = 2 },
				bananaFever = { name = "Fievre", bananas = 3 },
				serverParty = { name = "Fete", speed = 1.5, bananas = 1.5 },
			},
			maxStackedDuration = 4 * HOUR,
		})
		profile = Profile.create()
	end)

	it("active un boost pour une duree donnee", function()
		stack:grant(profile, "speedRush", 900, 1000)
		expect(stack:isActive(profile, "speedRush", 1500)).toBe(true)
		expect(stack:remainingFor(profile, "speedRush", 1500)).toBe(400)
	end)

	it("expire proprement", function()
		stack:grant(profile, "speedRush", 900, 1000)
		expect(stack:isActive(profile, "speedRush", 1901)).toBe(false)
		expect(stack:remainingFor(profile, "speedRush", 1901)).toBe(0)
	end)

	it("cumule les achats successifs du meme boost", function()
		stack:grant(profile, "speedRush", 900, 1000)
		stack:grant(profile, "speedRush", 900, 1200)
		-- il restait 700 s, on ajoute 900 s : 1600 s restants
		expect(stack:remainingFor(profile, "speedRush", 1200)).toBe(1600)
	end)

	it("plafonne le cumul pour eviter les boosts infinis", function()
		for _ = 1, 20 do
			stack:grant(profile, "speedRush", HOUR, 0)
		end
		expect(stack:remainingFor(profile, "speedRush", 0)).toBe(4 * HOUR)
	end)

	it("ignore un boost inconnu", function()
		local granted = stack:grant(profile, "inconnu", 900, 0)
		expect(granted).toBe(false)
		expect(profile.boosts.inconnu).toBeNil()
	end)

	it("agrege les multiplicateurs des boosts actifs", function()
		stack:grant(profile, "speedRush", 900, 0)
		stack:grant(profile, "bananaFever", 900, 0)
		local bonuses = stack:multipliersFor(profile, 100)
		expect(bonuses.speed).toBe(2)
		expect(bonuses.bananas).toBe(3)
	end)

	it("multiplie les boosts qui se chevauchent", function()
		stack:grant(profile, "speedRush", 900, 0)
		stack:grant(profile, "serverParty", 900, 0)
		expect(stack:multipliersFor(profile, 100).speed).toBe(3)
	end)

	it("revient a 1 sans boost actif", function()
		local bonuses = stack:multipliersFor(profile, 0)
		expect(bonuses.speed).toBe(1)
		expect(bonuses.bananas).toBe(1)
	end)

	it("nettoie les boosts expires du profil", function()
		stack:grant(profile, "speedRush", 10, 0)
		stack:prune(profile, 999)
		expect(profile.boosts.speedRush).toBeNil()
	end)

	it("liste les boosts actifs pour l'interface", function()
		stack:grant(profile, "speedRush", 900, 0)
		local active = stack:activeFor(profile, 100)
		expect(#active).toBe(1)
		expect(active[1].id).toBe("speedRush")
		expect(active[1].name).toBe("Ruee")
		expect(active[1].remaining).toBe(800)
	end)
end)

describe("PurchaseLedger", function()
	local profile
	beforeEach(function()
		profile = Profile.create()
	end)

	it("ne connait aucun achat au depart", function()
		expect(PurchaseLedger.hasProcessed(profile, "r-1")).toBe(false)
	end)

	it("enregistre un achat une seule fois", function()
		expect(
			PurchaseLedger.record(
				profile,
				{ purchaseId = "r-1", productId = "bananaBag", robux = 99, at = 10 }
			)
		).toBe(true)
		expect(PurchaseLedger.hasProcessed(profile, "r-1")).toBe(true)
		expect(
			PurchaseLedger.record(
				profile,
				{ purchaseId = "r-1", productId = "bananaBag", robux = 99, at = 20 }
			)
		).toBe(false)
	end)

	it("cumule le total depense et le nombre d'achats", function()
		PurchaseLedger.record(profile, { purchaseId = "r-1", productId = "a", robux = 99, at = 1 })
		PurchaseLedger.record(profile, { purchaseId = "r-2", productId = "b", robux = 199, at = 2 })
		expect(profile.purchases.count).toBe(2)
		expect(profile.purchases.spentRobux).toBe(298)
	end)

	it("borne l'historique pour ne pas faire exploser la sauvegarde", function()
		for index = 1, PurchaseLedger.MAX_HISTORY + 25 do
			PurchaseLedger.record(
				profile,
				{ purchaseId = `r-{index}`, productId = "a", robux = 1, at = index }
			)
		end
		expect(#profile.purchases.order).toBe(PurchaseLedger.MAX_HISTORY)
		-- les plus anciens sortent de l'historique, les recents restent proteges
		expect(PurchaseLedger.hasProcessed(profile, "r-1")).toBe(false)
		expect(PurchaseLedger.hasProcessed(profile, `r-{PurchaseLedger.MAX_HISTORY + 25}`)).toBe(true)
	end)
end)

describe("ProductCatalog", function()
	local catalog
	beforeEach(function()
		catalog = ProductCatalog.new({
			{
				id = "bananaBag",
				productId = 111,
				name = "Sac de bananes",
				robux = 99,
				grant = { bananas = 5000 },
			},
			{
				id = "speedRush",
				productId = 222,
				name = "Ruee",
				robux = 199,
				grant = { boost = { id = "speedRush", duration = 1200 } },
			},
			{ id = "desactive", productId = 0, name = "Non configure", robux = 0, grant = { bananas = 1 } },
		})
	end)

	it("retrouve un produit par son identifiant metier", function()
		expect(catalog:get("bananaBag").name).toBe("Sac de bananes")
	end)

	it("retrouve un produit par son identifiant Roblox", function()
		expect(catalog:byProductId(222).id).toBe("speedRush")
		expect(catalog:byProductId(999)).toBeNil()
	end)

	it("ignore les produits non configures (productId = 0)", function()
		expect(catalog:byProductId(0)).toBeNil()
		expect(catalog:isConfigured("desactive")).toBe(false)
		expect(catalog:isConfigured("bananaBag")).toBe(true)
	end)

	it("liste uniquement les produits vendables", function()
		local sellable = catalog:sellable()
		expect(#sellable).toBe(2)
	end)
end)

describe("Grants", function()
	local context, stack
	beforeEach(function()
		stack = BoostStack.new({ definitions = { speedRush = { speed = 2 } }, maxStackedDuration = HOUR })
		context = { profile = Profile.create(), boosts = stack, now = 100 }
	end)

	it("credite des bananes", function()
		local summary = Grants.apply({ bananas = 5000 }, context)
		expect(context.profile.bananas).toBe(5000)
		expect(summary.bananas).toBe(5000)
	end)

	it("credite de la vitesse", function()
		Grants.apply({ speed = 250 }, context)
		expect(context.profile.speed).toBe(250)
	end)

	it("active un boost", function()
		Grants.apply({ boost = { id = "speedRush", duration = 600 } }, context)
		expect(stack:isActive(context.profile, "speedRush", 200)).toBe(true)
	end)

	it("accorde une renaissance immediate sans exiger le seuil", function()
		context.profile.speed = 10
		context.rebirthPolicy = {
			multiplierFor = function(_self, n)
				return 1 + n
			end,
		}
		local summary = Grants.apply({ rebirths = 1 }, context)
		expect(context.profile.rebirths).toBe(1)
		expect(context.profile.speed).toBe(0)
		expect(summary.rebirths).toBe(1)
	end)

	it("combine plusieurs recompenses", function()
		local summary = Grants.apply({ bananas = 100, speed = 10 }, context)
		expect(summary.bananas).toBe(100)
		expect(summary.speed).toBe(10)
	end)

	it("ignore une recompense vide", function()
		expect(Grants.apply(nil, context)).toEqual({})
	end)
end)

describe("RewardSchedule (recompense quotidienne)", function()
	local schedule, profile
	beforeEach(function()
		schedule = RewardSchedule.new({
			dayLength = DAY,
			graceWindow = 2 * DAY,
			rewards = {
				{ day = 1, grant = { bananas = 100 } },
				{ day = 2, grant = { bananas = 250 } },
				{ day = 3, grant = { boost = { id = "speedRush", duration = 600 } } },
			},
		})
		profile = Profile.create()
	end)

	it("est reclamable des la premiere connexion", function()
		local status = schedule:statusFor(profile, 0)
		expect(status.claimable).toBe(true)
		expect(status.day).toBe(1)
	end)

	it("accorde la recompense du jour et demarre la serie", function()
		local result = schedule:claim(profile, 1000)
		expect(result.ok).toBe(true)
		expect(result.value.day).toBe(1)
		expect(profile.daily.streak).toBe(1)
		expect(profile.daily.lastClaimAt).toBe(1000)
	end)

	it("refuse une seconde reclamation le meme jour", function()
		schedule:claim(profile, 1000)
		local result = schedule:claim(profile, 1000 + HOUR)
		expect(result.ok).toBe(false)
		expect(result.code).toBe("ALREADY_CLAIMED")
		expect(result.value.secondsRemaining).toBe(DAY - HOUR)
	end)

	it("fait progresser la serie le lendemain", function()
		schedule:claim(profile, 0)
		local result = schedule:claim(profile, DAY + 60)
		expect(result.ok).toBe(true)
		expect(profile.daily.streak).toBe(2)
		expect(result.value.day).toBe(2)
	end)

	it("remet la serie a zero apres une absence trop longue", function()
		schedule:claim(profile, 0)
		schedule:claim(profile, 3 * DAY)
		expect(profile.daily.streak).toBe(1)
	end)

	it("boucle sur le premier jour une fois le cycle termine", function()
		profile.daily.streak = 3
		profile.daily.lastClaimAt = 0
		local result = schedule:claim(profile, DAY + 1)
		expect(result.value.day).toBe(1)
		expect(profile.daily.streak).toBe(4)
	end)
end)

describe("IntervalReward (coffre de temps de jeu)", function()
	local chest, profile
	beforeEach(function()
		chest = IntervalReward.new({ interval = 300, grant = { bananas = 50 } })
		profile = Profile.create()
	end)

	it("n'est pas reclamable avant l'intervalle", function()
		local status = chest:statusFor(profile, "playtimeChest", 0)
		expect(status.claimable).toBe(false)
		expect(status.secondsRemaining).toBe(300)
	end)

	it("devient reclamable apres l'intervalle", function()
		expect(chest:statusFor(profile, "playtimeChest", 300).claimable).toBe(true)
	end)

	it("relance le compteur apres reclamation", function()
		local result = chest:claim(profile, "playtimeChest", 400)
		expect(result.ok).toBe(true)
		expect(result.value.grant.bananas).toBe(50)
		expect(chest:statusFor(profile, "playtimeChest", 400).claimable).toBe(false)
	end)

	it("refuse une reclamation anticipee", function()
		chest:claim(profile, "playtimeChest", 400)
		local result = chest:claim(profile, "playtimeChest", 500)
		expect(result.code).toBe("NOT_READY")
	end)
end)

describe("PromoCodes", function()
	local codes, profile
	beforeEach(function()
		codes = PromoCodes.new({
			{ code = "SINGE2026", grant = { bananas = 500 } },
			{ code = "EXPIRE", grant = { bananas = 100 }, expiresAt = 50 },
		})
		profile = Profile.create()
	end)

	it("accepte un code valide, sans tenir compte de la casse", function()
		local result = codes:redeem(profile, "singe2026", 10)
		expect(result.ok).toBe(true)
		expect(result.value.grant.bananas).toBe(500)
	end)

	it("refuse un code deja utilise", function()
		codes:redeem(profile, "SINGE2026", 10)
		local result = codes:redeem(profile, "SINGE2026", 20)
		expect(result.code).toBe("ALREADY_REDEEMED")
	end)

	it("refuse un code inconnu", function()
		expect(codes:redeem(profile, "n'importe quoi", 10).code).toBe("UNKNOWN_CODE")
	end)

	it("refuse un code expire", function()
		expect(codes:redeem(profile, "EXPIRE", 100).code).toBe("EXPIRED")
	end)
end)

describe("OfferEngine", function()
	local engine, profile
	beforeEach(function()
		engine = OfferEngine.new({
			{
				id = "starterPack",
				productKey = "starterPack",
				triggerAfterSeconds = 180,
				durationSeconds = 900,
				oncePerProfile = true,
			},
			{
				id = "gateBooster",
				productKey = "speedRush",
				trigger = "zoneBlocked",
				durationSeconds = 600,
			},
		})
		profile = Profile.create()
	end)

	it("cache l'offre de bienvenue avant son declenchement", function()
		expect(#engine:visibleFor(profile, { playtime = 60, now = 60 })).toBe(0)
	end)

	it("declenche l'offre de bienvenue apres le temps de jeu requis", function()
		local offers = engine:visibleFor(profile, { playtime = 200, now = 200 })
		expect(#offers).toBe(1)
		expect(offers[1].id).toBe("starterPack")
		expect(offers[1].secondsRemaining).toBe(900)
	end)

	it("fait expirer l'offre apres sa duree", function()
		engine:visibleFor(profile, { playtime = 200, now = 200 })
		expect(#engine:visibleFor(profile, { playtime = 1200, now = 1200 })).toBe(0)
	end)

	it("ne repropose pas une offre unique deja achetee", function()
		engine:markPurchased(profile, "starterPack")
		expect(#engine:visibleFor(profile, { playtime = 200, now = 200 })).toBe(0)
	end)

	it("declenche une offre contextuelle sur evenement", function()
		engine:trigger(profile, "zoneBlocked", 500)
		local offers = engine:visibleFor(profile, { playtime = 500, now = 700 })
		expect(#offers).toBe(1)
		expect(offers[1].id).toBe("gateBooster")
		expect(offers[1].secondsRemaining).toBe(400)
	end)
end)
