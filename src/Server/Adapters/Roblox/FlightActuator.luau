--!strict
--[[
	FlightActuator — port FlightActuator: hands the flight state to the character.

	The dragon is steered by the client, because a body owned by the client is the
	only way to get a responsive arcade feel. But the client does not decide HOW FAST
	it goes: the server writes the authorised velocity and turn rate onto the
	character, and re-measures the actual displacement afterwards.

	Writing on the character rather than the player is deliberate: the client
	controller reads them locally, without waiting for a snapshot round trip.
]]

local FlightActuator = {}
FlightActuator.__index = FlightActuator

function FlightActuator.new()
	return setmetatable({}, FlightActuator)
end

local function setIfChanged(instance: Instance, name: string, value: any)
	if instance:GetAttribute(name) ~= value then
		instance:SetAttribute(name, value)
	end
end

function FlightActuator.apply(_self, player: Player, flight: any)
	local character = player.Character
	if not character then
		return
	end

	setIfChanged(character, "FlightVelocity", flight.velocity)
	setIfChanged(character, "FlightAgility", flight.agility)
	setIfChanged(character, "FlightMagnet", flight.magnet)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- On the ground at the Nest the dragon walks; the value only matters there.
		humanoid.WalkSpeed = 24
	end
end

return FlightActuator
