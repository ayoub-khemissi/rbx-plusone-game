--!strict
--[[
	SessionRegistry — etat en memoire des joueurs connectes.

	Une session est le pont entre un joueur Roblox et son profil de domaine. Elle
	porte aussi ce qui ne doit PAS etre persiste : derniere position echantillonnee,
	zone courante, gamepasses charges, drapeau de sauvegarde.
]]

local Ports = require(script.Parent.Ports)

type PlayerRef = Ports.PlayerRef
type Point = Ports.Point

export type Session = {
	userId: number,
	player: PlayerRef?,
	profile: any,
	zoneId: number,
	passes: { [string]: boolean },
	lastPosition: Point?,
	lastSampleAt: number?,
	savable: boolean,
	joinedAt: number?,
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
		zoneId = 1,
		passes = {},
		lastPosition = nil,
		lastSampleAt = nil,
		savable = true,
		joinedAt = nil,
	}

	if self._sessions[userId] == nil then
		self._count += 1
	end
	self._sessions[userId] = session
	return session
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
