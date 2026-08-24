--!strict
--[[
	DataStoreProfileRepository — the ProfileRepository port, over DataStoreService.

	Two precautions that production cannot do without:
	  - RETRY with a growing wait: DataStores fail regularly, for quota or network
	    reasons, and a first failure means very little;
	  - raise the failure through `error()`: the use case then marks the session
	    read-only rather than overwriting the player's save with a blank profile.
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

--[[
	The storage key. Changing it orphans every existing save, so it is fixed for the
	lifetime of the game — which is why it is worth getting right before launch.
]]
local function keyFor(userId: number): string
	return `player_{userId}`
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

	error(`DataStore unavailable after {self.maxRetries} attempts: {tostring(lastError)}`, 0)
end

function DataStoreProfileRepository.load(self, userId: number): any?
	return self:_attempt(function()
		return self.store:GetAsync(keyFor(userId))
	end)
end

function DataStoreProfileRepository.save(self, userId: number, profile: any): boolean
	self:_attempt(function()
		-- UpdateAsync rather than SetAsync: a serialised write, which survives two
		-- servers saving the same profile at the same time.
		return self.store:UpdateAsync(keyFor(userId), function()
			return profile
		end)
	end)
	return true
end

return DataStoreProfileRepository
