--!nocheck
local Profile = require(Domain.Profile.Profile)

describe("Profile", function()
	it("cree un profil neuf coherent", function()
		local profile = Profile.create()
		expect(profile.version).toBe(Profile.SCHEMA_VERSION)
		expect(profile.speed).toBe(0)
		expect(profile.bananas).toBe(0)
		expect(profile.rebirths).toBe(0)
		expect(profile.highestZone).toBe(1)
		expect(profile.upgrades).toEqual({})
		expect(profile.totals.steps).toBe(0)
	end)

	it("lit un niveau d'amelioration absent comme zero", function()
		local profile = Profile.create()
		expect(Profile.levelOf(profile, "speedGain")).toBe(0)
		profile.upgrades.speedGain = 4
		expect(Profile.levelOf(profile, "speedGain")).toBe(4)
	end)

	it("migre une donnee absente vers un profil neuf", function()
		local profile = Profile.migrate(nil)
		expect(profile.version).toBe(Profile.SCHEMA_VERSION)
		expect(profile.speed).toBe(0)
	end)

	it("complete les champs manquants d'une sauvegarde ancienne", function()
		local profile = Profile.migrate({ speed = 1200, bananas = 40 })
		expect(profile.speed).toBe(1200)
		expect(profile.bananas).toBe(40)
		expect(profile.rebirths).toBe(0)
		expect(profile.highestZone).toBe(1)
		expect(profile.totals.distance).toBe(0)
	end)

	it("assainit les valeurs corrompues", function()
		local profile = Profile.migrate({
			speed = -50,
			bananas = 0 / 0,
			rebirths = 2.7,
			highestZone = 0,
			upgrades = { speedGain = -3, triche = "beaucoup" },
		})
		expect(profile.speed).toBe(0)
		expect(profile.bananas).toBe(0)
		expect(profile.rebirths).toBe(2)
		expect(profile.highestZone).toBe(1)
		expect(profile.upgrades.speedGain).toBe(0)
		expect(profile.upgrades.triche).toBeNil()
	end)

	it("ne partage pas les tables entre deux profils neufs", function()
		local first, second = Profile.create(), Profile.create()
		first.upgrades.speedGain = 3
		expect(second.upgrades.speedGain).toBeNil()
	end)
end)

describe("Profile (schema v2 : monetisation)", function()
	it("initialise les structures de monetisation", function()
		local profile = Profile.create()
		expect(profile.version).toBe(2)
		expect(profile.boosts).toEqual({})
		expect(profile.codes).toEqual({})
		expect(profile.timers).toEqual({})
		expect(profile.purchases.count).toBe(0)
		expect(profile.purchases.spentRobux).toBe(0)
		expect(profile.daily.streak).toBe(0)
		expect(profile.offers.seen).toEqual({})
	end)

	it("complete un profil v1 sans perdre la progression", function()
		local profile = Profile.migrate({
			version = 1,
			speed = 8000,
			bananas = 250,
			upgrades = { speedGain = 7 },
		})
		expect(profile.version).toBe(2)
		expect(profile.speed).toBe(8000)
		expect(profile.upgrades.speedGain).toBe(7)
		expect(profile.purchases.order).toEqual({})
		expect(profile.daily.lastClaimAt).toBe(0)
	end)

	it("restaure les boosts, achats et codes deja obtenus", function()
		local profile = Profile.migrate({
			boosts = { speedRush = 1750, invalide = "oui" },
			codes = { SINGE2026 = true, faux = false },
			purchases = { count = 3, spentRobux = 597, order = { "r-1", "r-2", 42 } },
			daily = { streak = 4, lastClaimAt = 990 },
			timers = { playtimeChest = 120 },
			offers = { seen = { starterPack = 60 }, purchased = { starterPack = true } },
		})

		expect(profile.boosts.speedRush).toBe(1750)
		expect(profile.boosts.invalide).toBeNil()
		expect(profile.codes.SINGE2026).toBe(true)
		expect(profile.codes.faux).toBeNil()
		expect(profile.purchases.order).toEqual({ "r-1", "r-2" })
		expect(profile.purchases.ids["r-2"]).toBe(true)
		expect(profile.purchases.spentRobux).toBe(597)
		expect(profile.daily.streak).toBe(4)
		expect(profile.timers.playtimeChest).toBe(120)
		expect(profile.offers.purchased.starterPack).toBe(true)
	end)
end)
