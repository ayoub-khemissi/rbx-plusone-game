--!strict
--[[
	PrestigePolicy — the long loop: reset everything to come back stronger.

	Speed, Coins and upgrades go back to zero in exchange for a permanent multiplier
	on every future gain. The requirement grows geometrically, so each prestige is a
	real decision rather than a formality.

	It is a loop INSIDE a world, not the end of one, and NOTHING about it restarts.
	Rebirths, the requirement and the multiplier all run in one continuous ladder
	across the whole game; a world is simply a stretch of it, entered once enough
	have been taken.

	Both the requirement and the multiplier compound. The requirement climbs a
	little faster, so a rebirth slowly becomes a bigger decision — but only a
	little, because a gap that widens quickly turns a long loop into a wall.

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
	-- Compounded per rebirth, like the requirement. See multiplierFor.
	multiplierGrowth: number,
	-- How many rebirths open the next world. Nothing about the ladder restarts.
	rebirthsPerWorld: number?,
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

	One continuous ladder for the whole game: no world resets it, and no world is a
	special case of it. Worlds are read off the same climb.
]]
function PrestigePolicy.requirementFor(self: PrestigePolicy, prestiges: number): number
	local taken = math.max(math.floor(prestiges or 0), 0)
	return math.floor(self.tuning.baseRequirement * self.tuning.requirementGrowth ^ taken)
end

--[[
	The permanent multiplier a given number of rebirths is worth.

	It COMPOUNDS rather than adding. Adding makes each rebirth worth less than the
	last while the requirement keeps multiplying, so the loop grinds to a halt after
	a dozen; compounding keeps the two in the same units and lets the ladder run for
	as long as anyone wants to climb it.
]]
function PrestigePolicy.multiplierFor(self: PrestigePolicy, prestiges: number): number
	return self.tuning.multiplierGrowth ^ math.max(math.floor(prestiges or 0), 0)
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

	--[[
		The high-water mark survives a rebirth — that is the whole point of it — but
		NOT a change of world. A world the player has never seen must cost what it
		costs; carrying the mark across would hand them a discount on ground they
		have not covered.
	]]
	local perWorld = self.tuning.rebirthsPerWorld
	if perWorld and perWorld > 0 and profile.prestiges % perWorld == 0 then
		profile.bestLevel = 0
	end

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
