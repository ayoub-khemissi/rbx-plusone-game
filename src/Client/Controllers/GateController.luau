--!strict
--[[
	GateController — rend les barrieres traversables localement quand la vitesse
	requise est atteinte.

	La collision est desactivee CHEZ LE JOUEUR uniquement : c'est instantane et sans
	latence. La verification qui compte reste serveur (EnforceZoneAccess), donc
	desactiver ces collisions par la triche ne debloque rien : le joueur est renvoye.
]]

local CollectionService = game:GetService("CollectionService")

local GATE_TAG = "BarriereZone"
local UNLOCKED_COLOR = Color3.fromRGB(92, 206, 118)

local GateController = {}
GateController.__index = GateController

function GateController.new(state)
	local self = setmetatable({ state = state, gates = {} }, GateController)

	local function track(instance: Instance)
		if instance:IsA("BasePart") then
			table.insert(self.gates, instance)
			self:render()
		end
	end

	for _, gate in CollectionService:GetTagged(GATE_TAG) do
		track(gate)
	end
	CollectionService:GetInstanceAddedSignal(GATE_TAG):Connect(track)

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function GateController.render(self)
	local speed = self.state:get("Speed")

	for _, gate in self.gates do
		if gate.Parent then
			local required = gate:GetAttribute("RequiredSpeed") or 0
			local unlocked = speed >= required

			gate.CanCollide = not unlocked and required > 0
			gate.Color = if unlocked then UNLOCKED_COLOR else gate.Color
			gate.Transparency = if unlocked then 0.85 else 0.45
		end
	end
end

return GateController
