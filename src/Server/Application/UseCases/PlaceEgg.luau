--!strict
--[[ PlaceEgg — moves an egg from the stock into a hatchery slot. ]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local PlaceEgg = {}
PlaceEgg.__index = PlaceEgg

function PlaceEgg.new(dependencies)
	return setmetatable(table.clone(dependencies), PlaceEgg)
end

--[[ Extra slots bought with the Nest Keeper pass. ]]
function PlaceEgg.extraSlots(self, session): number
	return if session.passes.nestKeeper then self.extraSlotsPerPass else 0
end

function PlaceEgg.run(self, player, rarity)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end
	if typeof(rarity) ~= "string" then
		return Result.err("NO_EGG", "Unknown rarity")
	end

	local placed = self.clutch:place(session.profile, rarity, self.clock.now(), self:extraSlots(session))
	if not placed.ok then
		self.notifier:notify(player, placed.message or "Cannot place that egg.", "error")
		return placed
	end

	self.publisher:publish(player, self.snapshots:build(session))
	self.notifier:notify(player, `A {rarity} egg is warming up.`, "info")
	self.save:run(session.userId)

	return placed
end

return PlaceEgg
