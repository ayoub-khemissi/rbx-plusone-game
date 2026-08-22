--!strict
--[[ PerformRebirth — renaissance : tout repart de zero, en plus fort. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)
local Format = require(Shared.Domain.Support.Format)

local PerformRebirth = {}
PerformRebirth.__index = PerformRebirth

function PerformRebirth.new(dependencies)
	return setmetatable(table.clone(dependencies), PerformRebirth)
end

function PerformRebirth.run(self, player)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	local result = self.rebirthPolicy:apply(session.profile)
	if not result.ok then
		local missing = result.value and result.value.missing or 0
		self.notifier:notify(
			player,
			`Encore {Format.abbreviate(missing)} de vitesse pour renaitre !`,
			"error"
		)
		return result
	end

	session.zoneId = 1
	session.lastPosition = nil
	session.lastSampleAt = nil

	self.teleporter:sendTo(player, self.layout:spawnOf(1))
	self.publisher:publish(player, self.snapshots:build(session))
	self.notifier:notify(
		player,
		`Renaissance {result.value.rebirths} ! Gains {Format.multiplier(result.value.multiplier)}`,
		"success"
	)

	if self.save then
		self.save:run(session.userId)
	end

	return result
end

return PerformRebirth
