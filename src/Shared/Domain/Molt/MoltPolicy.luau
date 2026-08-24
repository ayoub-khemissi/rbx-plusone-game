--!strict
--[[
	MoltPolicy — the long loop: shedding the old skin to come back stronger.

	Reaching the last tier lets the dragon molt: speed, gold and upgrades reset, in
	exchange for a permanent multiplier on every gain, a harsher sky and a new scale
	colour visible to other players.

	The requirement grows geometrically, so each molt is a real decision rather than a
	formality.
]]

local Result = require(script.Parent.Parent.Support.Result)
local Profile = require(script.Parent.Parent.Profile.Profile)

type Result = Result.Result
type Profile = Profile.Profile

export type Tuning = {
	baseRequirement: number,
	requirementGrowth: number,
	multiplierPerMolt: number,
	resetsUpgrades: boolean,
	keptGoldRatio: number?,
}

local MoltPolicy = {}
MoltPolicy.__index = MoltPolicy

export type MoltPolicy = typeof(setmetatable({} :: { tuning: Tuning }, MoltPolicy))

function MoltPolicy.new(tuning: Tuning): MoltPolicy
	return setmetatable({ tuning = tuning }, MoltPolicy)
end

--[[ Speed needed to go from `molts` to `molts + 1`. ]]
function MoltPolicy.requirementFor(self: MoltPolicy, molts: number): number
	return math.floor(self.tuning.baseRequirement * self.tuning.requirementGrowth ^ math.max(molts, 0))
end

function MoltPolicy.multiplierFor(self: MoltPolicy, molts: number): number
	return 1 + math.max(molts, 0) * self.tuning.multiplierPerMolt
end

function MoltPolicy.progressFor(self: MoltPolicy, profile: Profile): number
	local required = self:requirementFor(profile.molts)
	if required <= 0 then
		return 1
	end
	return math.clamp(profile.speed / required, 0, 1)
end

function MoltPolicy.evaluate(self: MoltPolicy, profile: Profile): Result
	local required = self:requirementFor(profile.molts)
	if profile.speed < required then
		return Result.err("SPEED_TOO_LOW", "Not fast enough to molt yet", {
			required = required,
			missing = required - profile.speed,
		})
	end

	return Result.ok({
		required = required,
		nextMolts = profile.molts + 1,
		nextMultiplier = self:multiplierFor(profile.molts + 1),
	})
end

--[[ Consumes the current run of progress and grows the permanent multiplier. ]]
function MoltPolicy.apply(self: MoltPolicy, profile: Profile): Result
	local evaluation = self:evaluate(profile)
	if not evaluation.ok then
		return evaluation
	end

	profile.speed = 0
	profile.gold = math.floor(profile.gold * (self.tuning.keptGoldRatio or 0))
	profile.deepestTier = 0
	profile.molts += 1
	profile.totals.molts += 1

	if self.tuning.resetsUpgrades then
		profile.upgrades = {}
	end

	return Result.ok({
		molts = profile.molts,
		multiplier = self:multiplierFor(profile.molts),
		nextRequirement = self:requirementFor(profile.molts),
	})
end

return MoltPolicy
