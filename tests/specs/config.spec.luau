--!nocheck
--[[
	Guard rail over the real balancing data: a configuration mistake must break the
	build, not production.
]]

local Config = require(Config)
local TierLadder = require(Domain.Run.TierLadder)
local SkyLayout = require(Domain.Run.SkyLayout)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local DragonCatalog = require(Domain.Hatchery.DragonCatalog)
local RarityTable = require(Domain.Hatchery.RarityTable)
local MoltPolicy = require(Domain.Molt.MoltPolicy)
local ProductCatalog = require(Domain.Monetization.ProductCatalog)

local KNOWN_EFFECTS = {
	speedMultiplier = true,
	goldMultiplier = true,
	agility = true,
	magnet = true,
	feathers = true,
	hatch = true,
}

describe("Config.Tiers", function()
	it("builds a valid ladder", function()
		expect(function()
			TierLadder.new(Config.Tiers)
		end).never.toThrow()
	end)

	it("numbers the tiers from 1 to N without a gap", function()
		for index, tier in Config.Tiers do
			expect(tier.id).toBe(index)
		end
	end)

	it("opens the first tier to a brand new dragon", function()
		expect(Config.Tiers[1].requiredSpeed).toBe(0)
	end)

	it("keeps every guaranteed rarity within its own cap", function()
		local rarities = RarityTable.new(Config.Monetization.rarities)
		for _, tier in Config.Tiers do
			if tier.minRarity then
				expect(rarities:indexOf(tier.minRarity)).toBeLessThanOrEqual(rarities:indexOf(tier.maxRarity))
			end
			expect(rarities:indexOf(tier.maxRarity)).never.toBeNil()
		end
	end)

	it("makes climbing one more tier clearly worth it", function()
		for index = 2, #Config.Tiers do
			local previous, current = Config.Tiers[index - 1], Config.Tiers[index]
			local ratio = (current.eggs * current.goldMultiplier) / (previous.eggs * previous.goldMultiplier)
			-- Sous 1,8 le joueur n'hesite pas ; au-dessus de 6 il n'encaisse jamais.
			expect(ratio).toBeGreaterThan(1.8)
			expect(ratio).toBeLessThan(6)
		end
	end)
end)

describe("Config.Upgrades", function()
	it("builds a valid catalog", function()
		expect(function()
			UpgradeCatalog.new(Config.Upgrades)
		end).never.toThrow()
	end)

	it("only uses effect families the domain knows", function()
		for _, definition in Config.Upgrades do
			expect(KNOWN_EFFECTS[definition.effect]).toBe(true)
		end
	end)

	it("keeps costs rising and finite", function()
		local catalog = UpgradeCatalog.new(Config.Upgrades)
		for _, id in catalog:ids() do
			expect(catalog:costFor(id, 0)).toBeGreaterThan(0)
			expect(catalog:costFor(id, 1)).toBeGreaterThan(catalog:costFor(id, 0))
			expect(catalog:costFor(id, 60)).toBeLessThan(math.huge)
		end
	end)

	it("sells agility, without which speed cannot be steered", function()
		local catalog = UpgradeCatalog.new(Config.Upgrades)
		expect(catalog:get("agility")).never.toBeNil()
	end)
end)

describe("Config.Dragons", function()
	it("builds a valid collection", function()
		expect(function()
			DragonCatalog.new(Config.Dragons)
		end).never.toThrow()
	end)

	it("offers at least one species per rarity of the table", function()
		local catalog = DragonCatalog.new(Config.Dragons)
		for _, entry in Config.Monetization.rarities do
			expect(#catalog:byRarity(entry.rarity)).toBeGreaterThan(0)
		end
	end)

	it("keeps every bonus modest enough to stay a bonus", function()
		for _, dragon in Config.Dragons do
			for _, amount in dragon.bonus do
				expect(amount).toBeGreaterThan(0)
				expect(amount).toBeLessThanOrEqual(1)
			end
		end
	end)
end)

describe("Config.Products and Passes", function()
	it("builds a valid product catalog", function()
		expect(function()
			ProductCatalog.new(Config.Products)
		end).never.toThrow()
	end)

	it("exposes unique pass ids with a numeric assetId", function()
		local seen = {}
		for _, pass in Config.Passes do
			expect(seen[pass.id]).toBeNil()
			seen[pass.id] = true
			expect(pass.assetId).toBeA("number")
		end
	end)

	it("only grants flat bonuses the domain knows", function()
		for _, pass in Config.Passes do
			for key in pass.effect.flat or {} do
				expect(KNOWN_EFFECTS[key]).toBe(true)
			end
		end
	end)

	it("points every offer at a product that exists", function()
		local catalog = ProductCatalog.new(Config.Products)
		for _, offer in Config.Monetization.offers do
			expect(catalog:get(offer.productKey)).never.toBeNil()
		end
	end)
end)

describe("Config.Balance", function()
	it("keeps flight velocity under the physics ceiling", function()
		local curve = Config.Balance.speedCurve
		expect(curve.baseVelocity + curve.maxBonusVelocity).toBeLessThanOrEqual(300)
	end)

	it("leaves an anti-cheat margin above 1", function()
		expect(Config.Balance.flight.toleranceFactor).toBeGreaterThan(1)
		expect(Config.Balance.flight.sampleInterval).toBeGreaterThan(0)
	end)

	-- Muer doit vouloir dire "j'ai fini le ciel", pas "j'ai un peu joue".
	it("asks for the last tier before the first molt", function()
		local policy = MoltPolicy.new(Config.Balance.molt)
		expect(policy:requirementFor(0)).toBeGreaterThanOrEqual(Config.Tiers[#Config.Tiers].requiredSpeed)
		expect(policy:multiplierFor(1)).toBeGreaterThan(1)
	end)

	it("lays the sky out beyond the Nest", function()
		local layout = SkyLayout.new(Config.Balance.sky, Config.Tiers)
		expect(Config.Balance.sky.launchX).toBeGreaterThan(Config.World.nest.size / 2)
		expect(layout:totalLength()).toBeGreaterThan(4000)
		expect(layout:tierAt(0)).toBeNil()
		expect(layout:tierAt(Config.Balance.sky.launchX)).toBe(1)
	end)

	-- L'Autel doit rester atteignable : hors du couloir, mais pas hors de portee.
	it("keeps the altar detour off the line yet reachable", function()
		local sky = Config.Balance.sky
		expect(sky.altarOffset).toBeGreaterThan(sky.corridorWidth / 2)
		expect(sky.altarOffset).toBeLessThan(sky.corridorWidth * 1.5)
	end)
end)
