--!strict
--[[
	MagnetController — collects nearby Coins for players who own the magnet.

	The client only points at a Coin; the server checks the tag, the distance and the
	respawn state before paying anything.
]]

local CollectionService = game:GetService("CollectionService")

local Sound = require(script.Parent.Parent.Sound)
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
			self.remotes.events.CollectCoin:FireServer(coin)
			-- Answered here rather than on the server's confirmation: the pickup is
			-- the moment the player felt, and a reply a round trip later reads as
			-- lag. The server still decides what it pays.
			Sound.playRepeating("coin")
		end
	end
end

return MagnetController
