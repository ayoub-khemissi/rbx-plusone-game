--!strict
--[[
	Progression — the domain service that composes the core loop:

		measured displacement -> credited steps -> speed & coins -> movement state

	Both gains land straight in the profile: falling into a hole costs time, never
	progress. That is the whole promise of the game — you always end a run faster than
	you started it.

	It knows nothing about the network, Roblox, or persistence.
]]

local MovementAccounting = require(script.Parent.MovementAccounting)
local Profile = require(script.Parent.Parent.Profile.Profile)

type Profile = Profile.Profile
type Reading = MovementAccounting.Reading

export type Tuning = {
	speedPerStep: number,
	coinsPerStep: number,
	-- How much faster ground already covered is re-covered. See `credit`.
	catchUp: number?,
}

export type Context = {
	distance: number,
	deltaTime: number,
	currentWalkSpeed: number,
	stage: any?,
	passes: { [string]: boolean }?,
	boosts: { speed: number?, coins: number? }?,
}

export type MovementState = {
	walkSpeed: number,
	jumpPower: number,
	jumpLevel: number,
	dashLevel: number,
	dashPower: number,
	magnet: number,
	saturation: number,
}

export type Outcome = {
	steps: number,
	speedGained: number,
	coinsGained: number,
	clamped: boolean,
	movement: MovementState,
	multipliers: any,
}

local Progression = {}
Progression.__index = Progression

export type Dependencies = {
	curve: any,
	levels: any,
	accounting: any,
	multipliers: any,
	jumpBudget: any,
	dashPolicy: any,
	tuning: Tuning,
}

export type Progression = typeof(setmetatable({} :: Dependencies, Progression))

function Progression.new(dependencies: Dependencies): Progression
	return setmetatable(table.clone(dependencies), Progression)
end

function Progression.distanceBetween(self: Progression, from: any, to: any): number
	return self.accounting:distanceBetween(from, to)
end

local function bonusContext(context: Context)
	return {
		stage = context.stage,
		passes = context.passes,
		boosts = context.boosts,
	}
end

--[[ Movement state to apply to the character for the current profile. ]]
function Progression.movementFor(self: Progression, profile: Profile, bonuses: any): MovementState
	local level = self.levels:levelFor(profile.speed)
	local walkSpeed = self.curve:walkSpeedFor(level)
	local dashPowerLevel = self.dashPolicy:powerLevelFor(bonuses)

	return {
		walkSpeed = walkSpeed,
		jumpPower = self.curve:jumpPowerFor(bonuses.flat.jumpPower or 0),
		jumpLevel = self.jumpBudget:levelFor(bonuses),
		dashUnlocked = self.dashPolicy:isUnlocked(bonuses),
		dashLevel = dashPowerLevel,
		dashMultiplier = self.dashPolicy:multiplierFor(dashPowerLevel),
		dashPower = self.dashPolicy:powerFor(dashPowerLevel, walkSpeed),
		magnet = bonuses.flat.magnet or 0,
		saturation = self.curve:saturationFor(level),
	}
end

--[[ Credits one sampling interval of running. ]]
--[[
	Credits a number of steps to the profile.

	Split out of `advance` because a treadmill has steps to pay for but no distance
	to measure: it is the server that decides how far the character ran, so there is
	nothing to check it against. Everything after the measurement is the same, and
	writing it twice is how the two would drift.
]]
--[[
	How much faster the player climbs while below the best level they ever reached.

	A rebirth takes the experience away and leaves the multiplier, and with an
	exponent near two nine tenths of a world sits in its last tenth of levels — so
	without this, most of every cycle is spent re-walking ground the player had
	already walked, at a pace they had already outgrown.

	It is paid on the GAIN and not on the price, and that distinction is the whole
	reason it exists. Discounting the price of a known level would raise the level a
	given Speed reads as, every rebirth, until "Level 700" in the first world meant
	nothing to anybody. The gain leaves the ladder exactly where it was: the player
	climbs it quickly, and it still says what it said.

	It stops the moment they pass their best. New ground is what a world is made of,
	and it costs what it costs.
]]
function Progression._catchUpFor(self: Progression, profile: Profile): number
	local best = profile.bestLevel or 0
	if best <= 0 then
		return 1
	end
	return if self.levels:levelFor(profile.speed) < best then self.tuning.catchUp or 1 else 1
end

function Progression.credit(self: Progression, profile: Profile, steps: number, bonuses: any, elapsed: number)
	local speedGained = steps * self.tuning.speedPerStep * bonuses.speed * self:_catchUpFor(profile)
	local coinsGained = steps * self.tuning.coinsPerStep * bonuses.coins

	profile.speed += speedGained
	profile.coins += coinsGained
	profile.totals.coinsEarned += coinsGained
	profile.totals.playtime += math.max(elapsed, 0)

	--[[
		The high-water mark of this world, raised here because this is the one place
		experience is ever added. It survives a rebirth, and it is what tells the
		catch-up where to stop.
	]]
	local reached = self.levels:levelFor(profile.speed)
	if reached > (profile.bestLevel or 0) then
		profile.bestLevel = reached
	end

	return { speedGained = speedGained, coinsGained = coinsGained }
end

function Progression.advance(self: Progression, profile: Profile, context: Context): Outcome
	local reading: Reading =
		self.accounting:measure(context.distance, context.deltaTime, context.currentWalkSpeed)
	local bonuses = self.multipliers:compute(profile, bonusContext(context))

	local gained = self:credit(profile, reading.steps, bonuses, context.deltaTime)
	profile.totals.distance += reading.distance

	return {
		steps = reading.steps,
		speedGained = gained.speedGained,
		coinsGained = gained.coinsGained,
		clamped = reading.clamped,
		movement = self:movementFor(profile, bonuses),
		multipliers = bonuses,
	}
end

--[[ A coin picked up on the course. ]]
function Progression.collectCoin(
	self: Progression,
	profile: Profile,
	value: number,
	context: Context?
): number
	local bonuses = self.multipliers:compute(profile, bonusContext(context or ({} :: any)))
	local granted = math.max(value, 0) * bonuses.coins

	profile.coins += granted
	profile.totals.coinsEarned += granted
	return granted
end

--[[ Remembers the deepest Stage ever reached. ]]
function Progression.noteStage(_self: Progression, profile: Profile, stageId: number): boolean
	if stageId > profile.highestStage then
		profile.highestStage = stageId
		return true
	end
	return false
end

return Progression
