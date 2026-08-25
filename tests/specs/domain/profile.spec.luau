--!nocheck
local Profile = require(Domain.Profile.Profile)

describe("Profile", function()
	it("creates a coherent new profile", function()
		local profile = Profile.create()
		expect(profile.version).toBe(Profile.SCHEMA_VERSION)
		expect(profile.speed).toBe(0)
		expect(profile.coins).toBe(0)
		expect(profile.prestiges).toBe(0)
		expect(profile.highestStage).toBe(0)
		expect(profile.upgrades).toEqual({})
	end)

	it("reads a missing upgrade level as zero", function()
		local profile = Profile.create()
		expect(Profile.levelOf(profile, "speedGain")).toBe(0)
		profile.upgrades.speedGain = 4
		expect(Profile.levelOf(profile, "speedGain")).toBe(4)
	end)

	it("migrates missing data into a fresh profile", function()
		local profile = Profile.migrate(nil)
		expect(profile.version).toBe(Profile.SCHEMA_VERSION)
		expect(profile.speed).toBe(0)
	end)

	it("fills the gaps of a partial save", function()
		local profile = Profile.migrate({ speed = 1200, coins = 40 })
		expect(profile.speed).toBe(1200)
		expect(profile.coins).toBe(40)
		expect(profile.prestiges).toBe(0)
		expect(profile.totals.distance).toBe(0)
	end)

	it("sanitises corrupted values", function()
		local profile = Profile.migrate({
			speed = -50,
			coins = 0 / 0,
			prestiges = 2.7,
			highestStage = -3,
			upgrades = { speedGain = -3, cheat = "a lot" },
		})
		expect(profile.speed).toBe(0)
		expect(profile.coins).toBe(0)
		expect(profile.prestiges).toBe(2)
		expect(profile.highestStage).toBe(0)
		expect(profile.upgrades.speedGain).toBe(0)
		expect(profile.upgrades.cheat).toBeNil()
	end)

	-- Rien de ce qui appartient a une course ne doit survivre a une reconnexion.
	it("stores nothing about the current run", function()
		local profile = Profile.create()
		expect(profile.checkpoint).toBeNil()
		expect(profile.airJumpsUsed).toBeNil()
		expect(profile.dashCooldown).toBeNil()
	end)

	it("keeps the monetization data untouched across the migration", function()
		local profile = Profile.migrate({
			boosts = { speedRush = 1750, bogus = "yes" },
			codes = { LAUNCH = true, fake = false },
			purchases = { count = 3, spentRobux = 597, order = { "r-1", "r-2", 42 } },
			daily = { streak = 4, lastClaimAt = 990 },
			timers = { sessionChest = 120 },
			offers = { seen = { starterPack = 60 }, purchased = { starterPack = true } },
		})
		expect(profile.boosts.speedRush).toBe(1750)
		expect(profile.boosts.bogus).toBeNil()
		expect(profile.codes.LAUNCH).toBe(true)
		expect(profile.purchases.order).toEqual({ "r-1", "r-2" })
		expect(profile.purchases.ids["r-2"]).toBe(true)
		expect(profile.daily.streak).toBe(4)
		expect(profile.offers.purchased.starterPack).toBe(true)
	end)

	it("does not share tables between two fresh profiles", function()
		local first, second = Profile.create(), Profile.create()
		first.upgrades.speedGain = 3
		expect(second.upgrades.speedGain).toBeNil()
	end)
end)
