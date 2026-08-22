--!strict
--[[ CharacterTeleporter — port Teleporter : deplace le personnage du joueur. ]]

local CharacterTeleporter = {}
CharacterTeleporter.__index = CharacterTeleporter

function CharacterTeleporter.new()
	return setmetatable({}, CharacterTeleporter)
end

function CharacterTeleporter.sendTo(_self, player: Player, position: { x: number, y: number, z: number })
	local character = player.Character
	if not character or not position then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	-- On oriente le joueur vers la suite de la piste (axe +X).
	root.CFrame = CFrame.lookAt(
		Vector3.new(position.x, position.y + 3, position.z),
		Vector3.new(position.x + 10, position.y + 3, position.z)
	)
	root.AssemblyLinearVelocity = Vector3.zero
end

return CharacterTeleporter
