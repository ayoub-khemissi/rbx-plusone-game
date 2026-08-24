--!strict
--[[
	BoostStack — timed boosts (x2 speed for 20 minutes, server party...).

	Two properties matter to the business model:
	  1. boosts are PERSISTED in the profile, so a player who buys then disconnects
	     does not lose what they paid for — trust is what makes them buy again;
	  2. buying the same boost again ADDS to its duration, up to a cap, which rewards
	     repeat purchases without breaking the balance.
]]

export type Definition = {
	name: string?,
	icon: string?,
	speed: number?,
	gold: number?,
}

export type Tuning = {
	definitions: { [string]: Definition },
	maxStackedDuration: number,
}

export type ActiveBoost = {
	id: string,
	name: string,
	icon: string?,
	remaining: number,
	speed: number,
	gold: number,
}

local BoostStack = {}
BoostStack.__index = BoostStack

export type BoostStack = typeof(setmetatable({} :: Tuning, BoostStack))

function BoostStack.new(tuning: Tuning): BoostStack
	return setmetatable({
		definitions = tuning.definitions,
		maxStackedDuration = tuning.maxStackedDuration,
	}, BoostStack)
end

function BoostStack.definitionOf(self: BoostStack, boostId: string): Definition?
	return self.definitions[boostId]
end

function BoostStack.remainingFor(_self: BoostStack, profile: any, boostId: string, now: number): number
	local expiresAt = profile.boosts[boostId]
	if not expiresAt then
		return 0
	end
	return math.max(expiresAt - now, 0)
end

function BoostStack.isActive(self: BoostStack, profile: any, boostId: string, now: number): boolean
	return self:remainingFor(profile, boostId, now) > 0
end

--[[ Adds time to a boost. Returns false when the boost does not exist. ]]
function BoostStack.grant(
	self: BoostStack,
	profile: any,
	boostId: string,
	duration: number,
	now: number
): boolean
	if not self.definitions[boostId] or typeof(duration) ~= "number" or duration <= 0 then
		return false
	end

	local remaining = self:remainingFor(profile, boostId, now)
	local total = math.min(remaining + duration, self.maxStackedDuration)
	profile.boosts[boostId] = now + total
	return true
end

--[[ Drops expired boosts from the profile so the save stays small. ]]
function BoostStack.prune(_self: BoostStack, profile: any, now: number)
	for boostId, expiresAt in profile.boosts do
		if expiresAt <= now then
			profile.boosts[boostId] = nil
		end
	end
end

function BoostStack.activeFor(self: BoostStack, profile: any, now: number): { ActiveBoost }
	local active: { ActiveBoost } = {}

	for boostId, expiresAt in profile.boosts do
		local definition = self.definitions[boostId]
		if definition and expiresAt > now then
			table.insert(active, {
				id = boostId,
				name = definition.name or boostId,
				icon = definition.icon,
				remaining = expiresAt - now,
				speed = definition.speed or 1,
				gold = definition.gold or 1,
			})
		end
	end

	table.sort(active, function(left, right)
		return left.id < right.id
	end)

	return active
end

--[[ Combined multipliers of every active boost (they multiply with each other). ]]
function BoostStack.multipliersFor(
	self: BoostStack,
	profile: any,
	now: number
): { speed: number, gold: number }
	local speed, gold = 1, 1

	for _, boost in self:activeFor(profile, now) do
		speed *= boost.speed
		gold *= boost.gold
	end

	return { speed = speed, gold = gold }
end

return BoostStack
