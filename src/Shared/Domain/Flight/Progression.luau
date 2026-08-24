--!strict
--[[
	Progression — the domain service that composes the flight loop:

		measured displacement -> credited steps -> speed & gold -> flight state

	The split between the two destinations IS the game:

	  - SPEED goes to the profile, immediately and permanently. That is the safety net
	    of the push-your-luck loop: a flight that ends against a wall still made the
	    dragon faster.
	  - GOLD goes to the pouch, where it stays at risk until it is banked at an Altar.

	It knows nothing about the network, Roblox, or persistence.
]]

local FlightAccounting = require(script.Parent.FlightAccounting)
local Pouch = require(script.Parent.Parent.Run.Pouch)
local Profile = require(script.Parent.Parent.Profile.Profile)

type Profile = Profile.Profile
type Reading = FlightAccounting.Reading

export type Tuning = {
	speedPerStep: number,
	goldPerStep: number,
}

export type Context = {
	distance: number,
	deltaTime: number,
	currentVelocity: number,
	tier: any?,
	passes: { [string]: boolean }?,
	boosts: { speed: number?, gold: number? }?,
	dragons: { [string]: number }?,
}

export type FlightState = {
	velocity: number,
	agility: number,
	magnet: number,
	saturation: number,
}

export type Outcome = {
	steps: number,
	speedGained: number,
	goldGained: number,
	clamped: boolean,
	flight: FlightState,
	multipliers: any,
}

local Progression = {}
Progression.__index = Progression

export type Dependencies = {
	curve: any,
	accounting: any,
	multipliers: any,
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
		tier = context.tier,
		passes = context.passes,
		boosts = context.boosts,
		dragons = context.dragons,
	}
end

--[[ Flight state to apply to the dragon for the current profile. ]]
function Progression.flightFor(self: Progression, profile: Profile, bonuses: any): FlightState
	return {
		velocity = self.curve:velocityFor(profile.speed),
		agility = self.curve:agilityFor(bonuses.flat.agility or 0),
		magnet = bonuses.flat.magnet or 0,
		saturation = self.curve:saturationFor(profile.speed),
	}
end

--[[ Credits one sampling interval of flight. ]]
function Progression.advance(self: Progression, profile: Profile, pouch: any, context: Context): Outcome
	local reading: Reading =
		self.accounting:measure(context.distance, context.deltaTime, context.currentVelocity)
	local bonuses = self.multipliers:compute(profile, bonusContext(context))

	local speedGained = reading.steps * self.tuning.speedPerStep * bonuses.speed
	local goldGained = reading.steps * self.tuning.goldPerStep * bonuses.gold

	profile.speed += speedGained
	profile.totals.distance += reading.distance
	profile.totals.playtime += math.max(context.deltaTime, 0)

	Pouch.addGold(pouch, goldGained)

	return {
		steps = reading.steps,
		speedGained = speedGained,
		goldGained = goldGained,
		clamped = reading.clamped,
		flight = self:flightFor(profile, bonuses),
		multipliers = bonuses,
	}
end

--[[ A ring picked up mid-flight: gold goes to the pouch, still at risk. ]]
function Progression.collectRing(
	self: Progression,
	profile: Profile,
	pouch: any,
	value: number,
	context: Context?
): number
	local bonuses = self.multipliers:compute(profile, bonusContext(context or ({} :: any)))
	local granted = math.max(value, 0) * bonuses.gold

	Pouch.addGold(pouch, granted)
	return granted
end

return Progression
