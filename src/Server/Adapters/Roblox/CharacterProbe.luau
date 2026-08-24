--!strict
--[[
	CharacterProbe — reads the real physical state of a character.

	Converts Roblox types (Vector3) into the plain data the domain expects
	({x, y, z}): the Roblox / business boundary runs through here.
]]

local CharacterProbe = {}

export type Reading = {
	position: { x: number, y: number, z: number },
	velocity: number,
	grounded: boolean,
}

function CharacterProbe.read(player: Player): Reading?
	local character = player.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end

	local position = root.Position
	return {
		position = { x = position.X, y = position.Y, z = position.Z },
		-- Actual speed of the body, not the authorised one: that is the point.
		velocity = root.AssemblyLinearVelocity.Magnitude,
		grounded = humanoid.FloorMaterial ~= Enum.Material.Air,
	}
end

return CharacterProbe
