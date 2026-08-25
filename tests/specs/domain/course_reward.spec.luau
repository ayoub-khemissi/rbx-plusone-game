--!nocheck
local CourseReward = require(Domain.Run.CourseReward)

local TUNING = { share = 0.02, minimum = 300, coinsPerSpeed = 0.5 }
local STAGES = {
	{ id = 1, requiredSpeed = 0, coinMultiplier = 1 },
	{ id = 2, requiredSpeed = 10000, coinMultiplier = 2 },
	{ id = 3, requiredSpeed = 40000, coinMultiplier = 3 },
}

describe("CourseReward", function()
	local rewards
	beforeEach(function()
		rewards = CourseReward.new(TUNING)
	end)

	--[[
		A course pays a share of what the NEXT one costs to enter, which is the only
		figure that says how big this stretch of the game is. Paying a flat amount
		would make the first course the best one to farm forever.
	]]
	it("pays out of what the next course costs", function()
		local reward = rewards:forStage(STAGES[2], STAGES[3])
		expect(reward.speed).toBe(math.floor(40000 * TUNING.share))
	end)

	it("pays more for a course further in", function()
		local first = rewards:forStage(STAGES[1], STAGES[2])
		local second = rewards:forStage(STAGES[2], STAGES[3])
		expect(second.speed).toBeGreaterThan(first.speed)
	end)

	-- The first course has almost nothing behind it, and no reward at all would
	-- teach a new player that the plate is not worth touching.
	it("never pays less than the floor", function()
		expect(rewards:forStage(STAGES[1], STAGES[2]).speed).toBe(TUNING.minimum)
	end)

	-- The last course has no next one; it is worth what it cost to reach.
	it("pays the last course out of its own cost", function()
		local reward = rewards:forStage(STAGES[3], nil)
		expect(reward.speed).toBe(math.floor(40000 * TUNING.share))
	end)

	--[[
		Coins follow the experience and then take the stage multiplier, so a deeper
		course pays twice over — once for being bigger, once for being deeper.
	]]
	it("scales the coins with the stage multiplier", function()
		local reward = rewards:forStage(STAGES[2], STAGES[3])
		expect(reward.coins).toBe(math.floor(reward.speed * TUNING.coinsPerSpeed * 2))
	end)

	it("refuses a stage it was not given", function()
		expect(rewards:forStage(nil, nil)).toBeNil()
	end)
end)
