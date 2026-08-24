--!strict
--[[
	LoadPlayerProfile — opens the session of a player joining the game.

	Major safety rule: if reading the store fails, the player can still play but the
	session is marked NOT savable. Losing one session is far better than overwriting
	hours of progress with an empty profile.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Profile = require(Shared.Domain.Profile.Profile)
local Result = require(Shared.Domain.Support.Result)

local LoadPlayerProfile = {}
LoadPlayerProfile.__index = LoadPlayerProfile

function LoadPlayerProfile.new(dependencies)
	return setmetatable(table.clone(dependencies), LoadPlayerProfile)
end

function LoadPlayerProfile.run(self, player)
	local userId = player.UserId

	local loaded, raw = pcall(function()
		return self.repository:load(userId)
	end)

	local session = self.sessions:open(userId, Profile.migrate(if loaded then raw else nil), player)
	session.savable = loaded

	local now = self.clock.now()
	session.joinedAt = now

	local passesLoaded, passes = pcall(function()
		return self.passGateway:ownedPasses(player)
	end)
	session.passes = if passesLoaded and typeof(passes) == "table" then passes else {}

	-- Session hooks (pruning expired boosts, arming timers) injected by the container.
	for _, hook in self.sessionHooks or {} do
		hook(session, now)
	end

	self.publisher:publish(player, self.snapshots:build(session))

	if not loaded then
		self.notifier:notify(player, "Save unavailable: your progress will not be stored.", "error")
		return Result.err("LOAD_FAILED", tostring(raw), session)
	end

	return Result.ok(session)
end

return LoadPlayerProfile
