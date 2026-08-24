--!strict
--[[
	SessionRegistry — in-memory state of the connected players.

	A session bridges a Roblox player and their domain profile. It also carries
	everything that must NOT be persisted: the pouch of the current flight, the last
	sampled position, the feathers armed for this flight.

	That separation is deliberate. A flight must never survive a reconnection —
	otherwise disconnecting would become a way to protect a pouch.
]]

local Ports = require(script.Parent.Ports)

type PlayerRef = Ports.PlayerRef
type Point = Ports.Point

export type Session = {
	userId: number,
	player: PlayerRef?,
	profile: any,
	passes: { [string]: boolean },
	savable: boolean,
	joinedAt: number?,

	-- Current flight, all of it volatile
	flying: boolean,
	pouch: any?,
	tierId: number,
	feathers: number,
	insured: boolean,
	lastPosition: Point?,
	lastSampleAt: number?,
	perchedAt: number?,
}

local SessionRegistry = {}
SessionRegistry.__index = SessionRegistry

export type SessionRegistry = typeof(setmetatable(
	{} :: { _sessions: { [number]: Session }, _count: number },
	SessionRegistry
))

function SessionRegistry.new(): SessionRegistry
	return setmetatable({ _sessions = {}, _count = 0 }, SessionRegistry)
end

function SessionRegistry.open(
	self: SessionRegistry,
	userId: number,
	profile: any,
	player: PlayerRef?
): Session
	local session: Session = {
		userId = userId,
		player = player,
		profile = profile,
		passes = {},
		savable = true,
		joinedAt = nil,

		flying = false,
		pouch = nil,
		tierId = 0,
		feathers = 0,
		insured = false,
		lastPosition = nil,
		lastSampleAt = nil,
		perchedAt = nil,
	}

	if self._sessions[userId] == nil then
		self._count += 1
	end
	self._sessions[userId] = session
	return session
end

--[[ Clears everything that belongs to a single flight. ]]
function SessionRegistry.endFlight(_self: SessionRegistry, session: Session)
	session.flying = false
	session.pouch = nil
	session.tierId = 0
	session.feathers = 0
	session.insured = false
	session.lastPosition = nil
	session.lastSampleAt = nil
end

function SessionRegistry.get(self: SessionRegistry, userId: number): Session?
	return self._sessions[userId]
end

function SessionRegistry.forPlayer(self: SessionRegistry, player: PlayerRef): Session?
	return if player then self._sessions[player.UserId] else nil
end

function SessionRegistry.close(self: SessionRegistry, userId: number): Session?
	local session = self._sessions[userId]
	if session then
		self._sessions[userId] = nil
		self._count -= 1
	end
	return session
end

function SessionRegistry.count(self: SessionRegistry): number
	return self._count
end

function SessionRegistry.forEach(self: SessionRegistry, visitor: (Session) -> ())
	for _, session in self._sessions do
		visitor(session)
	end
end

return SessionRegistry
