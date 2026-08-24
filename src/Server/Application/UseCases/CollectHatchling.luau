--!strict
--[[
	CollectHatchling — a hatched egg becomes a dragon.

	The species is rolled here, at the edge of the Application layer, from the
	injected generator: the domain stays pure and a drop stays reproducible in tests.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local CollectHatchling = {}
CollectHatchling.__index = CollectHatchling

function CollectHatchling.new(dependencies)
	return setmetatable(table.clone(dependencies), CollectHatchling)
end

function CollectHatchling.run(self, player, slotIndex)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "No open session")
	end

	local profile = session.profile
	local hatched = self.clutch:collect(profile, slotIndex, self.clock.now())
	if not hatched.ok then
		return hatched
	end

	local species = self.dragons:roll(hatched.value.rarity, self.random.nextNumber())
	if not species then
		return Result.err("NO_SPECIES", `No dragon of rarity {hatched.value.rarity}`)
	end

	profile.dragons[species.id] = (profile.dragons[species.id] or 0) + 1

	self.publisher:publish(player, self.snapshots:build(session))
	self.notifier:notify(player, `🐉 {species.name} hatched! ({hatched.value.rarity})`, "success")
	self.save:run(session.userId)

	return Result.ok({ species = species, rarity = hatched.value.rarity })
end

return CollectHatchling
