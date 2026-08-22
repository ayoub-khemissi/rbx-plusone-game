--!strict
--[[
	HumanoidActuator — port MovementActuator : applique l'etat de mouvement calcule
	par le domaine sur le Humanoid.

	Le personnage est la seule chose que le serveur "ecrit" : la vitesse n'est jamais
	decidee par le client.
]]

local HumanoidActuator = {}
HumanoidActuator.__index = HumanoidActuator

function HumanoidActuator.new(stunPenalty: number)
	return setmetatable({ stunPenalty = stunPenalty or 0.45 }, HumanoidActuator)
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

function HumanoidActuator.apply(self, player: Player, movement: any)
	local humanoid = humanoidOf(player)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Penalite temporaire posee par les obstacles (voir WorldBuilder).
	local stunnedUntil = player:GetAttribute("StunnedUntil")
	local penalty = if typeof(stunnedUntil) == "number" and os.clock() < stunnedUntil
		then self.stunPenalty
		else 1

	humanoid.WalkSpeed = movement.walkSpeed * penalty
	humanoid.UseJumpPower = true
	humanoid.JumpPower = movement.jumpPower
end

return HumanoidActuator
