--!strict
--[[
	Ports — the boundaries of the Application layer.

	A port is an INTERFACE: the Application layer knows these contracts and never
	their implementation. Adapters (src/Server/Adapters) realise them with Roblox
	APIs, tests with in-memory doubles.

	Nothing here is instantiable: this module only documents and types the wiring
	performed by Composition/Container.
]]

export type PlayerRef = { UserId: number, Name: string }

export type Point = { x: number, y: number, z: number }

--[[ Player profile persistence. May throw: the caller handles the failure. ]]
export type ProfileRepository = {
	load: (self: ProfileRepository, userId: number) -> any?,
	save: (self: ProfileRepository, userId: number, profile: any) -> boolean,
}

--[[ Replication of the state to the client (attributes, leaderstats...). ]]
export type StatsPublisher = {
	publish: (self: StatsPublisher, player: PlayerRef, snapshot: any) -> (),
}

--[[ Short messages shown to the player. ]]
export type Notifier = {
	notify: (self: Notifier, player: PlayerRef, message: string, kind: string?) -> (),
}

--[[ Applies the flight state (velocity, agility) to the dragon. ]]
export type FlightActuator = {
	apply: (self: FlightActuator, player: PlayerRef, flight: any) -> (),
}

--[[ Forced movement of the character: launch, barrier push-back, return to the Nest. ]]
export type Teleporter = {
	sendTo: (self: Teleporter, player: PlayerRef, position: Point) -> (),
}

--[[ Gamepass ownership and purchase prompts. ]]
export type PassGateway = {
	ownedPasses: (self: PassGateway, player: PlayerRef) -> { [string]: boolean },
}

export type Marketplace = {
	promptProduct: (self: Marketplace, player: PlayerRef, productId: number) -> (),
	promptGamePass: (self: Marketplace, player: PlayerRef, assetId: number) -> (),
}

--[[
	Injectable clock. `now()` is an absolute epoch — incubation and boosts must
	survive a disconnection — while `monotonic()` measures durations.
]]
export type Clock = {
	now: () -> number,
	monotonic: () -> number,
}

--[[ Injectable randomness: keeps every drop reproducible in a test. ]]
export type Random = {
	nextNumber: () -> number,
}

return {}
