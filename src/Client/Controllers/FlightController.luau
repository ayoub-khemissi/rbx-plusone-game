--!strict
--[[
	FlightController — arcade flight.

	The dragon is steered by the client because a client-owned body is the only way
	to get a responsive feel on Roblox. But the client decides only the DIRECTION:
	the velocity and turn rate come from the server, written on the character, and
	the server re-measures the resulting displacement. Tampering with this file
	changes how it feels, never what it earns.

	Steering reads the PlayerModule control vector rather than `Humanoid.MoveDirection`.
	That matters: flight sets `PlatformStand`, which stops the humanoid from moving,
	and MoveDirection then reports zero — the input channel would be dead. Reading the
	raw control vector keeps one code path for keyboard, gamepad and touch thumbstick.

	The steering model is "point and go": the dragon turns towards where the camera
	looks while you hold forward. It is the scheme players already know from every
	flying game, and it needs no extra buttons on mobile.
]]

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local FlightController = {}
FlightController.__index = FlightController

local CLIMB_ACTION = "DragonClimb"
local DIVE_ACTION = "DragonDive"
local VERTICAL_WEIGHT = 0.9
local MIN_PITCH = -0.85
local MAX_PITCH = 0.85
local INPUT_DEADZONE = 0.05

function FlightController.new(player: Player, state)
	local self = setmetatable({
		player = player,
		state = state,
		climb = 0,
		dive = 0,
		flying = false,
	}, FlightController)

	self:_bindControls()

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

--[[ The PlayerModule owns the raw input vector, whatever the device. ]]
function FlightController._bindControls(self)
	local ok, controls = pcall(function()
		local playerScripts = self.player:WaitForChild("PlayerScripts")
		return require(playerScripts:WaitForChild("PlayerModule")):GetControls()
	end)

	self.controls = if ok then controls else nil
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

	-- `true` asks Roblox for an on-screen button, so touch devices are covered.
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

--[[
	Turns the raw control vector into a world direction.

	The forward axis follows the camera in full 3D, so looking down dives and looking
	up climbs; the climb and dive buttons only add to it.
]]
function FlightController._steerDirection(self): Vector3
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.zero
	end

	local raw = if self.controls then self.controls:GetMoveVector() else Vector3.zero
	local direction = Vector3.zero

	-- GetMoveVector uses -Z as forward.
	if math.abs(raw.Z) > INPUT_DEADZONE then
		direction += camera.CFrame.LookVector * -raw.Z
	end
	if math.abs(raw.X) > INPUT_DEADZONE then
		direction += camera.CFrame.RightVector * raw.X
	end

	local vertical = self.climb - self.dive
	if vertical ~= 0 then
		direction += Vector3.new(0, vertical * VERTICAL_WEIGHT, 0)
	end

	return direction
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
	local steer = self:_steerDirection()

	if steer.Magnitude > INPUT_DEADZONE then
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
