--!nocheck
local World = require(Domain.Run.World)
local Profile = require(Domain.Profile.Profile)

-- The announced levels are the ones this fixture's own curve produces, so the
-- spec measures the design and never its own arithmetic.
local STAGES = {
	{ id = 1, name = "One", requiredLevel = 1, requiredSpeed = 0, coinMultiplier = 1 },
	{ id = 2, name = "Two", requiredLevel = 7, requiredSpeed = 1000, coinMultiplier = 1.5 },
	{ id = 3, name = "Three", requiredLevel = 16, requiredSpeed = 4000, coinMultiplier = 2 },
}
local LEVEL = { base = 20, exponent = 1.9 }
local DEFINITIONS = {
	{ id = 1, name = "First", scale = 1 },
	{ id = 2, name = "Second", scale = 2, requires = { { kind = "prestiges", value = 1 } } },
	{ id = 3, name = "Third", scale = 4, requires = { { kind = "prestiges", value = 2 } } },
}

describe("World", function()
	local registry, profile
	beforeEach(function()
		registry = World.registry(DEFINITIONS, { stages = STAGES, level = LEVEL })
		profile = Profile.create()
	end)

	it("puts a new player in the first world", function()
		expect(registry:forProfile(profile).id).toBe(1)
	end)

	-- A rebirth is the key: the world a player is in follows how many they have.
	it("moves a player on with every rebirth", function()
		profile.prestiges = 1
		expect(registry:forProfile(profile).id).toBe(2)
		profile.prestiges = 2
		expect(registry:forProfile(profile).id).toBe(3)
	end)

	it("keeps the last world once there are no more", function()
		profile.prestiges = 99
		expect(registry:forProfile(profile).id).toBe(#DEFINITIONS)
	end)

	--[[
		THE INVARIANT THE WHOLE DESIGN RESTS ON. A world scales the experience and
		the level curve by the same factor, so level 30 is level 30 everywhere: one
		table of speeds and jump distances builds every world, and a tenth course
		has the same gaps in the last world as in the first.
	]]
	it("reads the same level at the same point of every world", function()
		local first = registry:get(1)

		for _, definition in DEFINITIONS do
			local world = registry:get(definition.id)
			for index, stage in world.stages do
				-- Against the first world rather than against a constant: the claim
				-- is that the worlds agree, not that they match a number typed here.
				expect(world.levels:levelFor(stage.requiredSpeed)).toBe(
					first.levels:levelFor(first.stages[index].requiredSpeed)
				)
				expect(world.levels:levelFor(stage.requiredSpeed)).toBe(stage.requiredLevel)
			end
		end
	end)

	it("scales what a course costs, and nothing else about it", function()
		local first, second = registry:get(1), registry:get(2)

		expect(second.stages[3].requiredSpeed).toBe(first.stages[3].requiredSpeed * 2)
		expect(second.stages[3].requiredLevel).toBe(first.stages[3].requiredLevel)
		expect(second.stages[3].coinMultiplier).toBe(first.stages[3].coinMultiplier)
	end)

	it("hands out a usable ladder for each world", function()
		local second = registry:get(2)
		expect(second.ladder:highestUnlocked(0)).toBe(1)
		expect(second.ladder:highestUnlocked(second.stages[2].requiredSpeed)).toBe(2)
	end)

	describe("unlocking", function()
		it("refuses a world the rebirths do not open", function()
			expect(registry:isOpen(2, profile)).toBe(false)
			profile.prestiges = 1
			expect(registry:isOpen(2, profile)).toBe(true)
		end)

		it("always opens the first one", function()
			expect(registry:isOpen(1, profile)).toBe(true)
		end)

		it("treats a world that does not exist as closed", function()
			expect(registry:isOpen(99, profile)).toBe(false)
		end)
	end)
end)
