--!nocheck
local Profile = require(Domain.Profile.Profile)

describe("Profile", function()
	it("creates a coherent new profile", function()
		local profile = Profile.create()
		expect(profile.version).toBe(3)
		expect(profile.speed).toBe(0)
		expect(profile.gold).toBe(0)
		expect(profile.molts).toBe(0)
		expect(profile.deepestTier).toBe(0)
		expect(profile.upgrades).toEqual({})
		expect(profile.eggs).toEqual({})
		expect(profile.hatchery).toEqual({})
		expect(profile.dragons).toEqual({})
	end)

	it("reads a missing upgrade level as zero", function()
		local profile = Profile.create()
		expect(Profile.levelOf(profile, "speedGain")).toBe(0)
		profile.upgrades.speedGain = 4
		expect(Profile.levelOf(profile, "speedGain")).toBe(4)
	end)

	it("stacks eggs by rarity", function()
		local profile = Profile.create()
		Profile.addEggs(profile, "rare", 2)
		Profile.addEggs(profile, "rare", 3)
		expect(Profile.eggsOf(profile, "rare")).toBe(5)
		expect(Profile.eggsOf(profile, "epic")).toBe(0)
	end)

	it("ignores negative or fractional egg counts", function()
		local profile = Profile.create()
		Profile.addEggs(profile, "rare", -5)
		Profile.addEggs(profile, "rare", 2.7)
		expect(Profile.eggsOf(profile, "rare")).toBe(2)
	end)

	it("migrates missing data into a fresh profile", function()
		local profile = Profile.migrate(nil)
		expect(profile.version).toBe(3)
		expect(profile.speed).toBe(0)
	end)

	it("fills the gaps of a partial save", function()
		local profile = Profile.migrate({ speed = 1200, gold = 40 })
		expect(profile.speed).toBe(1200)
		expect(profile.gold).toBe(40)
		expect(profile.molts).toBe(0)
		expect(profile.totals.distance).toBe(0)
	end)

	it("sanitises corrupted values", function()
		local profile = Profile.migrate({
			speed = -50,
			gold = 0 / 0,
			molts = 2.7,
			deepestTier = -3,
			upgrades = { speedGain = -3, cheat = "a lot" },
			dragons = { emberling = 2.9, ghost = "yes" },
		})
		expect(profile.speed).toBe(0)
		expect(profile.gold).toBe(0)
		expect(profile.molts).toBe(2)
		expect(profile.deepestTier).toBe(0)
		expect(profile.upgrades.speedGain).toBe(0)
		expect(profile.upgrades.cheat).toBeNil()
		expect(profile.dragons.emberling).toBe(2)
		expect(profile.dragons.ghost).toBeNil()
	end)

	it("restores incubating eggs with their ready time", function()
		local profile = Profile.migrate({
			eggs = { rare = 4 },
			hatchery = { { rarity = "rare", readyAt = 1750 }, { broken = true }, "nope" },
		})
		expect(Profile.eggsOf(profile, "rare")).toBe(4)
		expect(#profile.hatchery).toBe(1)
		expect(profile.hatchery[1].readyAt).toBe(1750)
	end)

	it("keeps the monetization data untouched across the migration", function()
		local profile = Profile.migrate({
			boosts = { swiftRush = 1750, bogus = "yes" },
			codes = { LAUNCH = true, fake = false },
			purchases = { count = 3, spentRobux = 597, order = { "r-1", "r-2", 42 } },
			daily = { streak = 4, lastClaimAt = 990 },
			timers = { chest = 120 },
			offers = { seen = { starterPack = 60 }, purchased = { starterPack = true } },
		})
		expect(profile.boosts.swiftRush).toBe(1750)
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
