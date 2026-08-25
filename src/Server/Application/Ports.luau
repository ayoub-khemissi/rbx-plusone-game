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

--[[
	Short messages shown to the player.

	`cue` names a MOMENT the client may answer with a sound — "checkpoint", "fall".
	The server never names a clip: which sound a moment makes, or whether it makes
	one at all, is the client's business and a theme's to change.
]]
export type Notifier = {
	notify: (self: Notifier, player: PlayerRef, message: string, kind: string?, cue: string?) -> (),
}

--[[ Applies the movement state (speed, jump, abilities) to the character. ]]
export type MovementActuator = {
	apply: (self: MovementActuator, player: PlayerRef, movement: any) -> (),
}

--[[
	The player's character, as the server is allowed to treat it: put it somewhere,
	or end it. A fall does both, one after the other.
]]
export type Body = {
	sendTo: (self: Body, player: PlayerRef, position: Point) -> (),
	kill: (self: Body, player: PlayerRef) -> (),
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
	Injectable clock. `now()` is an absolute epoch — boosts and daily streaks must
	survive a disconnection — while `monotonic()` measures durations that only make
	sense within one session, such as an ability cooldown.
]]
export type Clock = {
	now: () -> number,
	monotonic: () -> number,
}

return {}
