--!strict
--[[
	RebirthPolicy — regles de la renaissance : seuil, bonus permanent, remise a zero.

	Toute la boucle "long terme" du jeu tient dans ce module : plus le joueur renait,
	plus le seuil monte (croissance geometrique) et plus ses gains sont multiplies.
]]

local Result = require(script.Parent.Parent.Support.Result)
local Profile = require(script.Parent.Parent.Profile.Profile)

type Result = Result.Result
type Profile = Profile.Profile

export type Tuning = {
	baseRequirement: number,
	requirementGrowth: number,
	multiplierPerRebirth: number,
	resetsUpgrades: boolean,
	keptBananaRatio: number?,
}

local RebirthPolicy = {}
RebirthPolicy.__index = RebirthPolicy

export type RebirthPolicy = typeof(setmetatable({} :: { tuning: Tuning }, RebirthPolicy))

function RebirthPolicy.new(tuning: Tuning): RebirthPolicy
	return setmetatable({ tuning = tuning }, RebirthPolicy)
end

--[[ Vitesse necessaire pour passer de `rebirths` a `rebirths + 1`. ]]
function RebirthPolicy.requirementFor(self: RebirthPolicy, rebirths: number): number
	return math.floor(self.tuning.baseRequirement * self.tuning.requirementGrowth ^ math.max(rebirths, 0))
end

function RebirthPolicy.multiplierFor(self: RebirthPolicy, rebirths: number): number
	return 1 + math.max(rebirths, 0) * self.tuning.multiplierPerRebirth
end

function RebirthPolicy.progressFor(self: RebirthPolicy, profile: Profile): number
	local required = self:requirementFor(profile.rebirths)
	if required <= 0 then
		return 1
	end
	return math.clamp(profile.speed / required, 0, 1)
end

function RebirthPolicy.evaluate(self: RebirthPolicy, profile: Profile): Result
	local required = self:requirementFor(profile.rebirths)
	if profile.speed < required then
		return Result.err("SPEED_TOO_LOW", "Vitesse insuffisante pour renaitre", {
			required = required,
			missing = required - profile.speed,
		})
	end

	return Result.ok({
		required = required,
		nextRebirths = profile.rebirths + 1,
		nextMultiplier = self:multiplierFor(profile.rebirths + 1),
	})
end

--[[ Consomme la progression courante et incremente le compteur de renaissances. ]]
function RebirthPolicy.apply(self: RebirthPolicy, profile: Profile): Result
	local evaluation = self:evaluate(profile)
	if not evaluation.ok then
		return evaluation
	end

	profile.speed = 0
	profile.bananas = math.floor(profile.bananas * (self.tuning.keptBananaRatio or 0))
	profile.highestZone = 1
	profile.rebirths += 1
	profile.totals.rebirths += 1

	if self.tuning.resetsUpgrades then
		profile.upgrades = {}
	end

	return Result.ok({
		rebirths = profile.rebirths,
		multiplier = self:multiplierFor(profile.rebirths),
		nextRequirement = self:requirementFor(profile.rebirths),
	})
end

return RebirthPolicy
