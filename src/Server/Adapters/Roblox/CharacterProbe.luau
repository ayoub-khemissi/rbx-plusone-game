--!strict
--[[
	CharacterProbe — lecture de l'etat physique reel d'un personnage.

	Convertit les types Roblox (Vector3) en donnees pures ({x, y, z}) attendues par
	le domaine : la frontiere Roblox / metier passe par ici.
]]

local CharacterProbe = {}

export type Reading = {
	position: { x: number, y: number, z: number },
	walkSpeed: number,
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
		walkSpeed = humanoid.WalkSpeed,
		grounded = humanoid.FloorMaterial ~= Enum.Material.Air,
	}
end

return CharacterProbe
