--!strict
--[[
	PrestigePolicy — the long loop: reset everything to come back stronger.

	Speed, Coins and upgrades go back to zero in exchange for a permanent multiplier
	on every future gain. The requirement grows geometrically, so each prestige is a
	real decision rather than a formality.

	It is a loop INSIDE a world, not the end of one: several of them open the next
	world, and the requirement restarts there rather than compounding forever.

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
	-- How many rebirths a world is made of. The requirement restarts at each one.
	rebirthsPerWorld: number?,
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

--[[
	Experience needed to go from `prestiges` to `prestiges + 1`.

	The growth applies WITHIN a world: the count restarts at each new one, and the
	world's `scale` carries the whole ladder up. Compounding across every rebirth
	ever taken would put the thirty-fifth out of reach by a factor of millions,
	which is not a long loop but a wall.
]]
function PrestigePolicy.requirementFor(self: PrestigePolicy, prestiges: number, scale: number?): number
	local taken = math.max(math.floor(prestiges or 0), 0)
	local perWorld = self.tuning.rebirthsPerWorld
	local cycle = if perWorld and perWorld > 0 then taken % perWorld else taken

	return math.floor(self.tuning.baseRequirement * (scale or 1) * self.tuning.requirementGrowth ^ cycle)
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
