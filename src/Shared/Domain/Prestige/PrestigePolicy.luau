--!strict
--[[
	PrestigePolicy — the long loop: reset everything to come back stronger.

	Speed, Coins and upgrades go back to zero in exchange for a permanent multiplier
	on every future gain. The requirement grows geometrically, so each prestige is a
	real decision rather than a formality.

	Named after the mechanic, never after a theme: a theme may display it as Rebirth,
	Ascension or anything else, but the code only knows Prestige.
]]

local Result = require(script.Parent.Parent.Support.Result)
local Profile = require(script.Parent.Parent.Profile.Profile)

type Result = Result.Result
type Profile = Profile.Profile

export type Tuning = {
	baseRequirement: number,
	requirementGrowth: number,
	multiplierPerPrestige: number,
	resetsUpgrades: boolean,
	keptCoinRatio: number?,
}

local PrestigePolicy = {}
PrestigePolicy.__index = PrestigePolicy

export type PrestigePolicy = typeof(setmetatable({} :: { tuning: Tuning }, PrestigePolicy))

function PrestigePolicy.new(tuning: Tuning): PrestigePolicy
	return setmetatable({ tuning = tuning }, PrestigePolicy)
end

--[[ Speed needed to go from `prestiges` to `prestiges + 1`. ]]
function PrestigePolicy.requirementFor(self: PrestigePolicy, prestiges: number): number
	return math.floor(self.tuning.baseRequirement * self.tuning.requirementGrowth ^ math.max(prestiges, 0))
end

function PrestigePolicy.multiplierFor(self: PrestigePolicy, prestiges: number): number
	return 1 + math.max(prestiges, 0) * self.tuning.multiplierPerPrestige
end

function PrestigePolicy.progressFor(self: PrestigePolicy, profile: Profile): number
	local required = self:requirementFor(profile.prestiges)
	if required <= 0 then
		return 1
	end
	return math.clamp(profile.speed / required, 0, 1)
end

function PrestigePolicy.evaluate(self: PrestigePolicy, profile: Profile): Result
	local required = self:requirementFor(profile.prestiges)
	if profile.speed < required then
		return Result.err("SPEED_TOO_LOW", "Not fast enough to prestige yet", {
			required = required,
			missing = required - profile.speed,
		})
	end

	return Result.ok({
		required = required,
		nextPrestiges = profile.prestiges + 1,
		nextMultiplier = self:multiplierFor(profile.prestiges + 1),
	})
end

--[[ Consumes the current run of progress and grows the permanent multiplier. ]]
function PrestigePolicy.apply(self: PrestigePolicy, profile: Profile): Result
	local evaluation = self:evaluate(profile)
	if not evaluation.ok then
		return evaluation
	end

	profile.speed = 0
	profile.coins = math.floor(profile.coins * (self.tuning.keptCoinRatio or 0))
	profile.highestStage = 0
	profile.prestiges += 1
	profile.totals.prestiges += 1

	if self.tuning.resetsUpgrades then
		profile.upgrades = {}
	end

	return Result.ok({
		prestiges = profile.prestiges,
		multiplier = self:multiplierFor(profile.prestiges),
		nextRequirement = self:requirementFor(profile.prestiges),
	})
end

return PrestigePolicy
