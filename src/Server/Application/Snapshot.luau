--!strict
--[[
	Snapshot — a read-only view of a player's state, meant for the client.

	This is a PRESENTATION MODEL: the client never sees the Profile entity, it reads
	this stable contract. Changing the shape of the save therefore does not ripple
	into the interface, and the reverse holds too.

	It carries no themed word either: the client puts the theme labels on top.
]]

local SessionRegistry = require(script.Parent.SessionRegistry)

type Session = SessionRegistry.Session

local Snapshot = {}
Snapshot.__index = Snapshot

export type Dependencies = {
	ladder: any,
	levels: any,
	progression: any,
	multipliers: any,
	prestigePolicy: any,
	jumpBudget: any,
	dashPolicy: any,
	boosts: any,
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
	local bonuses = self.multipliers:compute(profile, {
		stage = self.ladder:get(session.stageId),
		passes = session.passes,
		boosts = boostBonuses,
	})
	local movement = self.progression:movementFor(profile, bonuses)

	local reachedStage = self.ladder:highestUnlocked(profile.speed)
	local nextStage = self.ladder:nextOf(reachedStage)
	local level = self.levels:progressFor(profile.speed)

	return {
		-- Permanent progression
		speed = profile.speed,
		coins = profile.coins,
		prestiges = profile.prestiges,
		highestStage = profile.highestStage,
		reachedStage = reachedStage,
		upgrades = table.clone(profile.upgrades),
		passes = table.clone(session.passes),

		-- Current run
		stageId = session.stageId,
		hasCheckpoint = session.checkpoint ~= nil,

		-- Movement
		walkSpeed = movement.walkSpeed,
		jumpPower = movement.jumpPower,
		jumpLevel = movement.jumpLevel,
		jumpsLeft = self.jumpBudget:remaining(session.jumps, self.jumpBudget:capacityFor(bonuses)),
		dashUnlocked = movement.dashUnlocked,
		dashLevel = movement.dashLevel,
		dashMultiplier = movement.dashMultiplier,
		dashPower = movement.dashPower,
		dashCooldown = self.dashPolicy:remainingCooldown(session.dash, self.clock.monotonic()),
		magnet = movement.magnet,
		saturation = movement.saturation,

		-- Multipliers
		speedMultiplier = bonuses.speed,
		coinMultiplier = bonuses.coins,
		boostSpeed = boostBonuses.speed,
		boostCoins = boostBonuses.coins,
		activeBoosts = self.boosts:activeFor(profile, now),

		-- Prestige
		prestigeMultiplier = self.prestigePolicy:multiplierFor(profile.prestiges),
		prestigeRequirement = self.prestigePolicy:requirementFor(profile.prestiges),
		prestigeProgress = self.prestigePolicy:progressFor(profile),

		-- Rank. What the player reads; the Stage is what the map gates on.
		level = level.level,
		bestLevel = profile.bestLevel,
		levelCurrent = level.current,
		levelRequired = level.required,
		levelProgress = level.ratio,

		-- Next gate
		stageProgress = self.ladder:progressToNext(reachedStage, profile.speed),
		nextStageRequirement = nextStage and nextStage.requiredSpeed,
	}
end

return Snapshot
