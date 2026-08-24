--!strict
--[[
	Flip — a front somersault, in code rather than as an animation asset.

	WHY NOT AN ANIMATION. Roblox refuses to play an animation asset that the
	experience's creator does not own. Every "front flip" in the toolbox belongs to
	somebody else, and unlike an image there is no re-upload path: the animation
	data cannot be pulled back out of another account's asset. A catalogue id would
	load, fail silently, and leave the character jumping stiffly with nothing in the
	output to say why.

	So the rotation is driven here. It costs no asset, needs no moderation, works on
	both R6 and R15, and every part of it is tunable.

	WHAT ROTATES. The Motor6D joining the root to the torso, never the
	HumanoidRootPart itself. The root part IS the collision box: spinning it turns
	the character's hitbox end over end, which catches on ledges and wedges the
	player into geometry. Turning the joint spins what is SEEN and leaves the
	physics upright.

	The flip is cosmetic by construction. It cannot change where the character
	lands, and a player who lands mid-spin simply lands.
]]

local RunService = game:GetService("RunService")

local Flip = {}

local DURATION = 0.55
local TURNS = 1

--[[
	The joint that carries the whole upper body.

	R6 calls it RootJoint and hangs the Torso off it; R15 calls it Root and hangs
	the LowerTorso. Finding it by what it CONNECTS rather than by name covers both,
	and any custom rig built the same way.
]]
local function rootJoint(character: Model): Motor6D?
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	for _, descendant in root:GetChildren() do
		if descendant:IsA("Motor6D") and descendant.Part0 == root then
			return descendant
		end
	end

	return nil
end

--[[
	Spins the character forward once, and puts the joint back where it found it.

	Returns immediately if one is already running: a triple jump should not stack
	two rotations onto the same joint and leave it somewhere between them.
]]
function Flip.play(character: Model)
	local joint = rootJoint(character)
	if not joint or joint:GetAttribute("Flipping") then
		return
	end

	joint:SetAttribute("Flipping", true)

	local origin = joint.C0
	local elapsed = 0
	local connection: RBXScriptConnection

	local function restore()
		if connection then
			connection:Disconnect()
		end
		-- The joint may have gone with a respawn between two frames.
		if joint.Parent then
			joint.C0 = origin
			joint:SetAttribute("Flipping", nil)
		end
	end

	connection = RunService.RenderStepped:Connect(function(deltaTime)
		if not joint.Parent or not character.Parent then
			restore()
			return
		end

		elapsed += deltaTime
		if elapsed >= DURATION then
			restore()
			return
		end

		-- Eased so the spin leaves fast and settles, rather than turning at the
		-- constant rate of a rotisserie.
		local progress = elapsed / DURATION
		local eased = 1 - (1 - progress) ^ 3
		joint.C0 = origin * CFrame.Angles(math.rad(360 * TURNS * eased), 0, 0)
	end)
end

return Flip
