--!strict
--[[
	WallRunController — course sur les murs, saut mural et elan aerien.

	Ces mouvements sont simules cote CLIENT (le personnage appartient au client sur
	Roblox) : c'est ce qui rend le controle nerveux et sans latence. Aucun gain n'en
	depend directement — le serveur ne credite que la distance reellement parcourue,
	donc un joueur qui bidouillerait ce module ne gagnerait rien de plus.

	Duree d'accroche = base + amelioration "Griffes Adherentes" + bonus VIP.
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local WallRunController = {}
WallRunController.__index = WallRunController

local CHECK_DISTANCE = 3.8
local MIN_HORIZONTAL_SPEED = 10
local BASE_GRIP = 1.2
local INITIAL_LIFT = 6
local LIFT_DECAY = 26
local WALL_JUMP_UP = 58
local WALL_JUMP_AWAY = 46
local SAME_WALL_COOLDOWN = 0.35
local DASH_SPEED = 70
local DASH_KEY = Enum.KeyCode.Q

function WallRunController.new(player: Player, state)
	local self = setmetatable({
		player = player,
		state = state,
		running = nil,
		lastWall = nil,
		lastWallAt = 0,
		dashesLeft = 0,
	}, WallRunController)

	self.rayParams = RaycastParams.new()
	self.rayParams.FilterType = Enum.RaycastFilterType.Exclude

	player.CharacterAdded:Connect(function(character)
		self:_bindCharacter(character)
	end)
	if player.Character then
		self:_bindCharacter(player.Character)
	end

	UserInputService.JumpRequest:Connect(function()
		self:_onJumpRequest()
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == DASH_KEY then
			self:_dash()
		end
	end)

	RunService.RenderStepped:Connect(function(deltaTime)
		self:_update(deltaTime)
	end)

	return self
end

function WallRunController._bindCharacter(self, character: Model)
	self.character = character
	self.root = character:WaitForChild("HumanoidRootPart") :: BasePart
	self.humanoid = character:WaitForChild("Humanoid") :: Humanoid
	self.rayParams.FilterDescendantsInstances = { character }
	self.running = nil
	self.dashesLeft = 0

	self.humanoid.StateChanged:Connect(function(_old, new)
		if new == Enum.HumanoidStateType.Landed then
			self.dashesLeft = self.state:get("AirDash")
		end
	end)
end

function WallRunController._gripDuration(self): number
	return BASE_GRIP + self.state:get("WallGrip")
end

--[[ Cherche un mur a gauche ou a droite ; renvoie le cote et le resultat du rayon. ]]
function WallRunController._findWall(self)
	local origin = self.root.Position
	local right = self.root.CFrame.RightVector

	for _, side in { -1, 1 } do
		local result = workspace:Raycast(origin, right * side * CHECK_DISTANCE, self.rayParams)
		if result and result.Instance and result.Instance.CanCollide then
			return side, result
		end
	end

	return nil, nil
end

function WallRunController._start(self, side: number, result: RaycastResult)
	local now = os.clock()
	-- Empeche de remonter indefiniment le meme mur en enchainant les accroches.
	if self.lastWall == result.Instance and now - self.lastWallAt < SAME_WALL_COOLDOWN then
		return
	end

	self.running = {
		side = side,
		normal = result.Normal,
		startedAt = now,
		lift = INITIAL_LIFT,
	}
	self.lastWall = result.Instance
	self.lastWallAt = now
	self.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
end

function WallRunController._stop(self)
	if self.running then
		self.lastWallAt = os.clock()
	end
	self.running = nil
end

function WallRunController._update(self, deltaTime: number)
	local root, humanoid = self.root, self.humanoid
	if not root or not humanoid or not root.Parent or humanoid.Health <= 0 then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z)

	if self.running then
		local elapsed = os.clock() - self.running.startedAt
		local _, result = self:_findWall()

		if elapsed > self:_gripDuration() or not result or humanoid.FloorMaterial ~= Enum.Material.Air then
			self:_stop()
			return
		end

		-- Direction le long du mur, dans le sens du regard.
		local along = self.running.normal:Cross(Vector3.yAxis)
		if along:Dot(root.CFrame.LookVector) < 0 then
			along = -along
		end

		self.running.lift -= LIFT_DECAY * deltaTime
		local speed = math.max(horizontal.Magnitude, humanoid.WalkSpeed * 0.9)
		root.AssemblyLinearVelocity = along * speed + Vector3.new(0, self.running.lift, 0)
		return
	end

	if humanoid.FloorMaterial ~= Enum.Material.Air or horizontal.Magnitude < MIN_HORIZONTAL_SPEED then
		return
	end

	local side, result = self:_findWall()
	if side and result then
		self:_start(side, result)
	end
end

function WallRunController._onJumpRequest(self)
	if not self.running or not self.root then
		return
	end

	local normal = self.running.normal
	local forward = self.root.CFrame.LookVector
	self:_stop()

	self.root.AssemblyLinearVelocity = normal * WALL_JUMP_AWAY
		+ Vector3.new(0, WALL_JUMP_UP, 0)
		+ Vector3.new(forward.X, 0, forward.Z) * 12
end

--[[ Elan aerien : debloque par l'amelioration "Elan Aerien". ]]
function WallRunController._dash(self)
	if not self.root or not self.humanoid then
		return
	end
	if self.humanoid.FloorMaterial ~= Enum.Material.Air or self.dashesLeft <= 0 then
		return
	end

	self.dashesLeft -= 1
	local direction = self.root.CFrame.LookVector
	self.root.AssemblyLinearVelocity = Vector3.new(direction.X, 0, direction.Z).Unit
			* (self.humanoid.WalkSpeed + DASH_SPEED)
		+ Vector3.new(0, 12, 0)
end

return WallRunController
