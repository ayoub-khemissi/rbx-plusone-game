--!strict
--[[
	EffectsController — the feeling of speed.

	A widening field of view and a trail behind the dragon do more for the sensation
	of velocity than the number on the HUD ever will.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BASE_FOV = 70
local MAX_EXTRA_FOV = 28
local TRAIL_THRESHOLD = 0.2

local EffectsController = {}
EffectsController.__index = EffectsController

function EffectsController.new(player: Player, state)
	local self = setmetatable({ player = player, state = state }, EffectsController)

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

function EffectsController._attachTrail(self, character: Model)
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	local top = Instance.new("Attachment")
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, 1.2, 0)
	top.Parent = root

	local bottom = Instance.new("Attachment")
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -1.2, 0)
	bottom.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "SpeedTrail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = 0.4
	trail.MinLength = 0.2
	trail.LightEmission = 0.7
	trail.Color = ColorSequence.new(Color3.fromRGB(250, 214, 120), Color3.fromRGB(250, 140, 90))
	trail.Transparency = NumberSequence.new(0.15, 1)
	trail.Enabled = false
	trail.Parent = root

	self.trail = trail
end

function EffectsController._update(self)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local saturation = math.clamp(self.state:get("Saturation"), 0, 1)
	local flying = self.state:flag("Flying")
	local target = BASE_FOV + MAX_EXTRA_FOV * (if flying then saturation else 0)

	if math.abs(camera.FieldOfView - target) > 0.5 then
		TweenService:Create(camera, TweenInfo.new(0.4), { FieldOfView = target }):Play()
	end

	if self.trail and self.trail.Parent then
		self.trail.Enabled = flying and saturation > TRAIL_THRESHOLD
	end
end

return EffectsController
