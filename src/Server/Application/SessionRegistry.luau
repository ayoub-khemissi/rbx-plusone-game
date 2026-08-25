--!strict
--[[
	SessionRegistry — in-memory state of the connected players.

	A session bridges a Roblox player and their domain profile. It also carries
	everything that must NOT be persisted: the checkpoint they will come back to, the
	air jumps already spent, the dash cooldown.

	That separation is deliberate. Nothing about a run should survive a reconnection:
	a save is about progress, never about where you were standing.
]]

local Shared = require(script.Parent.Parent.Shared)
local JumpBudget = require(Shared.Domain.Movement.JumpBudget)
local DashPolicy = require(Shared.Domain.Movement.DashPolicy)

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

	-- Current run, all of it volatile
	stageId: number,
	checkpoint: Point?,
	lastPosition: Point?,
	lastSampleAt: number?,
	jumps: JumpBudget.State,
	dash: DashPolicy.State,
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

		stageId = 1,
		checkpoint = nil,
		lastPosition = nil,
		lastSampleAt = nil,
		jumps = JumpBudget.newState(),
		dash = DashPolicy.newState(),
	}

	if self._sessions[userId] == nil then
		self._count += 1
	end
	self._sessions[userId] = session
	return session
end

--[[ Clears everything tied to the current position on the course. ]]
function SessionRegistry.resetRun(_self: SessionRegistry, session: Session)
	session.stageId = 1
	session.checkpoint = nil
	session.lastPosition = nil
	session.lastSampleAt = nil
	session.jumps = JumpBudget.newState()
	session.dash = DashPolicy.newState()
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
