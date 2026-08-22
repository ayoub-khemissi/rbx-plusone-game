--!strict
--[[
	RemoteBindings — traduit les messages reseau en appels de cas d'usage.

	Regle : cette couche NE CONTIENT AUCUNE REGLE DE JEU. Elle valide les types
	recus du client (qui peut envoyer n'importe quoi) et delegue. Toute decision
	revient au domaine.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local RemoteBindings = {}

local MAGNET_RANGE = 60 -- portee maximale acceptee pour un ramassage a distance

local function distanceToPlayer(player: Player, part: BasePart): number
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return math.huge
	end
	return (root.Position - part.Position).Magnitude
end

function RemoteBindings.bind(container, remotes, world)
	local useCases = container.useCases
	local events = remotes.events
	local functions = remotes.functions

	events.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
		useCases.buyUpgrade:run(player, upgradeId)
	end)

	events.Rebirth.OnServerEvent:Connect(function(player)
		useCases.performRebirth:run(player)
	end)

	events.TravelZone.OnServerEvent:Connect(function(player, zoneId)
		useCases.travelToZone:run(player, zoneId)
	end)

	events.RedeemCode.OnServerEvent:Connect(function(player, code)
		useCases.redeemCode:run(player, code)
	end)

	events.ClaimDaily.OnServerEvent:Connect(function(player)
		useCases.claimDailyReward:run(player)
	end)

	events.ClaimChest.OnServerEvent:Connect(function(player)
		useCases.claimPlaytimeChest:run(player)
	end)

	events.PromptPurchase.OnServerEvent:Connect(function(player, kind, id)
		useCases.promptPurchase:run(player, kind, id)
	end)

	-- Aimant a bananes : le client signale la cible, le serveur verifie le gamepass
	-- ET la distance reelle avant de crediter.
	events.CollectBanana.OnServerEvent:Connect(function(player, part)
		local session = container.sessions:forPlayer(player)
		if not session or not session.passes.bananaMagnet then
			return
		end
		if
			typeof(part) ~= "Instance"
			or not part:IsA("BasePart")
			or not part:IsDescendantOf(world.folder)
		then
			return
		end
		if part:GetAttribute("Valeur") == nil or distanceToPlayer(player, part) > MAGNET_RANGE then
			return
		end

		world.collect(player, part)
	end)

	functions.GetOffers.OnServerInvoke = function(player)
		local result = useCases.listOffers:run(player)
		return if result.ok then result.value.offers else {}
	end

	functions.GetRewardStatus.OnServerInvoke = function(player)
		local daily = useCases.claimDailyReward:status(player)
		local chest = useCases.claimPlaytimeChest:status(player)
		return {
			daily = if daily.ok then daily.value else nil,
			chest = if chest.ok then chest.value else nil,
		}
	end

	-- Achats Robux : Roblox rejoue le recu tant qu'on ne confirme pas.
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local result = useCases.processReceipt:run(receiptInfo)

		if result.ok then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if result.code == "UNKNOWN_PRODUCT" then
			-- Produit retire du jeu : on confirme pour ne pas boucler indefiniment.
			container.ports.logger:warn(`Recu pour un produit inconnu : {receiptInfo.ProductId}`)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		container.ports.logger:warn(`Achat non confirme ({result.code}), Roblox rejouera`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Gamepass achete en cours de partie : on recharge les droits immediatement.
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _assetId, wasPurchased)
		if not wasPurchased then
			return
		end
		local session = container.sessions:forPlayer(player)
		if not session then
			return
		end

		local ok, passes = pcall(function()
			return container.ports.passGateway:ownedPasses(player)
		end)
		if ok and typeof(passes) == "table" then
			session.passes = passes
			container.ports.publisher:publish(player, container.snapshots:build(session))
			container.ports.notifier:notify(player, "Merci ! Ton avantage est actif.", "success")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		container.ports.notifier:forget(player)
		container.ports.passGateway:forget(player)
	end)
end

return RemoteBindings
