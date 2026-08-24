--!strict
--[[
	InMemoryProfileRepository — the ProfileRepository port, without a DataStore.

	Used in Studio when API access is off: the game stays entirely playable and the
	save is simply lost when the server stops.
]]

local InMemoryProfileRepository = {}
InMemoryProfileRepository.__index = InMemoryProfileRepository

function InMemoryProfileRepository.new()
	return setmetatable({ store = {} }, InMemoryProfileRepository)
end

function InMemoryProfileRepository.load(self, userId: number): any?
	return self.store[userId]
end

function InMemoryProfileRepository.save(self, userId: number, profile: any): boolean
	-- A shallow copy: what is stored is a snapshot, not the live table.
	self.store[userId] = table.clone(profile)
	return true
end

return InMemoryProfileRepository
