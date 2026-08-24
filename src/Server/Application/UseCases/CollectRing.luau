--!strict
--[[
	CollectRing — a ring crossed mid-flight.

	The gold goes into the pouch, so it stays at risk until an Altar. Rings are also
	the readable trajectory of the corridor: crossing them is what a good line looks
	like.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local CollectRing = {}
CollectRing.__index = CollectRing

function CollectRing.new(dependencies)
	return setmetatable(table.clone(dependencies), CollectRing)
end

function CollectRing.run(self, player, value)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	if not session.flying or not session.pouch then
		return Result.err("NOT_FLYING", "Rings only pay in flight")
	end

	local profile = session.profile
	local granted =
		self.progression:collectRing(profile, session.pouch, if typeof(value) == "number" then value else 0, {
			passes = session.passes,
			boosts = self.boosts:multipliersFor(profile, self.clock.now()),
			dragons = self.dragons:bonusesFor(profile),
		})

	self.publisher:publish(player, self.snapshots:build(session))
	return Result.ok({ granted = granted })
end

return CollectRing
