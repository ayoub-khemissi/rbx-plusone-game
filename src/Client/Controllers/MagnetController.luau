--!strict
--[[
	MagnetController — catches nearby rings for players who own the magnet.

	The client only points at a ring; the server checks the distance, the tag and the
	cooldown before paying anything.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local RING_TAG = "Ring"
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
	if radius <= 0 or not self.state:flag("Flying") then
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

	for _, instance in CollectionService:GetTagged(RING_TAG) do
		local sensor = instance :: BasePart
		if sensor.Parent and (sensor.Position - root.Position).Magnitude <= radius then
			self.remotes.events.CollectRing:FireServer(sensor)
		end
	end
end

return MagnetController
