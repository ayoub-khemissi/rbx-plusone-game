--!strict
--[[
	CharacterBody — the Body port: what the server does to the player's character.

	Two things, and they belong together: put it somewhere, or end it. A fall does
	both, one after the other.
]]

local CharacterBody = {}
CharacterBody.__index = CharacterBody

function CharacterBody.new()
	return setmetatable({}, CharacterBody)
end

function CharacterBody.sendTo(_self, player: Player, position: { x: number, y: number, z: number })
	local character = player.Character
	if not character or not position then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	-- Face the player down the course rather than wherever they fell from.
	root.CFrame = CFrame.lookAt(
		Vector3.new(position.x, position.y + 3, position.z),
		Vector3.new(position.x + 10, position.y + 3, position.z)
	)
	root.AssemblyLinearVelocity = Vector3.zero
end

--[[
	Kills the character. Roblox brings a new one back on its own, after the delay
	the server set, and the return is handled where every new body is handled.

	Health rather than :Destroy(): a death runs the animation, drops the camera and
	fires everything a death is supposed to fire. Removing the character would look
	like a bug in the game rather than a fall in it.
]]
function CharacterBody.kill(_self, player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

return CharacterBody
