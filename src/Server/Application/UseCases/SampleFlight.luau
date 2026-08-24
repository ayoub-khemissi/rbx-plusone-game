--!strict
--[[
	SampleFlight — the heart of the loop, called by the server sampling loop.

	The server measures the dragon itself: the client never declares a gain, so it
	cannot invent one. Speed lands in the profile immediately, gold lands in the
	pouch and stays at risk.

	This is also where the wind barrier is enforced. Client-side the barrier is just
	a visual, so a tampered client could fly through it — the server pushes them back
	to the deepest tier their speed actually earns.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Pouch = require(Shared.Domain.Run.Pouch)
local Format = require(Shared.Domain.Support.Format)

local SampleFlight = {}
SampleFlight.__index = SampleFlight

local PUSH_BACK_MARGIN = 40

function SampleFlight.new(dependencies)
	return setmetatable(table.clone(dependencies), SampleFlight)
end

function SampleFlight._pushBack(self, player, session, blockedTierId)
	local fallback = self.ladder:highestUnlocked(session.profile.speed)
	local bounds = self.layout:boundsOf(fallback)
	local blocked = self.ladder:get(blockedTierId)

	self.teleporter:sendTo(player, {
		x = bounds.endX - PUSH_BACK_MARGIN,
		y = bounds.altitude,
		z = 0,
	})
	self.notifier:notify(
		player,
		`{Format.abbreviate(blocked and blocked.requiredSpeed or 0)} speed needed to pass into {blocked and blocked.name or "this tier"}.`,
		"warning"
	)

	-- The teleport itself must never be credited as flown distance.
	session.lastPosition = nil
	session.lastSampleAt = nil
end

function SampleFlight.run(self, player, sample)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	if not session.flying then
		return Result.ok({ idle = true })
	end

	local position = sample.position
	local at = sample.at

	if not session.lastPosition or not session.lastSampleAt then
		session.lastPosition = position
		session.lastSampleAt = at
		return Result.ok({ warmup = true, steps = 0, speedGained = 0, goldGained = 0 })
	end

	local tierId = self.layout:tierAt(position.x)
	if tierId and not self.ladder:isUnlocked(tierId, session.profile.speed) then
		self:_pushBack(player, session, tierId)
		return Result.err("BARRIER_BLOCKED", "Not fast enough for this barrier", { tierId = tierId })
	end

	local distance = self.progression:distanceBetween(session.lastPosition, position)
	local deltaTime = at - session.lastSampleAt
	session.lastPosition = position
	session.lastSampleAt = at

	local profile = session.profile
	local outcome = self.progression:advance(profile, session.pouch, {
		distance = distance,
		deltaTime = deltaTime,
		currentVelocity = sample.velocity,
		passes = session.passes,
		boosts = self.boosts:multipliersFor(profile, self.clock.now()),
		dragons = self.dragons:bonusesFor(profile),
	})

	if tierId then
		local tier = self.ladder:get(tierId)
		if tier and Pouch.reachTier(session.pouch, tier) then
			session.tierId = tierId
			self.notifier:notify(player, `Tier {tierId} — {tier.name}`, "info")
		end
	end

	self.actuator:apply(player, outcome.flight)
	self.publisher:publish(player, self.snapshots:build(session))

	return Result.ok(outcome)
end

return SampleFlight
