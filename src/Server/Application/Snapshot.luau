--!strict
--[[
	Snapshot — vue en lecture seule de l'etat d'un joueur, destinee au client.

	C'est un MODELE DE PRESENTATION : le client ne voit jamais l'entite Profile, il
	consomme ce contrat stable. Changer la forme de la sauvegarde n'impacte donc pas
	l'interface, et inversement.
]]

local SessionRegistry = require(script.Parent.SessionRegistry)

type Session = SessionRegistry.Session

export type Snapshot = {
	speed: number,
	bananas: number,
	rebirths: number,
	zoneId: number,
	highestZone: number,
	highestUnlockedZone: number,
	upgrades: { [string]: number },
	passes: { [string]: boolean },
	walkSpeed: number,
	jumpPower: number,
	wallGrip: number,
	airDash: number,
	saturation: number,
	speedMultiplier: number,
	bananaMultiplier: number,
	rebirthMultiplier: number,
	rebirthRequirement: number,
	rebirthProgress: number,
	zoneProgress: number,
	nextZoneRequirement: number?,
	boostSpeed: number,
	boostBananas: number,
	activeBoosts: { any },
}

local Snapshot = {}
Snapshot.__index = Snapshot

export type Dependencies = {
	ladder: any,
	progression: any,
	multipliers: any,
	rebirthPolicy: any,
	boosts: any,
	clock: any,
}

export type SnapshotFactory = typeof(setmetatable({} :: Dependencies, Snapshot))

function Snapshot.new(dependencies: Dependencies): SnapshotFactory
	return setmetatable(table.clone(dependencies), Snapshot)
end

function Snapshot.build(self: SnapshotFactory, session: Session): Snapshot
	local profile = session.profile
	local zone = self.ladder:get(session.zoneId)
	local now = self.clock.now()
	local boostBonuses = self.boosts:multipliersFor(profile, now)
	local bonuses = self.multipliers:compute(profile, {
		zone = zone,
		passes = session.passes,
		boosts = boostBonuses,
	})
	local movement = self.progression:movementFor(profile, bonuses)
	local nextZone = self.ladder:nextOf(session.zoneId)

	return {
		speed = profile.speed,
		bananas = profile.bananas,
		rebirths = profile.rebirths,
		zoneId = session.zoneId,
		highestZone = profile.highestZone,
		highestUnlockedZone = self.ladder:highestUnlocked(profile.speed),
		upgrades = table.clone(profile.upgrades),
		passes = table.clone(session.passes),

		walkSpeed = movement.walkSpeed,
		jumpPower = movement.jumpPower,
		wallGrip = movement.wallGrip,
		airDash = movement.airDash,
		saturation = movement.saturation,

		speedMultiplier = bonuses.speed,
		bananaMultiplier = bonuses.bananas,

		rebirthMultiplier = self.rebirthPolicy:multiplierFor(profile.rebirths),
		rebirthRequirement = self.rebirthPolicy:requirementFor(profile.rebirths),
		rebirthProgress = self.rebirthPolicy:progressFor(profile),

		zoneProgress = self.ladder:progressToNext(session.zoneId, profile.speed),
		nextZoneRequirement = nextZone and nextZone.requiredSpeed,

		boostSpeed = boostBonuses.speed,
		boostBananas = boostBonuses.bananas,
		activeBoosts = self.boosts:activeFor(profile, now),
	}
end

return Snapshot
