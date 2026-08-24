--!nocheck
local RarityTable = require(Domain.Hatchery.RarityTable)
local Clutch = require(Domain.Hatchery.Clutch)
local DragonCatalog = require(Domain.Hatchery.DragonCatalog)
local Profile = require(Domain.Profile.Profile)

local RARITIES = {
	{ rarity = "common", weight = 70 },
	{ rarity = "rare", weight = 25 },
	{ rarity = "epic", weight = 5 },
}

describe("RarityTable", function()
	local rarities
	beforeEach(function()
		rarities = RarityTable.new(RARITIES)
	end)

	it("keeps the rarities ordered from common to precious", function()
		expect(rarities:order()).toEqual({ "common", "rare", "epic" })
		expect(rarities:indexOf("rare")).toBe(2)
		expect(rarities:indexOf("mythic")).toBeNil()
	end)

	it("rolls within the weights", function()
		expect(rarities:roll("epic", 0)).toBe("common")
		expect(rarities:roll("epic", 0.5)).toBe("common")
		expect(rarities:roll("epic", 0.8)).toBe("rare")
		expect(rarities:roll("epic", 0.99)).toBe("epic")
	end)

	-- Un tier "rare max" ne doit jamais lacher d'epique, meme sur un tirage chanceux.
	it("never rolls above the cap of the tier", function()
		for _, value in { 0, 0.3, 0.7, 0.95, 1 } do
			expect(rarities:roll("rare", value)).never.toBe("epic")
		end
		expect(rarities:roll("common", 0.999)).toBe("common")
	end)

	it("renormalises the weights under the cap", function()
		-- Sous plafond "rare", les poids 70/25 deviennent 73,7 % / 26,3 %.
		expect(rarities:roll("rare", 0.7)).toBe("common")
		expect(rarities:roll("rare", 0.8)).toBe("rare")
	end)

	it("falls back to the lowest rarity when the cap is unknown", function()
		expect(rarities:roll("legendary", 0.99)).toBe("epic")
		expect(rarities:roll(nil, 0.99)).toBe("common")
	end)
end)

describe("Clutch", function()
	local clutch, profile
	beforeEach(function()
		clutch = Clutch.new({
			slots = 2,
			durations = { common = 300, rare = 900, epic = 3600 },
			perchMultiplier = 2,
		})
		profile = Profile.create()
		Profile.addEggs(profile, "common", 3)
	end)

	it("reports free slots", function()
		expect(clutch:freeSlots(profile)).toBe(2)
	end)

	it("moves an egg from the stock into a slot", function()
		local placed = clutch:place(profile, "common", 1000)

		expect(placed.ok).toBe(true)
		expect(Profile.eggsOf(profile, "common")).toBe(2)
		expect(#profile.hatchery).toBe(1)
		expect(profile.hatchery[1].readyAt).toBe(1300)
	end)

	it("refuses to place an egg the player does not own", function()
		expect(clutch:place(profile, "epic", 0).code).toBe("NO_EGG")
	end)

	it("refuses to place beyond the available slots", function()
		clutch:place(profile, "common", 0)
		clutch:place(profile, "common", 0)
		local third = clutch:place(profile, "common", 0)

		expect(third.code).toBe("NO_SLOT")
		expect(Profile.eggsOf(profile, "common")).toBe(1)
	end)

	it("grants extra slots when the player bought them", function()
		expect(clutch:freeSlots(profile, 2)).toBe(4)
	end)

	it("counts down in real time, even offline", function()
		clutch:place(profile, "common", 1000)

		local waiting = clutch:statusFor(profile, 1100)
		expect(waiting[1].remaining).toBe(200)
		expect(waiting[1].ready).toBe(false)

		local done = clutch:statusFor(profile, 99999)
		expect(done[1].remaining).toBe(0)
		expect(done[1].ready).toBe(true)
	end)

	it("refuses to collect an egg that is still warm", function()
		clutch:place(profile, "common", 0)
		expect(clutch:collect(profile, 1, 100).code).toBe("NOT_READY")
		expect(#profile.hatchery).toBe(1)
	end)

	it("collects a hatched egg and frees the slot", function()
		clutch:place(profile, "common", 0)
		local hatched = clutch:collect(profile, 1, 500)

		expect(hatched.ok).toBe(true)
		expect(hatched.value.rarity).toBe("common")
		expect(#profile.hatchery).toBe(0)
		expect(profile.totals.eggsHatched).toBe(1)
	end)

	it("rejects a slot index that does not exist", function()
		expect(clutch:collect(profile, 7, 0).code).toBe("NO_EGG")
		expect(clutch:collect(profile, "1", 0).code).toBe("NO_EGG")
	end)

	-- Le perchoir : rester connecte accelere la couvaison sans punir l'absence.
	it("speeds incubation up while the player is perched", function()
		clutch:place(profile, "common", 0)
		clutch:perch(profile, 10)
		expect(profile.hatchery[1].readyAt).toBe(290)
	end)

	it("never pulls a ready egg back into the past", function()
		clutch:place(profile, "common", 0)
		clutch:perch(profile, 10000)
		expect(profile.hatchery[1].readyAt).toBeGreaterThanOrEqual(0)
	end)
end)

describe("DragonCatalog", function()
	local catalog, profile

	local SPECIES = {
		{ id = "emberling", name = "Emberling", rarity = "common", bonus = { gold = 0.05 } },
		{ id = "mossback", name = "Mossback", rarity = "common", bonus = { speed = 0.05 } },
		{ id = "stormtail", name = "Stormtail", rarity = "rare", bonus = { gold = 0.2, agility = 0.1 } },
		{ id = "sunwyrm", name = "Sunwyrm", rarity = "epic", bonus = { speed = 0.5, hatch = 0.25 } },
	}

	beforeEach(function()
		catalog = DragonCatalog.new(SPECIES)
		profile = Profile.create()
	end)

	it("lists species by rarity", function()
		expect(#catalog:byRarity("common")).toBe(2)
		expect(#catalog:byRarity("epic")).toBe(1)
		expect(#catalog:byRarity("mythic")).toBe(0)
	end)

	it("picks a species deterministically from a roll value", function()
		expect(catalog:roll("common", 0).id).toBe("emberling")
		expect(catalog:roll("common", 0.99).id).toBe("mossback")
		expect(catalog:roll("epic", 0.5).id).toBe("sunwyrm")
		expect(catalog:roll("mythic", 0.5)).toBeNil()
	end)

	it("adds up the bonuses of every dragon owned", function()
		profile.dragons.emberling = 1
		profile.dragons.stormtail = 2

		local bonuses = catalog:bonusesFor(profile)

		expect(bonuses.gold).toBeCloseTo(0.05 + 0.2 * 2, 1e-9)
		expect(bonuses.agility).toBeCloseTo(0.2, 1e-9)
		expect(bonuses.speed).toBe(0)
	end)

	it("reports collection progress, which is what brings players back", function()
		profile.dragons.emberling = 3
		local progress = catalog:completion(profile)

		expect(progress.owned).toBe(1)
		expect(progress.total).toBe(4)
		expect(progress.byRarity.common.owned).toBe(1)
		expect(progress.byRarity.common.total).toBe(2)
	end)

	it("refuses two species sharing an id", function()
		expect(function()
			DragonCatalog.new({ SPECIES[1], SPECIES[1] })
		end).toThrow("emberling")
	end)
end)

describe("RarityTable guarantees", function()
	local rarities
	beforeEach(function()
		rarities = RarityTable.new(RARITIES)
	end)

	-- Les tiers profonds promettent une rarete minimale : la promesse doit tenir
	-- meme sur un tirage malchanceux.
	it("honours a guaranteed floor on an unlucky roll", function()
		expect(rarities:roll("epic", 0, "rare")).toBe("rare")
		expect(rarities:roll("epic", 0.99, "rare")).toBe("epic")
	end)

	it("never lets the floor break the cap", function()
		expect(rarities:roll("common", 0, "epic")).toBe("common")
	end)

	it("ignores an unknown floor", function()
		expect(rarities:roll("epic", 0, "mythic")).toBe("common")
	end)
end)
