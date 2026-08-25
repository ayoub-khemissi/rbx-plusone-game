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
-- The furthest a Coin may be claimed from. Well past the Magnet's own reach: this
-- is the wall that stops a client claiming across the map, not the game rule.
local MAX_PICKUP_RANGE = 90

--[[
	How far a player is from something in the world.

	Through the PIVOT, so a Coin built as a model is measured the same way a Coin
	built as one part is. A map may use either and neither the check nor the range
	has to know which.
]]
local function distanceToPlayer(player: Player, instance: PVInstance): number
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return math.huge
	end
	return (root.Position - instance:GetPivot().Position).Magnitude
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

	--[[
		A Coin the client says it reached. The client owns what a pickup LOOKS like —
		see MapBindings — and the server owns whether it happened: the tag, the
		distance, and the player's own field, which is what stops the same Coin
		paying twice.

		The answer goes back on the same remote, carrying the Coin and what it was
		actually worth after the multipliers. Sending the part back rather than the
		amount alone lets the client match the answer to the Coin still flying
		towards it, with no bookkeeping on either side.
	]]
	events.CollectCoin.OnServerEvent:Connect(function(player, coin)
		-- A part or a model: whatever the map tagged, which is what the client
		-- claimed and what the answer will be matched against.
		if typeof(coin) ~= "Instance" or not coin:IsA("PVInstance") then
			return
		end
		if not CollectionService:HasTag(coin, "Coin") then
			return
		end
		if distanceToPlayer(player, coin) > MAX_PICKUP_RANGE then
			return
		end

		local value = coin:GetAttribute("Value") or container.config.Balance.run.coinValue
		local result = useCases.collectCoin:run(player, value, coin)
		if result.ok then
			events.CollectCoin:FireClient(player, coin, result.value.granted)
		end
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
			container.ports.notifier:cue(player, "reward")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		container.ports.notifier:forget(player)
		container.ports.passGateway:forget(player)
	end)
end

return RemoteBindings
