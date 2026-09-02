--!strict
--[[
	TreadmillController — makes a character standing still look like it is running.

	A belt pays for running on the spot, and without this the player sees nothing
	happen at all: the number climbs somewhere off to the side while the avatar
	stands there. The animation IS the feedback.

	IT BORROWS ROBLOX'S OWN RUN ANIMATION rather than shipping one. The default
	`Animate` script already holds the id for whatever rig and avatar type the player
	turned up with, so reading it there covers R6, R15 and every future variant, and
	needs no asset owned by anybody. A published animation of our own would also have
	to be owned by the place, which is a trap this project has already fallen into
	once.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TreadmillController = {}
TreadmillController.__index = TreadmillController

local FADE = 0.2
-- How fast a belt's grain travels, in studs a second. Slower than the run
-- animation's feet, so it reads as a belt under them rather than a floor sliding.
local BELT_SPEED = 3

--[[
	THE BELTS MOVE, on every client, whether anybody stands on them or not.

	A belt whose surface is still is a black rectangle; a moving grain is what says
	"this is a machine" from across the lobby. It is a texture offset, one per belt,
	advanced on the render step — no part moves, nothing replicates, and seven
	belts cost seven property writes a frame.

	The map declares a belt by tagging it and naming its grain `Belt`; a treadmill
	without one simply does not move, which is what a builder gets from tagging a
	flat pad.
]]
local function scrollBelts()
	local grains: { Texture } = {}

	local function collect(instance: Instance)
		for _, descendant in instance:GetDescendants() do
			if descendant:IsA("Texture") and descendant.Name == "Belt" then
				table.insert(grains, descendant)
			end
		end
	end

	local function collectAround(instance: Instance)
		collect(instance)
		-- The tag sits on the base; the grain sits on the belt beside it.
		if instance.Parent and instance.Parent:IsA("Model") then
			collect(instance.Parent)
		end
	end

	for _, instance in CollectionService:GetTagged("Treadmill") do
		collectAround(instance)
	end
	CollectionService:GetInstanceAddedSignal("Treadmill"):Connect(collectAround)

	RunService.RenderStepped:Connect(function(deltaTime)
		for _, grain in grains do
			if grain.Parent then
				grain.OffsetStudsV = (grain.OffsetStudsV + BELT_SPEED * deltaTime) % grain.StudsPerTileV
			end
		end
	end)
end

function TreadmillController.new(player: Player)
	local self = setmetatable({ player = player }, TreadmillController)

	scrollBelts()

	player.CharacterAdded:Connect(function(character)
		self:_bind(character)
	end)
	if player.Character then
		self:_bind(player.Character)
	end

	return self
end

--[[ The id Roblox loaded for this avatar, whatever rig it turned out to be. ]]
local function runAnimationId(character: Model): string?
	local animate = character:FindFirstChild("Animate")
	local run = animate and animate:FindFirstChild("run")
	local animation = run and run:FindFirstChildOfClass("Animation")

	return animation and animation.AnimationId
end

function TreadmillController._bind(_self, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end

	local animator = humanoid:WaitForChild("Animator", 10) :: Animator?
	local id = runAnimationId(character)
	if not animator or not id then
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Movement
	track.Looped = true

	local function update()
		local onBelt = (character:GetAttribute("Treadmill") or 0) > 0
		-- Only while standing: a player walking across a belt is already animated
		-- by Roblox, and playing a second run on top of it makes the legs stutter.
		local standing = humanoid.MoveDirection.Magnitude < 0.1

		if onBelt and standing then
			if not track.IsPlaying then
				track:Play(FADE)
			end
		elseif track.IsPlaying then
			track:Stop(FADE)
		end
	end

	character:GetAttributeChangedSignal("Treadmill"):Connect(update)
	humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(update)
	update()
end

return TreadmillController
