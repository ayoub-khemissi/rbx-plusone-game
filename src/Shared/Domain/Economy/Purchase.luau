--!strict
--[[
	Purchase — upgrade buying rules, as pure functions over the profile.

	`evaluate` changes nothing and serves both the server (validation) and the client
	(greying out a button). `apply` only spends when `evaluate` agrees, so the two can
	never drift apart.
]]

local Result = require(script.Parent.Parent.Support.Result)
local Profile = require(script.Parent.Parent.Profile.Profile)

type Result = Result.Result
type Profile = Profile.Profile

local Purchase = {}

function Purchase.evaluate(catalog: any, profile: Profile, upgradeId: string): Result
	local definition = catalog:get(upgradeId)
	if not definition then
		return Result.err("UNKNOWN_UPGRADE", `Unknown upgrade: {tostring(upgradeId)}`)
	end

	local level = Profile.levelOf(profile, upgradeId)
	if catalog:isMaxed(upgradeId, level) then
		return Result.err("MAX_LEVEL", "Already at maximum level", { level = level })
	end

	local cost = catalog:costFor(upgradeId, level)
	if profile.coins < cost then
		return Result.err("INSUFFICIENT_FUNDS", "Not enough Coins", {
			cost = cost,
			missing = cost - profile.coins,
		})
	end

	return Result.ok({ cost = cost, nextLevel = level + 1, definition = definition })
end

function Purchase.apply(catalog: any, profile: Profile, upgradeId: string): Result
	local evaluation = Purchase.evaluate(catalog, profile, upgradeId)
	if not evaluation.ok then
		return evaluation
	end

	local cost = evaluation.value.cost
	profile.coins -= cost
	profile.upgrades[upgradeId] = evaluation.value.nextLevel

	return Result.ok({
		cost = cost,
		level = evaluation.value.nextLevel,
		definition = evaluation.value.definition,
	})
end

--[[ Simulates a bulk purchase without touching the profile: how many levels are affordable. ]]
function Purchase.planBulk(catalog: any, profile: Profile, upgradeId: string, maxLevels: number)
	local plan = { affordableLevels = 0, totalCost = 0, nextCost = nil :: number? }
	if not catalog:get(upgradeId) then
		return plan
	end

	local level = Profile.levelOf(profile, upgradeId)
	local budget = profile.coins

	for _ = 1, math.max(maxLevels, 0) do
		if catalog:isMaxed(upgradeId, level) then
			break
		end
		local cost = catalog:costFor(upgradeId, level)
		if cost > budget then
			plan.nextCost = cost
			break
		end
		budget -= cost
		level += 1
		plan.affordableLevels += 1
		plan.totalCost += cost
	end

	return plan
end

return Purchase
