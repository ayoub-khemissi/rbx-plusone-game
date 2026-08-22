--!strict
--[[
	DataStoreProfileRepository — port ProfileRepository realise avec DataStoreService.

	Deux precautions indispensables en production :
	  - RETRY avec attente croissante : les DataStores echouent regulierement pour
	    des raisons de quota ou de reseau ;
	  - remontee de l'echec par `error()` : le cas d'usage marque alors la session
	    en lecture seule plutot que d'ecraser la sauvegarde du joueur.
]]

local DataStoreService = game:GetService("DataStoreService")

local DataStoreProfileRepository = {}
DataStoreProfileRepository.__index = DataStoreProfileRepository

export type Tuning = {
	dataStoreName: string,
	maxRetries: number,
	retryBackoff: number,
}

function DataStoreProfileRepository.new(tuning: Tuning)
	return setmetatable({
		store = DataStoreService:GetDataStore(tuning.dataStoreName),
		maxRetries = tuning.maxRetries,
		retryBackoff = tuning.retryBackoff,
	}, DataStoreProfileRepository)
end

local function keyFor(userId: number): string
	return `joueur_{userId}`
end

function DataStoreProfileRepository._attempt(self, action: () -> any): any
	local lastError

	for attempt = 1, self.maxRetries do
		local ok, result = pcall(action)
		if ok then
			return result
		end

		lastError = result
		if attempt < self.maxRetries then
			task.wait(self.retryBackoff ^ (attempt - 1))
		end
	end

	error(`DataStore indisponible apres {self.maxRetries} tentatives : {tostring(lastError)}`, 0)
end

function DataStoreProfileRepository.load(self, userId: number): any?
	return self:_attempt(function()
		return self.store:GetAsync(keyFor(userId))
	end)
end

function DataStoreProfileRepository.save(self, userId: number, profile: any): boolean
	self:_attempt(function()
		-- UpdateAsync plutot que SetAsync : ecriture serialisee, resistante aux
		-- ecritures concurrentes entre deux serveurs.
		return self.store:UpdateAsync(keyFor(userId), function()
			return profile
		end)
	end)
	return true
end

return DataStoreProfileRepository
