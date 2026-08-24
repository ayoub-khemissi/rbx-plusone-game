--!strict
--[[
	StartFlight — leaves the Nest and opens a fresh pouch.

	Everything at stake for this flight is decided here: the feathers armed by the
	gamepass, and whether one of the paid insured flights is spent. Consuming the
	insurance at take-off rather than at the crash is deliberate — the player knows
	what they are flying with.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Pouch = require(Shared.Domain.Run.Pouch)

local StartFlight = {}
StartFlight.__index = StartFlight

function StartFlight.new(dependencies)
	return setmetatable(table.clone(dependencies), StartFlight)
end

function StartFlight.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	if session.flying then
		return Result.err("ALREADY_FLYING", "A flight is already under way")
	end

	local profile = session.profile
	local bonuses = self.multipliers:compute(profile, {
		passes = session.passes,
		boosts = self.boosts:multipliersFor(profile, self.clock.now()),
		dragons = self.dragons:bonusesFor(profile),
	})

	session.flying = true
	session.pouch = Pouch.new()
	session.tierId = 0
	session.lastPosition = nil
	session.lastSampleAt = nil
	session.feathers = math.floor(bonuses.flat.feathers or 0)

	session.insured = profile.insuredFlights > 0
	if session.insured then
		profile.insuredFlights -= 1
	end

	profile.totals.flights += 1

	self.teleporter:sendTo(player, self.layout:launchPoint())
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok(session)
end

return StartFlight
