--!strict
--[[
	Progression — service de domaine qui compose la boucle de jeu principale :

		deplacement mesure -> pas credites -> vitesse & bananes -> etat de mouvement

	Il ne connait ni le reseau, ni Roblox, ni la persistance : la couche Application
	lui fournit un contexte et applique le resultat via les ports.
]]

local MovementAccounting = require(script.Parent.MovementAccounting)
local Profile = require(script.Parent.Parent.Profile.Profile)

type Profile = Profile.Profile
type Reading = MovementAccounting.Reading

export type Tuning = {
	speedPerStep: number,
	bananasPerStep: number,
}

export type Context = {
	distance: number,
	deltaTime: number,
	currentWalkSpeed: number,
	zone: { stepMultiplier: number?, bananaMultiplier: number? }?,
	passes: { [string]: boolean }?,
}

export type Movement = {
	walkSpeed: number,
	jumpPower: number,
	wallGrip: number,
	airDash: number,
	saturation: number,
}

export type Outcome = {
	steps: number,
	speedGained: number,
	bananasGained: number,
	clamped: boolean,
	movement: Movement,
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
	return setmetatable(dependencies, Progression)
end

--[[ Etat de mouvement a appliquer au personnage pour le profil courant. ]]
function Progression.movementFor(self: Progression, profile: Profile, bonuses: any): Movement
	return {
		walkSpeed = self.curve:walkSpeedFor(profile.speed),
		jumpPower = self.curve:jumpPowerFor(bonuses.flat.jumpPower or 0),
		wallGrip = bonuses.flat.wallGrip or 0,
		airDash = bonuses.flat.airDash or 0,
		saturation = self.curve:saturationFor(profile.speed),
	}
end

--[[ Credite un intervalle de deplacement et renvoie ce qui doit etre applique / affiche. ]]
function Progression.advance(self: Progression, profile: Profile, context: Context): Outcome
	local reading: Reading =
		self.accounting:measure(context.distance, context.deltaTime, context.currentWalkSpeed)
	local bonuses = self.multipliers:compute(profile, { zone = context.zone, passes = context.passes })

	local speedGained = reading.steps * self.tuning.speedPerStep * bonuses.speed
	local bananasGained = reading.steps * self.tuning.bananasPerStep * bonuses.bananas

	profile.speed += speedGained
	profile.bananas += bananasGained
	profile.totals.steps += reading.steps
	profile.totals.distance += reading.distance
	profile.totals.bananasCollected += bananasGained
	profile.totals.playtime += math.max(context.deltaTime, 0)

	return {
		steps = reading.steps,
		speedGained = speedGained,
		bananasGained = bananasGained,
		clamped = reading.clamped,
		movement = self:movementFor(profile, bonuses),
		multipliers = bonuses,
	}
end

--[[ Credite des bananes hors deplacement (collectibles, recompenses). ]]
function Progression.grantBananas(
	self: Progression,
	profile: Profile,
	amount: number,
	context: Context?
): number
	local bonuses = self.multipliers:compute(profile, {
		zone = context and context.zone,
		passes = context and context.passes,
	})
	local granted = math.max(amount, 0) * bonuses.bananas
	profile.bananas += granted
	profile.totals.bananasCollected += granted
	return granted
end

--[[ Memorise la zone la plus avancee jamais atteinte. ]]
function Progression.noteZone(_self: Progression, profile: Profile, zoneId: number): boolean
	if zoneId > profile.highestZone then
		profile.highestZone = zoneId
		return true
	end
	return false
end

return Progression
