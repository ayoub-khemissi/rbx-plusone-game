--!strict
--[[
	RemoteBindings — turns network messages into use case calls.

	Rule: this layer HOLDS NO GAME RULE. It validates the types coming from the
	client (which can send anything) and delegates. Every decision belongs to the
	domain.
]]

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local RemoteBindings = {}

-- Hard ceiling on the magnet, whatever the client claims to own.
local MAX_MAGNET_RANGE = 90

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

	events.StartFlight.OnServerEvent:Connect(function(player)
		useCases.startFlight:run(player)
	end)

	events.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
		useCases.buyUpgrade:run(player, upgradeId)
	end)

	events.Molt.OnServerEvent:Connect(function(player)
		useCases.performMolt:run(player)
	end)

	events.PlaceEgg.OnServerEvent:Connect(function(player, rarity)
		useCases.placeEgg:run(player, rarity)
	end)

	events.CollectHatchling.OnServerEvent:Connect(function(player, slotIndex)
		useCases.collectHatchling:run(player, slotIndex)
	end)

	events.RedeemCode.OnServerEvent:Connect(function(player, code)
		useCases.redeemCode:run(player, code)
	end)

	events.ClaimDaily.OnServerEvent:Connect(function(player)
		useCases.claimDailyReward:run(player)
	end)

	events.ClaimChest.OnServerEvent:Connect(function(player)
		useCases.claimSessionChest:run(player)
	end)

	events.PromptPurchase.OnServerEvent:Connect(function(player, kind, id)
		useCases.promptPurchase:run(player, kind, id)
	end)

	-- Ring magnet: the client points at the ring, the server checks the pass, the
	-- distance and the cooldown before paying anything.
	events.CollectRing.OnServerEvent:Connect(function(player, part)
		local session = container.sessions:forPlayer(player)
		if not session or not session.flying then
			return
		end
		if
			typeof(part) ~= "Instance"
			or not part:IsA("BasePart")
			or not part:IsDescendantOf(world.folder)
		then
			return
		end
		if not CollectionService:HasTag(part, "Ring") then
			return
		end
		if distanceToPlayer(player, part) > MAX_MAGNET_RANGE then
			return
		end

		world.collectRing(player, part)
	end)

	functions.GetOffers.OnServerInvoke = function(player)
		local result = useCases.listOffers:run(player)
		return if result.ok then result.value.offers else {}
	end

	functions.GetRewardStatus.OnServerInvoke = function(player)
		local daily = useCases.claimDailyReward:status(player)
		local chest = useCases.claimSessionChest:status(player)
		return {
			daily = if daily.ok then daily.value else nil,
			chest = if chest.ok then chest.value else nil,
		}
	end

	-- Robux purchases: Roblox replays the receipt until it is confirmed.
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local result = useCases.processReceipt:run(receiptInfo)

		if result.ok then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		if result.code == "UNKNOWN_PRODUCT" then
			-- Product removed from the game: confirm, or Roblox loops forever.
			container.ports.logger:warn(`Receipt for an unknown product: {receiptInfo.ProductId}`)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		container.ports.logger:warn(`Purchase not confirmed ({result.code}), Roblox will replay`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- A gamepass bought mid-session: reload the entitlements at once.
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
			container.ports.notifier:notify(player, "Thanks! Your perk is live.", "success")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		container.ports.notifier:forget(player)
		container.ports.passGateway:forget(player)
	end)
end

return RemoteBindings
