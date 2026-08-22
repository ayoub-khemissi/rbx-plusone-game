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
