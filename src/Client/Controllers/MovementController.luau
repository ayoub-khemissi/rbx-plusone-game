--!strict
--[[
	MovementController — the extra jumps and the dash.

	A DELIBERATE TRADE-OFF LIVES HERE. Asking the server for permission before every
	air jump would add a round trip to the most timing-critical input of a platformer,
	and a jump that answers 80 ms late feels broken. So the client PREDICTS: it applies
	the jump immediately from what the server wrote on the character, then tells the
	server, which keeps the authoritative count for the interface.

	That is safe because jumping pays nothing. Speed is credited from ground distance
	measured server side, and entering a locked Stage is refused at the checkpoint,
	server side too. A tampered client can jump more; it cannot earn more, and it
	cannot go anywhere its Speed has not already unlocked.

	The ground jump is left to Roblox: only the extra ones are ours.
]]

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local PressGate = require(Shared.Domain.Movement.PressGate)

local Flip = require(script.Parent.Parent.Flip)

local MovementController = {}
MovementController.__index = MovementController

local DASH_ACTION = "Dash"
local DASH_KEYS = { Enum.KeyCode.Q, Enum.KeyCode.LeftShift }
local DASH_LIFT = 8 -- a touch of lift, so a dash can save a jump that fell short
local DASH_DURATION = Config.Balance.dash.duration

-- Above one frame, below a human double tap. See PressGate for why this exists.
local JUMP_PRESS_WINDOW = 0.1

function MovementController.new(player: Player, state, remotes)
	local self = setmetatable({
		player = player,
		state = state,
		remotes = remotes,
		airJumpsUsed = 0,
		lastDashAt = -math.huge,
		jumpGate = PressGate.new(JUMP_PRESS_WINDOW),
		jumpPress = PressGate.newState(),
	}, MovementController)

	player.CharacterAdded:Connect(function(character)
		self:_bind(character)
	end)
	if player.Character then
		self:_bind(player.Character)
	end

	UserInputService.JumpRequest:Connect(function()
		self:_onJumpRequest()
	end)

	ContextActionService:BindAction(DASH_ACTION, function(_action, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_onDashRequest()
		end
		return Enum.ContextActionResult.Pass
	end, true, table.unpack(DASH_KEYS))
	ContextActionService:SetTitle(DASH_ACTION, "DASH")

	-- The server confirms and hands back the exact power to apply.
	remotes.events.JumpGranted.OnClientEvent:Connect(function(power)
		self:_applyJump(power)
		-- Only air jumps somersault. The first jump is the one everybody has, and
		-- flipping on it would turn ordinary walking into a circus act.
		if self.character then
			Flip.play(self.character)
		end
	end)
	remotes.events.DashGranted.OnClientEvent:Connect(function(power)
		self:_applyDash(power)
	end)

	return self
end

function MovementController._bind(self, character: Model)
	self.character = character
	self.root = character:WaitForChild("HumanoidRootPart") :: BasePart
	self.humanoid = character:WaitForChild("Humanoid") :: Humanoid
	self.airJumpsUsed = 0

	self.humanoid.StateChanged:Connect(function(_old, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			if self.airJumpsUsed > 0 then
				self.airJumpsUsed = 0
				self.remotes.events.Landed:FireServer()
			end
		end
	end)
end

function MovementController._airborne(self): boolean
	if not self.humanoid then
		return false
	end
	local state = self.humanoid:GetState()
	return state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
end

function MovementController._onJumpRequest(self)
	-- Offered FIRST, and unconditionally. JumpRequest repeats while the input is
	-- held, so the ground jump and the air jump arrive from the same press. Hiding
	-- the grounded events from the gate would open a gap that was never there.
	local newPress = self.jumpGate:offer(self.jumpPress, os.clock())

	if not newPress then
		return
	end

	if not self.character or not self:_airborne() then
		return -- the ground jump belongs to Roblox
	end

	-- JumpLevel is written by the server: level 1 has no air jump at all.
	local level = self.character:GetAttribute("JumpLevel") or 1
	if self.airJumpsUsed >= level - 1 then
		return
	end

	self.airJumpsUsed += 1
	self:_applyJump(self.character:GetAttribute("JumpPower") or self.humanoid.JumpPower)
	self.remotes.events.RequestJump:FireServer()
end

function MovementController._applyJump(self, power: number)
	if not self.root or typeof(power) ~= "number" then
		return
	end

	local velocity = self.root.AssemblyLinearVelocity
	-- Replace the vertical component instead of adding to it, so a second jump is
	-- always worth the same whether the character was rising or already falling.
	self.root.AssemblyLinearVelocity = Vector3.new(velocity.X, power, velocity.Z)
end

function MovementController._onDashRequest(self)
	if not self.character or not self.root then
		return
	end

	-- Owning the dash is what allows it; the power level only decides how hard.
	local power = self.character:GetAttribute("DashPower") or 0
	if self.character:GetAttribute("DashUnlocked") ~= true or power <= 0 then
		return
	end

	-- The local cooldown only avoids spamming the server; the real one is server side.
	local cooldown = self.state:get("DashCooldown")
	if cooldown > 0 or os.clock() - self.lastDashAt < 0.2 then
		return
	end

	self.lastDashAt = os.clock()
	self:_applyDash(power)
	self.remotes.events.RequestDash:FireServer()
end

function MovementController._applyDash(self, power: number)
	if not self.root or typeof(power) ~= "number" or power <= 0 then
		return
	end

	-- Dash where the player is heading, or where they are facing when standing still.
	local direction = self.humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = self.root.CFrame.LookVector
	end
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.1 then
		return
	end

	--[[
		HELD, not shoved.

		Writing the velocity once and walking away does almost nothing: the Humanoid
		steers the character back to its walk speed within two or three frames. The
		speed is therefore rewritten every frame for the length of the dash, which is
		what turns it into distance covered rather than a twitch.

		Only the horizontal components are held. Gravity keeps the vertical one, so a
		dash off a ledge still falls, and a dash mid-jump does not hang in the air.
	]]
	local unit = direction.Unit
	local until_ = os.clock() + DASH_DURATION
	local held: RBXScriptConnection

	self.root.AssemblyLinearVelocity =
		Vector3.new(unit.X * power, self.root.AssemblyLinearVelocity.Y + DASH_LIFT, unit.Z * power)

	held = RunService.Heartbeat:Connect(function()
		local root = self.root
		if os.clock() >= until_ or not root or not root.Parent then
			held:Disconnect()
			return
		end
		root.AssemblyLinearVelocity =
			Vector3.new(unit.X * power, root.AssemblyLinearVelocity.Y, unit.Z * power)
	end)
end

return MovementController
