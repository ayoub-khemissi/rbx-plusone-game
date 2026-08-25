--!strict
--[[
	CourseReward — what touching the plate at the end of a course pays.

	IT IS A SHARE OF WHAT THE NEXT COURSE COSTS. That figure is the only one that
	says how big this stretch of the game is, so a reward drawn from it scales on
	its own and never has to be retuned course by course. A flat amount would make
	the first course the best one to farm forever, which is the failure mode this
	whole mechanic invites.

	The share is deliberately modest: roughly what running the course pays anyway.
	The plate is worth touching for the Coins and the ride home, not because it
	beats playing — a plate that outpaces running turns a platformer into a queue.

	The last course has no next one, so it is worth what it cost to reach.
]]

export type Tuning = {
	share: number,
	minimum: number,
	coinsPerSpeed: number,
}

export type Reward = {
	speed: number,
	coins: number,
}

local CourseReward = {}
CourseReward.__index = CourseReward

export type CourseReward = typeof(setmetatable({} :: Tuning, CourseReward))

function CourseReward.new(tuning: Tuning): CourseReward
	return setmetatable({
		share = tuning.share,
		minimum = tuning.minimum,
		coinsPerSpeed = tuning.coinsPerSpeed,
	}, CourseReward)
end

--[[ What finishing `stage` pays, `nextStage` being the one after it if any. ]]
function CourseReward.forStage(self: CourseReward, stage: any, nextStage: any): Reward?
	if not stage then
		return nil
	end

	local basis = (nextStage and nextStage.requiredSpeed) or stage.requiredSpeed or 0
	local speed = math.max(math.floor(basis * self.share), self.minimum)

	-- Coins take the stage multiplier on top, so a deeper course pays twice over:
	-- once for being bigger, once for being deeper.
	local coins = math.floor(speed * self.coinsPerSpeed * (stage.coinMultiplier or 1))

	return { speed = speed, coins = coins }
end

return CourseReward
