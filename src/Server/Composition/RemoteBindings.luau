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

function RemoteBindings.bind(container, remotes)
	local useCases = container.useCases
	local events = remotes.events
	local functions = remotes.functions

	events.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
		useCases.buyUpgrade:run(player, upgradeId)
	end)

	events.Prestige.OnServerEvent:Connect(function(player)
		useCases.performPrestige:run(player)
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

	-- The client asks for an air jump; the server owns the budget and answers.
	events.RequestJump.OnServerEvent:Connect(function(player)
		local result = useCases.requestJump:run(player)
		if result.ok then
			events.JumpGranted:FireClient(player, result.value.jumpPower)
		end
	end)

	events.Landed.OnServerEvent:Connect(function(player)
		useCases.noteLanded:run(player)
	end)

	-- Same for the dash: the cooldown lives server side, or it would not be waited.
	events.RequestDash.OnServerEvent:Connect(function(player)
		local result = useCases.requestDash:run(player)
		if result.ok then
			events.DashGranted:FireClient(player, result.value.power)
		end
	end)

	-- Coin magnet: the client points at a coin, the server checks the tag and the
	-- distance before paying anything.
	events.CollectCoin.OnServerEvent:Connect(function(player, part)
		if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
			return
		end
		if not CollectionService:HasTag(part, "Coin") or not part.CanTouch then
			return
		end
		if distanceToPlayer(player, part) > MAX_MAGNET_RANGE then
			return
		end

		local value = part:GetAttribute("Value") or container.config.Balance.run.coinValue
		useCases.collectCoin:run(player, value)

		part.Transparency = 1
		part.CanTouch = false
		task.delay(container.config.Balance.run.coinRespawn, function()
			if part.Parent then
				part.Transparency = 0
				part.CanTouch = true
			end
		end)
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
