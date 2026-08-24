--!strict
--[[
	FlightController — arcade flight.

	The dragon is steered by the client because a client-owned body is the only way
	to get a responsive feel on Roblox. But the client decides only the DIRECTION:
	the velocity and turn rate come from the server, written on the character, and
	the server re-measures the resulting displacement. Tampering with this file
	changes how it feels, never what it earns.

	Steering reads `Humanoid.MoveDirection`, which is already filled by the keyboard
	on desktop and by the thumbstick on mobile — one code path for both. Climb and
	dive are bound through ContextActionService so touch devices get real buttons.
]]

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local FlightController = {}
FlightController.__index = FlightController

local CLIMB_ACTION = "DragonClimb"
local DIVE_ACTION = "DragonDive"
local VERTICAL_WEIGHT = 0.8
local MIN_PITCH = -0.85
local MAX_PITCH = 0.85

function FlightController.new(player: Player, state)
	local self = setmetatable({
		player = player,
		state = state,
		climb = 0,
		dive = 0,
		flying = false,
	}, FlightController)

	player.CharacterAdded:Connect(function(character)
		self:_bind(character)
	end)
	if player.Character then
		self:_bind(player.Character)
	end

	self:_bindInput()

	RunService.RenderStepped:Connect(function(deltaTime)
		self:_update(deltaTime)
	end)

	state.changed:connect(function()
		self:_syncFlyingState()
	end)

	return self
end

function FlightController._bind(self, character: Model)
	self.character = character
	self.root = character:WaitForChild("HumanoidRootPart") :: BasePart
	self.humanoid = character:WaitForChild("Humanoid") :: Humanoid
	self.flying = false
end

function FlightController._bindInput(self)
	local function handle(field: string)
		return function(_action, inputState)
			self[field] = if inputState == Enum.UserInputState.Begin then 1 else 0
			return Enum.ContextActionResult.Pass
		end
	end

	ContextActionService:BindAction(CLIMB_ACTION, handle("climb"), true, Enum.KeyCode.Space)
	ContextActionService:BindAction(DIVE_ACTION, handle("dive"), true, Enum.KeyCode.LeftShift)
	ContextActionService:SetTitle(CLIMB_ACTION, "▲")
	ContextActionService:SetTitle(DIVE_ACTION, "▼")
end

--[[ Enters or leaves flight mode following the server. ]]
function FlightController._syncFlyingState(self)
	local shouldFly = self.state:flag("Flying")
	if shouldFly == self.flying or not self.humanoid then
		return
	end

	self.flying = shouldFly
	self.humanoid.PlatformStand = shouldFly

	if not shouldFly and self.root then
		self.root.AssemblyLinearVelocity = Vector3.zero
	end
end

function FlightController._update(self, deltaTime: number)
	if not self.flying or not self.root or not self.root.Parent then
		return
	end

	local character = self.character
	local velocity = character:GetAttribute("FlightVelocity") or self.state:get("Velocity")
	local agility = character:GetAttribute("FlightAgility") or self.state:get("Agility")
	if velocity <= 0 then
		return
	end

	local heading = self.root.CFrame.LookVector

	-- MoveDirection is horizontal; the vertical axis comes from climb and dive.
	local steer = self.humanoid.MoveDirection + Vector3.new(0, (self.climb - self.dive) * VERTICAL_WEIGHT, 0)

	if steer.Magnitude > 0.05 then
		local blend = math.clamp(agility * deltaTime, 0, 1)
		heading = heading:Lerp(steer.Unit, blend)
		if heading.Magnitude > 0 then
			heading = heading.Unit
		end
	end

	-- Clamp the pitch: a vertical dragon reads as a bug, not as a dive.
	heading = Vector3.new(heading.X, math.clamp(heading.Y, MIN_PITCH, MAX_PITCH), heading.Z).Unit

	self.root.CFrame = CFrame.lookAt(self.root.Position, self.root.Position + heading)
	-- Setting the velocity every frame is also what cancels gravity.
	self.root.AssemblyLinearVelocity = heading * velocity
end

return FlightController
