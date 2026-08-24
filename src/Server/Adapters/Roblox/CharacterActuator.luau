--!strict
--[[
	CharacterActuator — port MovementActuator: applies the movement state to the
	character.

	Walk speed and jump power go on the Humanoid, which is what Roblox actually
	moves. The rest — jump level, dash power, magnet range — goes on the character as
	attributes, because the client controller reads them locally without waiting for a
	snapshot round trip.

	The character is the only thing the server writes: the client never decides how
	fast it goes.
]]

local CharacterActuator = {}
CharacterActuator.__index = CharacterActuator

function CharacterActuator.new()
	return setmetatable({}, CharacterActuator)
end

local function setIfChanged(instance: Instance, name: string, value: any)
	if instance:GetAttribute(name) ~= value then
		instance:SetAttribute(name, value)
	end
end

function CharacterActuator.apply(_self, player: Player, movement: any)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = movement.walkSpeed
		humanoid.UseJumpPower = true
		humanoid.JumpPower = movement.jumpPower
	end

	setIfChanged(character, "JumpLevel", movement.jumpLevel)
	setIfChanged(character, "JumpPower", movement.jumpPower)
	setIfChanged(character, "DashLevel", movement.dashLevel)
	setIfChanged(character, "DashPower", movement.dashPower)
	setIfChanged(character, "Magnet", movement.magnet)
end

return CharacterActuator
