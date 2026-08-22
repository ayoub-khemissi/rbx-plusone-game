--!strict
--[[
	InMemoryProfileRepository — port ProfileRepository sans DataStore.

	Utilise en Studio quand l'acces aux API n'est pas active : le jeu reste
	entierement testable, la sauvegarde est simplement perdue a l'arret du serveur.
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
	-- Copie superficielle : on stocke un instantane, pas la table vivante.
	self.store[userId] = table.clone(profile)
	return true
end

return InMemoryProfileRepository
