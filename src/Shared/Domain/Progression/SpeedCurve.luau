--!strict
--[[
	SpeedCurve — traduit les points de vitesse accumules en vitesse de deplacement reelle.

	Le moteur physique de Roblox devient instable au-dela de ~250 studs/s : la courbe
	est donc une exponentielle inverse, strictement croissante mais bornee. Le joueur
	continue de voir son compteur exploser tout en restant jouable.

		walkSpeed(s) = base + bonusMax * (1 - e^(-s / softness))
]]

export type Tuning = {
	baseWalkSpeed: number,
	maxBonusWalkSpeed: number,
	softness: number,
	baseJumpPower: number,
	jumpPowerPerLevel: number,
	maxJumpPower: number,
}

local SpeedCurve = {}
SpeedCurve.__index = SpeedCurve

export type SpeedCurve = typeof(setmetatable({} :: { tuning: Tuning }, SpeedCurve))

local function sanitize(value: number): number
	if typeof(value) ~= "number" or value ~= value or value < 0 then
		return 0
	end
	return value
end

function SpeedCurve.new(tuning: Tuning): SpeedCurve
	return setmetatable({ tuning = tuning }, SpeedCurve)
end

--[[ Part de la course vers le plafond, dans [0, 1]. ]]
function SpeedCurve.saturationFor(self: SpeedCurve, speed: number): number
	return 1 - math.exp(-sanitize(speed) / self.tuning.softness)
end

function SpeedCurve.walkSpeedFor(self: SpeedCurve, speed: number): number
	return self.tuning.baseWalkSpeed + self.tuning.maxBonusWalkSpeed * self:saturationFor(speed)
end

function SpeedCurve.jumpPowerFor(self: SpeedCurve, jumpLevel: number): number
	local level = sanitize(jumpLevel)
	return math.min(
		self.tuning.baseJumpPower + level * self.tuning.jumpPowerPerLevel,
		self.tuning.maxJumpPower
	)
end

return SpeedCurve
