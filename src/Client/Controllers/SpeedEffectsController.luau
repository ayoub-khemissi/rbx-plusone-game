--!strict
--[[
	SpeedEffectsController — retour visuel de la vitesse.

	Champ de vision qui s'ouvre et trainee derriere le singe : c'est ce qui donne
	la sensation d'acceleration, bien plus que le chiffre affiche.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BASE_FOV = 70
local MAX_EXTRA_FOV = 26
local TRAIL_THRESHOLD = 0.25

local SpeedEffectsController = {}
SpeedEffectsController.__index = SpeedEffectsController

function SpeedEffectsController.new(player: Player, state)
	local self = setmetatable({ player = player, state = state }, SpeedEffectsController)

	player.CharacterAdded:Connect(function(character)
		self:_attachTrail(character)
	end)
	if player.Character then
		self:_attachTrail(player.Character)
	end

	RunService.RenderStepped:Connect(function()
		self:_update()
	end)

	return self
end

function SpeedEffectsController._attachTrail(self, character: Model)
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TraineeHaut"
	attachment0.Position = Vector3.new(0, 1.2, 0)
	attachment0.Parent = root

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TraineeBas"
	attachment1.Position = Vector3.new(0, -1.2, 0)
	attachment1.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "TraineeVitesse"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 0.35
	trail.MinLength = 0.2
	trail.LightEmission = 0.6
	trail.Color = ColorSequence.new(Color3.fromRGB(250, 214, 76), Color3.fromRGB(250, 140, 60))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Enabled = false
	trail.Parent = root

	self.trail = trail
end

function SpeedEffectsController._update(self)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local saturation = math.clamp(self.state:get("WalkSpeed") / 250, 0, 1)
	local target = BASE_FOV + MAX_EXTRA_FOV * saturation

	if math.abs(camera.FieldOfView - target) > 0.5 then
		TweenService:Create(camera, TweenInfo.new(0.4), { FieldOfView = target }):Play()
	end

	if self.trail and self.trail.Parent then
		self.trail.Enabled = saturation > TRAIL_THRESHOLD
	end
end

return SpeedEffectsController
