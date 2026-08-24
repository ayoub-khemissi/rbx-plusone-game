--!strict
--[[
	Snapshot — a read-only view of a player's state, meant for the client.

	This is a PRESENTATION MODEL: the client never sees the Profile entity, it reads
	this stable contract. Changing the shape of the save therefore does not ripple
	into the interface, and the reverse holds too.
]]

local Shared = require(script.Parent.Parent.Shared)
local Pouch = require(Shared.Domain.Run.Pouch)

local SessionRegistry = require(script.Parent.SessionRegistry)

type Session = SessionRegistry.Session

local Snapshot = {}
Snapshot.__index = Snapshot

export type Dependencies = {
	ladder: any,
	progression: any,
	multipliers: any,
	moltPolicy: any,
	boosts: any,
	clutch: any,
	dragons: any,
	clock: any,
}

export type SnapshotFactory = typeof(setmetatable({} :: Dependencies, Snapshot))

function Snapshot.new(dependencies: Dependencies): SnapshotFactory
	return setmetatable(table.clone(dependencies), Snapshot)
end

function Snapshot.build(self: SnapshotFactory, session: Session)
	local profile = session.profile
	local now = self.clock.now()

	local boostBonuses = self.boosts:multipliersFor(profile, now)
	local dragonBonuses = self.dragons:bonusesFor(profile)
	local bonuses = self.multipliers:compute(profile, {
		passes = session.passes,
		boosts = boostBonuses,
		dragons = dragonBonuses,
	})
	local flight = self.progression:flightFor(profile, bonuses)

	local reachedTier = self.ladder:highestUnlocked(profile.speed)
	local nextTier = self.ladder:nextOf(reachedTier)
	local pouch = if session.pouch then Pouch.preview(session.pouch) else nil

	return {
		-- Permanent progression
		speed = profile.speed,
		gold = profile.gold,
		molts = profile.molts,
		deepestTier = profile.deepestTier,
		reachedTier = reachedTier,
		upgrades = table.clone(profile.upgrades),
		passes = table.clone(session.passes),

		-- Current flight
		flying = session.flying,
		tierId = session.tierId,
		feathers = session.feathers,
		insured = session.insured,
		insuredFlights = profile.insuredFlights,
		pouchGold = if pouch then pouch.gold else 0,
		pouchEggs = if pouch then pouch.eggs else 0,
		pouchTier = if pouch then pouch.tierId else 0,

		-- Flight state
		velocity = flight.velocity,
		agility = flight.agility,
		magnet = flight.magnet,
		saturation = flight.saturation,

		-- Multipliers
		speedMultiplier = bonuses.speed,
		goldMultiplier = bonuses.gold,
		boostSpeed = boostBonuses.speed,
		boostGold = boostBonuses.gold,
		activeBoosts = self.boosts:activeFor(profile, now),

		-- Molt
		moltMultiplier = self.moltPolicy:multiplierFor(profile.molts),
		moltRequirement = self.moltPolicy:requirementFor(profile.molts),
		moltProgress = self.moltPolicy:progressFor(profile),

		-- Next barrier
		tierProgress = self.ladder:progressToNext(reachedTier, profile.speed),
		nextTierRequirement = nextTier and nextTier.requiredSpeed,

		-- Nest
		eggs = table.clone(profile.eggs),
		hatchery = self.clutch:statusFor(profile, now),
		dragons = table.clone(profile.dragons),
		collection = self.dragons:completion(profile),
	}
end

return Snapshot
