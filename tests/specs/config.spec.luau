--!nocheck
--[[
	Garde-fou sur les donnees d'equilibrage reelles : une erreur de config doit casser
	la CI, pas la production.
]]

local Config = require(Config)
local ZoneLadder = require(Domain.Zones.ZoneLadder)
local TrackLayout = require(Domain.Zones.TrackLayout)
local UpgradeCatalog = require(Domain.Economy.UpgradeCatalog)
local RebirthPolicy = require(Domain.Rebirth.RebirthPolicy)

local KNOWN_EFFECTS =
	{ speedMultiplier = true, bananaMultiplier = true, jumpPower = true, wallGrip = true, airDash = true }

describe("Config.Zones", function()
	it("construit une echelle valide", function()
		expect(function()
			ZoneLadder.new(Config.Zones)
		end).never.toThrow()
	end)

	it("numerote les zones de 1 a N sans trou", function()
		for index, zone in Config.Zones do
			expect(zone.id).toBe(index)
		end
	end)

	it("fait croitre les recompenses avec la difficulte", function()
		for index = 2, #Config.Zones do
			local previous, current = Config.Zones[index - 1], Config.Zones[index]
			expect(current.stepMultiplier).toBeGreaterThan(previous.stepMultiplier)
			expect(current.bananaMultiplier).toBeGreaterThan(previous.bananaMultiplier)
		end
	end)

	it("donne un nom, une couleur et une longueur a chaque zone", function()
		for _, zone in Config.Zones do
			expect(zone.name).toBeA("string")
			expect(zone.length).toBeGreaterThan(100)
			expect(#zone.color).toBe(3)
		end
	end)
end)

describe("Config.Upgrades", function()
	it("construit un catalogue valide", function()
		expect(function()
			UpgradeCatalog.new(Config.Upgrades)
		end).never.toThrow()
	end)

	it("n'utilise que des familles d'effet connues du domaine", function()
		for _, definition in Config.Upgrades do
			expect(KNOWN_EFFECTS[definition.effect]).toBe(true)
		end
	end)

	it("garde des couts croissants et finis", function()
		local catalog = UpgradeCatalog.new(Config.Upgrades)
		for _, id in catalog:ids() do
			expect(catalog:costFor(id, 0)).toBeGreaterThan(0)
			expect(catalog:costFor(id, 1)).toBeGreaterThan(catalog:costFor(id, 0))
			expect(catalog:costFor(id, 60)).toBeLessThan(math.huge)
		end
	end)
end)

describe("Config.Passes", function()
	it("expose des identifiants uniques et un assetId numerique", function()
		local seen = {}
		for _, pass in Config.Passes do
			expect(seen[pass.id]).toBeNil()
			seen[pass.id] = true
			expect(pass.assetId).toBeA("number")
		end
	end)

	it("n'accorde que des bonus plats connus", function()
		for _, pass in Config.Passes do
			for key in pass.effect.flat or {} do
				expect(KNOWN_EFFECTS[key]).toBe(true)
			end
		end
	end)
end)

describe("Config.Balance", function()
	it("laisse la vitesse sous le seuil d'instabilite physique", function()
		local curve = Config.Balance.speedCurve
		expect(curve.baseWalkSpeed + curve.maxBonusWalkSpeed).toBeLessThanOrEqual(250)
	end)

	it("laisse une marge anti-triche superieure a 1", function()
		expect(Config.Balance.movement.toleranceFactor).toBeGreaterThan(1)
		expect(Config.Balance.movement.sampleInterval).toBeGreaterThan(0)
	end)

	it("propose une premiere renaissance atteignable", function()
		local policy = RebirthPolicy.new(Config.Balance.rebirth)
		expect(policy:requirementFor(0)).toBeGreaterThan(0)
		expect(policy:requirementFor(1)).toBeGreaterThan(policy:requirementFor(0))
		expect(policy:multiplierFor(1)).toBeGreaterThan(1)
	end)

	it("place la piste au-dela du hub", function()
		local layout = TrackLayout.new(Config.Balance.layout, Config.Zones)
		expect(Config.Balance.layout.trackStartX).toBeGreaterThanOrEqual(Config.World.hub.size / 2)
		expect(layout:totalLength()).toBeGreaterThan(1000)
		expect(layout:zoneAt(0)).toBeNil()
		expect(layout:zoneAt(Config.Balance.layout.trackStartX)).toBe(1)
	end)

	it("relie le hub a la piste par une passerelle marchable", function()
		-- Regression : le hub s'arretait a 130 et la piste demarrait a 200, soit
		-- 70 studs de vide qu'aucun saut ne franchit. Le generateur pose desormais
		-- une passerelle, mais elle doit rester d'une largeur credible.
		local gap = Config.Balance.layout.trackStartX - Config.World.hub.size / 2
		expect(gap).toBeGreaterThanOrEqual(0)
		expect(Config.World.approach.width).toBeGreaterThan(20)
		expect(Config.World.approach.width).toBeLessThanOrEqual(Config.Balance.layout.trackWidth)
	end)

	it("garde une piste plus large que la passerelle qui y mene", function()
		expect(Config.Balance.layout.trackWidth).toBeGreaterThanOrEqual(Config.World.approach.width)
	end)
end)
