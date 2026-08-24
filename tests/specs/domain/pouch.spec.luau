--!nocheck
local Pouch = require(Domain.Run.Pouch)
local Profile = require(Domain.Profile.Profile)

local TIER_3 = { id = 3, goldMultiplier = 3, eggs = 6, maxRarity = "rare" }
local TIER_5 = { id = 5, goldMultiplier = 6, eggs = 25, maxRarity = "rare" }

describe("Pouch", function()
	local pouch, profile
	beforeEach(function()
		pouch = Pouch.new()
		profile = Profile.create()
	end)

	it("starts empty", function()
		expect(Pouch.isEmpty(pouch)).toBe(true)
		expect(pouch.gold).toBe(0)
		expect(pouch.tierId).toBe(0)
	end)

	it("collects gold while flying", function()
		Pouch.addGold(pouch, 40)
		Pouch.addGold(pouch, 60)
		expect(pouch.gold).toBe(100)
		expect(Pouch.isEmpty(pouch)).toBe(false)
	end)

	it("ignores invalid gold amounts coming from the world", function()
		Pouch.addGold(pouch, -10)
		Pouch.addGold(pouch, 0 / 0)
		expect(pouch.gold).toBe(0)
	end)

	-- Le butin est celui du tier ATTEINT, pas la somme des tiers traverses :
	-- c'est ce qui rend le choix de continuer lisible (x2,5 d'un coup).
	it("keeps the loot of the highest tier reached, not the sum", function()
		Pouch.reachTier(pouch, TIER_3)
		Pouch.reachTier(pouch, TIER_5)
		expect(pouch.tierId).toBe(5)
		expect(Pouch.preview(pouch).eggs).toBe(25)
	end)

	it("never downgrades when an older tier is reported again", function()
		Pouch.reachTier(pouch, TIER_5)
		Pouch.reachTier(pouch, TIER_3)
		expect(pouch.tierId).toBe(5)
	end)

	it("multiplies carried gold by the tier reached", function()
		Pouch.addGold(pouch, 100)
		Pouch.reachTier(pouch, TIER_3)
		expect(Pouch.preview(pouch).gold).toBe(300)
	end)

	it("previews nothing before the first tier is reached", function()
		Pouch.addGold(pouch, 100)
		local preview = Pouch.preview(pouch)
		expect(preview.gold).toBe(0)
		expect(preview.eggs).toBe(0)
	end)

	it("banks the pouch into the profile and empties it", function()
		Pouch.addGold(pouch, 100)
		Pouch.reachTier(pouch, TIER_3)

		local banked = Pouch.bank(pouch, profile)

		expect(banked.gold).toBe(300)
		expect(banked.eggs).toBe(6)
		expect(banked.maxRarity).toBe("rare")
		expect(profile.gold).toBe(300)
		expect(Pouch.isEmpty(pouch)).toBe(true)
		expect(pouch.tierId).toBe(0)
	end)

	it("records the deepest tier ever banked", function()
		Pouch.reachTier(pouch, TIER_5)
		Pouch.bank(pouch, profile)
		expect(profile.deepestTier).toBe(5)

		local second = Pouch.new()
		Pouch.reachTier(second, TIER_3)
		Pouch.bank(second, profile)
		expect(profile.deepestTier).toBe(5)
	end)

	it("refuses to bank an untouched pouch", function()
		local banked = Pouch.bank(pouch, profile)
		expect(banked).toBeNil()
		expect(profile.gold).toBe(0)
	end)

	it("drops everything on death and reports the loss", function()
		Pouch.addGold(pouch, 100)
		Pouch.reachTier(pouch, TIER_5)

		local lost = Pouch.drop(pouch)

		expect(lost.gold).toBe(600)
		expect(lost.eggs).toBe(25)
		expect(profile.gold).toBe(0)
		expect(Pouch.isEmpty(pouch)).toBe(true)
	end)

	-- Le filet de securite : un vol rate rend quand meme le joueur plus rapide.
	it("never touches permanent speed", function()
		profile.speed = 5000
		Pouch.addGold(pouch, 100)
		Pouch.reachTier(pouch, TIER_5)
		Pouch.drop(pouch)
		expect(profile.speed).toBe(5000)
	end)

	it("applies an insurance ratio when the flight is insured", function()
		Pouch.addGold(pouch, 100)
		Pouch.reachTier(pouch, TIER_3)

		local rescued = Pouch.drop(pouch, { insuranceRatio = 0.5, profile = profile })

		expect(rescued.rescuedGold).toBe(150)
		expect(rescued.rescuedEggs).toBe(3)
		expect(profile.gold).toBe(150)
	end)

	-- Les oeufs sortent du sac avec une rarete MAXIMALE, pas une rarete tiree :
	-- le tirage a besoin d'alea, il appartient donc a la couche Application.
	it("hands the egg payload to the caller instead of rolling rarity itself", function()
		Pouch.reachTier(pouch, TIER_5)
		local banked = Pouch.bank(pouch, profile)
		expect(banked.eggs).toBe(25)
		expect(banked.maxRarity).toBe("rare")
		expect(banked.tierId).toBe(5)
	end)
end)
