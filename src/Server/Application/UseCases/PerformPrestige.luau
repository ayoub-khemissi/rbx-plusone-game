--!strict
--[[ PerformPrestige — the long loop: reset everything, come back stronger. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Format = require(Shared.Domain.Support.Format)

local PerformPrestige = {}
PerformPrestige.__index = PerformPrestige

function PerformPrestige.new(dependencies)
	return setmetatable(table.clone(dependencies), PerformPrestige)
end

function PerformPrestige.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local result = self.prestigePolicy:apply(session.profile)
	if not result.ok then
		local missing = result.value and result.value.missing or 0
		self.notifier:notify(
			player,
			`{Format.abbreviate(missing)} more {self.labels.level.name} before your next {self.labels.prestige.name}.`,
			"error"
		)
		return result
	end

	-- The course starts over too: keeping a deep checkpoint would skip it all.
	self.sessions:resetRun(session)

	self.body:sendTo(player, self.hubPoint)
	-- Played on the server, so the room sees it. A rebirth is the one moment in the
	-- game whose whole point is being watched.
	self.effects:celebrate(player, "rebirth")
	self.publisher:publish(player, self.snapshots:build(session))
	self.notifier:notify(
		player,
		`{self.labels.prestige.name} {result.value.prestiges}! All gains {Format.multiplier(
			result.value.multiplier
		)}`,
		"success"
	)

	self.save:run(session.userId)
	return result
end

return PerformPrestige
