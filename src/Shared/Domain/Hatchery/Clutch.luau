--!strict
--[[
	Clutch — the hatchery: eggs incubating in a limited number of slots.

	Incubation is stored as an ABSOLUTE ready time, so it keeps running while the
	player is offline. That is the whole point: the wait is a reason to come back
	tomorrow, not a reason to leave a character standing on a pad.

	Staying at the Nest speeds incubation up (`perch`) without ever punishing absence:
	the player who logs off still makes progress, the one who stays makes it faster,
	and the servers stay populated.
]]

local Result = require(script.Parent.Parent.Support.Result)
local Profile = require(script.Parent.Parent.Profile.Profile)

type Result = Result.Result

export type Tuning = {
	slots: number,
	durations: { [string]: number },
	perchMultiplier: number,
}

export type Status = {
	index: number,
	rarity: string,
	remaining: number,
	ready: boolean,
}

local Clutch = {}
Clutch.__index = Clutch

export type Clutch = typeof(setmetatable({} :: Tuning, Clutch))

local DEFAULT_DURATION = 300

function Clutch.new(tuning: Tuning): Clutch
	return setmetatable({
		slots = tuning.slots,
		durations = tuning.durations,
		perchMultiplier = tuning.perchMultiplier,
	}, Clutch)
end

function Clutch.durationFor(self: Clutch, rarity: string): number
	return self.durations[rarity] or DEFAULT_DURATION
end

function Clutch.capacity(self: Clutch, extraSlots: number?): number
	return self.slots + math.max(extraSlots or 0, 0)
end

function Clutch.freeSlots(self: Clutch, profile: any, extraSlots: number?): number
	return math.max(self:capacity(extraSlots) - #profile.hatchery, 0)
end

--[[ Moves one egg from the stock into a free slot. ]]
function Clutch.place(self: Clutch, profile: any, rarity: string, now: number, extraSlots: number?): Result
	if Profile.eggsOf(profile, rarity) < 1 then
		return Result.err("NO_EGG", "No egg of this rarity in stock")
	end
	if self:freeSlots(profile, extraSlots) < 1 then
		return Result.err("NO_SLOT", "Every hatchery slot is busy")
	end

	profile.eggs[rarity] -= 1
	table.insert(profile.hatchery, {
		rarity = rarity,
		readyAt = now + self:durationFor(rarity),
	})

	return Result.ok({ rarity = rarity, index = #profile.hatchery })
end

function Clutch.statusFor(_self: Clutch, profile: any, now: number): { Status }
	local statuses = {}

	for index, egg in profile.hatchery do
		local remaining = math.max((egg.readyAt or 0) - now, 0)
		table.insert(statuses, {
			index = index,
			rarity = egg.rarity,
			remaining = remaining,
			ready = remaining <= 0,
		})
	end

	return statuses
end

function Clutch.readyCount(self: Clutch, profile: any, now: number): number
	local count = 0
	for _, status in self:statusFor(profile, now) do
		if status.ready then
			count += 1
		end
	end
	return count
end

function Clutch.collect(_self: Clutch, profile: any, index: any, now: number): Result
	if typeof(index) ~= "number" then
		return Result.err("NO_EGG", "Invalid slot")
	end

	local egg = profile.hatchery[index]
	if not egg then
		return Result.err("NO_EGG", "No egg in this slot")
	end
	if (egg.readyAt or 0) > now then
		return Result.err("NOT_READY", "This egg is still warm", {
			remaining = egg.readyAt - now,
		})
	end

	table.remove(profile.hatchery, index)
	profile.totals.eggsHatched += 1

	return Result.ok({ rarity = egg.rarity })
end

--[[ Perched at the Nest: incubation advances faster than real time. ]]
function Clutch.perch(self: Clutch, profile: any, seconds: number)
	if typeof(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 then
		return
	end

	local bonus = seconds * math.max(self.perchMultiplier - 1, 0)
	for _, egg in profile.hatchery do
		egg.readyAt = math.max((egg.readyAt or 0) - bonus, 0)
	end
end

return Clutch
