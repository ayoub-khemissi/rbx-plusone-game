--!strict
--[[
	PassPerksController — confort offert par les gamepasses.

	  - Course automatique : le singe avance seul vers la suite de la piste ;
	  - Aimant a bananes  : signale au serveur les bananes proches (le serveur
	    verifie le gamepass ET la distance avant de crediter).

	Aucun de ces avantages ne modifie l'equilibrage : ils font gagner du confort,
	pas des multiplicateurs caches.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local BANANA_TAG = "Banane"
local MAGNET_RADIUS = 40
local MAGNET_INTERVAL = 0.25
local AUTO_RUN_INTERVAL = 0.1

local PassPerksController = {}
PassPerksController.__index = PassPerksController

function PassPerksController.new(player: Player, state, remotes)
	local self = setmetatable({
		player = player,
		state = state,
		remotes = remotes,
		magnetAccumulator = 0,
		autoRunAccumulator = 0,
	}, PassPerksController)

	RunService.Heartbeat:Connect(function(deltaTime)
		self:_update(deltaTime)
	end)

	return self
end

function PassPerksController._character(self)
	local character = self.player.Character
	if not character then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return root, humanoid
end

function PassPerksController._update(self, deltaTime: number)
	local root, humanoid = self:_character()
	if not root then
		return
	end

	if self.state:owns("autoRun") then
		self.autoRunAccumulator += deltaTime
		if self.autoRunAccumulator >= AUTO_RUN_INTERVAL then
			self.autoRunAccumulator = 0
			-- On vise droit devant, le long de la piste (axe +X).
			humanoid:Move(Vector3.new(1, 0, 0), false)
		end
	end

	if self.state:owns("bananaMagnet") then
		self.magnetAccumulator += deltaTime
		if self.magnetAccumulator >= MAGNET_INTERVAL then
			self.magnetAccumulator = 0
			self:_collectNearby(root)
		end
	end
end

function PassPerksController._collectNearby(self, root: BasePart)
	for _, instance in CollectionService:GetTagged(BANANA_TAG) do
		local banana = instance :: BasePart
		if
			banana.Parent
			and banana.CanTouch
			and (banana.Position - root.Position).Magnitude <= MAGNET_RADIUS
		then
			self.remotes.events.CollectBanana:FireServer(banana)
		end
	end
end

return PassPerksController
