--!strict
--[[
	CrashFlight — a wall. Everything not banked is gone.

	Two paid safety nets soften it, in this order:
	  - a phoenix feather forgives the wall entirely and the flight continues;
	  - flight insurance refunds part of the pouch once the flight is over.

	Speed earned during the flight is never taken back. That floor is what keeps a
	string of deaths from feeling like a wasted evening — and what makes the gamble
	acceptable in the first place.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Pouch = require(Shared.Domain.Run.Pouch)
local Format = require(Shared.Domain.Support.Format)

local CrashFlight = {}
CrashFlight.__index = CrashFlight

function CrashFlight.new(dependencies)
	return setmetatable(table.clone(dependencies), CrashFlight)
end

function CrashFlight.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	if not session.flying or not session.pouch then
		return Result.err("NOT_FLYING", "No flight to end")
	end

	local profile = session.profile
	profile.totals.walls += 1

	if session.feathers > 0 then
		session.feathers -= 1
		self.publisher:publish(player, self.snapshots:build(session))
		self.notifier:notify(player, "🪶 A phoenix feather burns — your pouch is safe.", "success")
		return Result.ok({ saved = true })
	end

	local options = if session.insured
		then { insuranceRatio = self.insuranceRatio, profile = profile }
		else nil
	local lost = Pouch.drop(session.pouch, options)

	self.sessions:endFlight(session)

	-- The moment of regret is exactly when the insurance offer means something.
	self.offers:trigger(profile, "pouchLost", self.clock.now())

	self.teleporter:sendTo(player, self.nestPoint)
	self.publisher:publish(player, self.snapshots:build(session))

	if lost.rescuedGold then
		self.notifier:notify(
			player,
			`🛡️ Insurance saved {Format.abbreviate(lost.rescuedGold)} gold from the wreck.`,
			"warning"
		)
	else
		self.notifier:notify(
			player,
			`💥 Lost {Format.abbreviate(lost.gold)} gold and {lost.eggs} eggs.`,
			"error"
		)
	end

	self.save:run(session.userId)

	return Result.ok({ saved = false, lost = lost })
end

return CrashFlight
