--!strict
--[[ PerformMolt — the long loop: shed everything, come back stronger. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Format = require(Shared.Domain.Support.Format)

local PerformMolt = {}
PerformMolt.__index = PerformMolt

function PerformMolt.new(dependencies)
	return setmetatable(table.clone(dependencies), PerformMolt)
end

function PerformMolt.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	-- Molting mid-flight would wipe the speed the pouch is riding on.
	if session.flying then
		return Result.err("IN_FLIGHT", "Land at the Nest before molting")
	end

	local result = self.moltPolicy:apply(session.profile)
	if not result.ok then
		local missing = result.value and result.value.missing or 0
		self.notifier:notify(player, `{Format.abbreviate(missing)} more speed before you can molt.`, "error")
		return result
	end

	self.teleporter:sendTo(player, self.nestPoint)
	self.publisher:publish(player, self.snapshots:build(session))
	self.notifier:notify(
		player,
		`Molt {result.value.molts}! All gains {Format.multiplier(result.value.multiplier)}`,
		"success"
	)

	self.save:run(session.userId)
	return result
end

return PerformMolt
