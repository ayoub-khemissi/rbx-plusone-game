--!strict
--[[
	MagnetController — collects nearby Coins for players who own the magnet.

	The client only points at a Coin; the server checks the tag, the distance and the
	respawn state before paying anything.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local COIN_TAG = "Coin"
local INTERVAL = 0.2

local MagnetController = {}
MagnetController.__index = MagnetController

function MagnetController.new(player: Player, state, remotes)
	local self = setmetatable({
		player = player,
		state = state,
		remotes = remotes,
		accumulator = 0,
	}, MagnetController)

	RunService.Heartbeat:Connect(function(deltaTime)
		self:_update(deltaTime)
	end)

	return self
end

function MagnetController._update(self, deltaTime: number)
	local radius = self.state:get("Magnet")
	if radius <= 0 then
		return
	end

	self.accumulator += deltaTime
	if self.accumulator < INTERVAL then
		return
	end
	self.accumulator = 0

	local character = self.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	for _, instance in CollectionService:GetTagged(COIN_TAG) do
		local coin = instance :: BasePart
		if coin.Parent and coin.CanTouch and (coin.Position - root.Position).Magnitude <= radius then
			-- The answer comes back on the same remote, with the amount. Sounding it
			-- here as well would double every pickup, and CoinController is the one
			-- place that knows what the coin was actually worth.
			self.remotes.events.CollectCoin:FireServer(coin)
		end
	end
end

return MagnetController
