--!strict
--[[
	MarketplaceGateway — ports PassGateway et Marketplace via MarketplaceService.

	La possession d'un gamepass est mise en cache par session : `UserOwnsGamePassAsync`
	est un appel reseau, l'appeler a chaque calcul de multiplicateur ferait ramer le
	serveur. Le cache est invalide des qu'un achat aboutit.
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
				self.logger:warn(`Verification du gamepass {pass.id} impossible : {tostring(result)}`)
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
