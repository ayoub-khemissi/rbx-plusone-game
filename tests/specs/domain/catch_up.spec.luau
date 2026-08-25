--!nocheck
local Progression = require(Domain.Movement.Progression)
local LevelCurve = require(Domain.Run.LevelCurve)
local SpeedCurve = require(Domain.Movement.SpeedCurve)
local MovementAccounting = require(Domain.Movement.MovementAccounting)
local JumpBudget = require(Domain.Movement.JumpBudget)
local DashPolicy = require(Domain.Movement.DashPolicy)
local Profile = require(Domain.Profile.Profile)
local Config = require(Config)

local CATCH_UP = 8
local BONUSES = { speed = 1, coins = 1, flat = {} }

local function build()
	local levels = LevelCurve.new({ base = 20, exponent = 2 })
	return Progression.new({
		curve = SpeedCurve.new(Config.Balance.speedCurve),
		levels = levels,
		accounting = MovementAccounting.new(Config.Balance.movement),
		multipliers = { compute = function() end },
		jumpBudget = JumpBudget.new(Config.Balance.movement),
		dashPolicy = DashPolicy.new(Config.Balance.dash),
		tuning = { speedPerStep = 1, coinsPerStep = 0.4, catchUp = CATCH_UP },
	}),
		levels
end

describe("Progression, climbing back after a rebirth", function()
	local progression, levels, profile
	beforeEach(function()
		progression, levels = build()
		profile = Profile.create()
	end)

	--[[
		A rebirth takes the experience and leaves the multiplier. With an exponent
		near two, nine tenths of a world sits in its last tenth of levels, so without
		this most of every cycle is spent re-walking ground the player had already
		walked, at a pace they had already outgrown.
	]]
	it("pays faster on ground already covered", function()
		profile.bestLevel = 50
		local outcome = progression:credit(profile, 10, BONUSES, 1)

		expect(outcome.speedGained).toBe(10 * CATCH_UP)
	end)

	it("pays the normal rate to a player who has never been anywhere", function()
		local outcome = progression:credit(profile, 10, BONUSES, 1)
		expect(outcome.speedGained).toBe(10)
	end)

	-- New ground is what a world is made of, and it costs what it costs.
	it("stops the moment the player passes their best", function()
		profile.bestLevel = 10
		profile.speed = levels:requirementFor(10)

		expect(progression:credit(profile, 10, BONUSES, 1).speedGained).toBe(10)
	end)

	--[[
		It is paid on the gain and never on the price of a level. A discount on known
		levels would raise the level a given Speed reads as, every rebirth, until the
		number on the screen meant nothing — which is the reason this lives here and
		not in LevelCurve.
	]]
	it("leaves the ladder exactly where it was", function()
		local before = levels:levelFor(100000)
		profile.bestLevel = 400
		progression:credit(profile, 10, BONUSES, 1)

		expect(levels:levelFor(100000)).toBe(before)
	end)

	it("never pays the Coins twice", function()
		profile.bestLevel = 50
		expect(progression:credit(profile, 10, BONUSES, 1).coinsGained).toBe(10 * 0.4)
	end)

	it("raises the best as new ground is covered", function()
		progression:credit(profile, 10000, BONUSES, 1)
		expect(profile.bestLevel).toBe(levels:levelFor(profile.speed))
	end)
end)
