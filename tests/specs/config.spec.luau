--!nocheck
--[[
	Guard rail over the real balancing data: a configuration mistake must break the
	build, not production.
]]

local Config = require(Config)
local StageLadder = require(Domain.Run.StageLadder)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local PrestigePolicy = require(Domain.Prestige.PrestigePolicy)
local SpeedCurve = require(Domain.Movement.SpeedCurve)
local JumpBudget = require(Domain.Movement.JumpBudget)
local DashPolicy = require(Domain.Movement.DashPolicy)
local ProductCatalog = require(Domain.Monetization.ProductCatalog)

local KNOWN_EFFECTS = {
	speedMultiplier = true,
	coinMultiplier = true,
	jumpPower = true,
	jumps = true,
	dash = true,
	magnet = true,
}

describe("Config.Stages", function()
	it("builds a valid ladder", function()
		expect(function()
			StageLadder.new(Config.Stages)
		end).never.toThrow()
	end)

	it("numbers the stages from 1 to N without a gap", function()
		for index, stage in Config.Stages do
			expect(stage.id).toBe(index)
		end
	end)

	it("opens the first stage to a brand new player", function()
		expect(Config.Stages[1].requiredSpeed).toBe(0)
	end)

	it("makes reaching one more stage clearly worth it", function()
		for index = 2, #Config.Stages do
			local previous, current = Config.Stages[index - 1], Config.Stages[index]
			local ratio = current.coinMultiplier / previous.coinMultiplier
			expect(ratio).toBeGreaterThan(1.2)
			expect(ratio).toBeLessThan(3)
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
			expect(catalog:costFor(id, 20)).toBeLessThan(math.huge)
		end
	end)

	-- Les deux mecaniques que le joueur vient chercher doivent etre achetables.
	it("sells both the extra jumps and the dash", function()
		local catalog = UpgradeCatalog.new(Config.Upgrades)
		expect(catalog:get("jump")).never.toBeNil()
		expect(catalog:get("dash")).never.toBeNil()
	end)

	it("caps the upgrades exactly where the domain caps them", function()
		local catalog = UpgradeCatalog.new(Config.Upgrades)
		local jumps = JumpBudget.new(Config.Balance.movement)
		local dash = DashPolicy.new(Config.Balance.dash)

		-- Acheter le dernier niveau doit donner le niveau maximum, ni plus ni moins.
		expect(jumps:levelFor({ flat = { jumps = catalog:get("jump").maxLevel } })).toBe(
			Config.Balance.movement.maxJumpLevel
		)
		expect(dash:levelFor({ flat = { dash = catalog:get("dash").maxLevel } })).toBe(
			Config.Balance.dash.maxLevel
		)
	end)
end)

describe("Config.Balance", function()
	-- Regression : a 500 de Speed le personnage courait a 82 studs/s, soit cinq fois
	-- la vitesse par defaut. Un parcours a trous devient injouable bien avant.
	it("keeps the character controllable at every point of the curve", function()
		local curve = SpeedCurve.new(Config.Balance.speedCurve)

		-- Les premieres minutes doivent se sentir, sans devenir incontrolables.
		expect(curve:walkSpeedFor(500)).toBeGreaterThan(Config.Balance.speedCurve.baseWalkSpeed)
		expect(curve:walkSpeedFor(500)).toBeLessThan(24)

		-- Au seuil de Prestige, on est rapide mais on pose encore ses sauts.
		local prestige = PrestigePolicy.new(Config.Balance.prestige):requirementFor(0)
		expect(curve:walkSpeedFor(prestige)).toBeLessThan(60)

		-- Et le plafond reste franchement sous la limite physique de Roblox.
		expect(curve:walkSpeedFor(1e12)).toBeLessThanOrEqual(60)
	end)

	it("leaves an anti-cheat margin above 1", function()
		expect(Config.Balance.movement.toleranceFactor).toBeGreaterThan(1)
		expect(Config.Balance.movement.sampleInterval).toBeGreaterThan(0)
	end)

	it("keeps the dash worth upgrading", function()
		local dash = DashPolicy.new(Config.Balance.dash)
		expect(dash:powerFor(1)).toBeGreaterThan(0)
		expect(dash:powerFor(3)).toBeGreaterThan(dash:powerFor(1))
		expect(Config.Balance.dash.cooldown).toBeGreaterThan(0)
	end)

	-- Prestige doit vouloir dire "j'ai fini le parcours", pas "j'ai un peu joue".
	it("asks for the last stage before the first prestige", function()
		local policy = PrestigePolicy.new(Config.Balance.prestige)
		expect(policy:requirementFor(0)).toBeGreaterThanOrEqual(Config.Stages[#Config.Stages].requiredSpeed)
		expect(policy:multiplierFor(1)).toBeGreaterThan(1)
	end)
end)

describe("Config.Theme", function()
	-- Le theme ne porte que de l'affichage : aucun nombre d'equilibrage.
	it("names every core concept", function()
		for _, key in { "speed", "coins", "prestige", "stage", "checkpoint", "hub" } do
			local label = Config.Theme.labels[key]
			expect(label).never.toBeNil()
			expect(label.name).toBeA("string")
			expect(label.icon).toBeA("string")
		end
	end)

	it("carries no balancing number", function()
		expect(Config.Theme.labels.speed.baseWalkSpeed).toBeNil()
		expect(Config.Theme.requiredSpeed).toBeNil()
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
