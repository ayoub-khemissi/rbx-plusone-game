--!nocheck
local Requirements = require(Domain.Progression.Requirements)
local Profile = require(Domain.Profile.Profile)

describe("Requirements", function()
	local rules, profile, context

	beforeEach(function()
		rules = Requirements.new()
		profile = Profile.create()
		context = function()
			return { profile = profile, level = 1, passes = {} }
		end
	end)

	it("lets anything through when nothing is required", function()
		expect(rules:evaluate(nil, context()).met).toBe(true)
		expect(rules:evaluate({}, context()).met).toBe(true)
	end)

	describe("upgrade", function()
		it("holds until the upgrade has been bought", function()
			local needs = { { kind = "upgrade", id = "dash", level = 1 } }

			expect(rules:evaluate(needs, context()).met).toBe(false)

			profile.upgrades.dash = 1
			expect(rules:evaluate(needs, context()).met).toBe(true)
		end)

		it("can ask for more than the first level", function()
			local needs = { { kind = "upgrade", id = "dash", level = 3 } }

			profile.upgrades.dash = 2
			expect(rules:evaluate(needs, context()).met).toBe(false)

			profile.upgrades.dash = 3
			expect(rules:evaluate(needs, context()).met).toBe(true)
		end)
	end)

	describe("level and prestige", function()
		it("holds until the player is high enough", function()
			local needs = { { kind = "level", value = 10 } }

			expect(rules:evaluate(needs, { profile = profile, level = 9 }).met).toBe(false)
			expect(rules:evaluate(needs, { profile = profile, level = 10 }).met).toBe(true)
		end)

		it("holds until enough prestiges", function()
			local needs = { { kind = "prestiges", value = 2 } }

			profile.prestiges = 1
			expect(rules:evaluate(needs, context()).met).toBe(false)

			profile.prestiges = 2
			expect(rules:evaluate(needs, context()).met).toBe(true)
		end)
	end)

	describe("stage and pass", function()
		it("holds until a stage has been reached", function()
			local needs = { { kind = "stage", value = 3 } }

			profile.highestStage = 2
			expect(rules:evaluate(needs, context()).met).toBe(false)

			profile.highestStage = 3
			expect(rules:evaluate(needs, context()).met).toBe(true)
		end)

		it("holds until a pass is owned", function()
			local needs = { { kind = "pass", id = "vip" } }

			expect(rules:evaluate(needs, context()).met).toBe(false)
			expect(rules:evaluate(needs, { profile = profile, passes = { vip = true } }).met).toBe(true)
		end)
	end)

	--[[
		Every condition has to pass, and the ones that did not have to come back:
		"locked" on its own is a dead end for the player, while "needs the Dash"
		tells them what to do next.
	]]
	it("requires all of them, and names the ones that failed", function()
		local needs = {
			{ kind = "upgrade", id = "dash", level = 1 },
			{ kind = "level", value = 10 },
		}

		local outcome = rules:evaluate(needs, { profile = profile, level = 4 })
		expect(outcome.met).toBe(false)
		expect(#outcome.unmet).toBe(2)

		profile.upgrades.dash = 1
		outcome = rules:evaluate(needs, { profile = profile, level = 4 })
		expect(#outcome.unmet).toBe(1)
		expect(outcome.unmet[1].kind).toBe("level")
	end)

	--[[
		A condition nobody implemented must LOCK, never open. A typo in a config
		that silently unlocked everything is the kind of bug that ships.
	]]
	it("refuses a condition it does not understand", function()
		local outcome = rules:evaluate({ { kind = "phaseOfTheMoon" } }, context())
		expect(outcome.met).toBe(false)
	end)

	it("survives a context that knows nothing", function()
		local needs = { { kind = "level", value = 3 } }
		expect(rules:evaluate(needs, { profile = profile }).met).toBe(false)
		expect(rules:evaluate(needs, {}).met).toBe(false)
	end)
end)
