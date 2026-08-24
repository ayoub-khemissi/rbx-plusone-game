--!strict
--[[
	SpeedGateController — makes a SpeedGate passable as soon as the player is fast
	enough, locally and instantly.

	Doing it client side removes any latency from a barrier the player runs into at
	full speed. It is safe because the server decides separately: entering a Stage is
	validated when the checkpoint behind the gate is touched, so forcing a gate open
	leads nowhere.
]]

local CollectionService = game:GetService("CollectionService")

local GATE_TAG = "SpeedGate"
local UNLOCKED_TRANSPARENCY = 0.75

local SpeedGateController = {}
SpeedGateController.__index = SpeedGateController

function SpeedGateController.new(state)
	local self = setmetatable({ state = state, gates = {} }, SpeedGateController)

	local function track(instance: Instance)
		if instance:IsA("BasePart") then
			-- Remember how the map author set the gate up, to restore it later.
			table.insert(self.gates, {
				part = instance,
				transparency = instance.Transparency,
				required = instance:GetAttribute("RequiredSpeed") or 0,
			})
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

	return self
end

function SpeedGateController.render(self)
	local speed = self.state:get("Speed")

	for _, gate in self.gates do
		if gate.part.Parent then
			local unlocked = speed >= gate.required
			gate.part.CanCollide = not unlocked
			gate.part.Transparency = if unlocked then UNLOCKED_TRANSPARENCY else gate.transparency
		end
	end
end

return SpeedGateController
