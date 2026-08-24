--!strict
--[[
	MarketplaceGateway — the PassGateway and Marketplace ports, over
	MarketplaceService.

	Pass ownership is cached per session. `UserOwnsGamePassAsync` is a network call,
	and every multiplier computation would otherwise make one. The cache is dropped
	as soon as a purchase goes through.
]]

local MarketplaceService = game:GetService("MarketplaceService")

local MarketplaceGateway = {}
MarketplaceGateway.__index = MarketplaceGateway

export type Pass = { id: string, assetId: number }

function MarketplaceGateway.new(passes: { Pass }, logger: any?)
	return setmetatable({
		passes = passes,
		logger = logger,
		_cache = {},
	}, MarketplaceGateway)
end

function MarketplaceGateway.ownedPasses(self, player: Player): { [string]: boolean }
	local owned = {}

	for _, pass in self.passes do
		if pass.assetId ~= 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.assetId)
			end)

			if ok then
				owned[pass.id] = result == true
			elseif self.logger then
				self.logger:warn(`Could not check gamepass {pass.id}: {tostring(result)}`)
			end
		end
	end

	self._cache[player.UserId] = owned
	return owned
end

function MarketplaceGateway.forget(self, player: Player)
	self._cache[player.UserId] = nil
end

function MarketplaceGateway.promptProduct(_self, player: Player, productId: number)
	if productId == 0 then
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

function MarketplaceGateway.promptGamePass(_self, player: Player, assetId: number)
	if assetId == 0 then
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, assetId)
end

return MarketplaceGateway
