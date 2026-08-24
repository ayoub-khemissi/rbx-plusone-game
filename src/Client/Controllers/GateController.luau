--!strict
--[[
	GateController — colours the wind barriers according to what the player can pass.

	Purely cosmetic, and deliberately so: the server decides who goes through
	(SampleFlight pushes back anyone too slow), so tampering with this file changes
	the colour of a ring and nothing else.
]]

local CollectionService = game:GetService("CollectionService")

local GATE_TAG = "Gate"
local UNLOCKED = Color3.fromRGB(120, 214, 150)
local LOCKED = Color3.fromRGB(214, 78, 74)

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

	return self
end

function GateController.render(self)
	local speed = self.state:get("Speed")

	for _, sensor in self.gates do
		if sensor.Parent then
			local required = sensor:GetAttribute("RequiredSpeed") or 0
			local color = if speed >= required then UNLOCKED else LOCKED

			-- The sensor is invisible; the ring around it is what the player sees.
			for _, segment in sensor.Parent:GetChildren() do
				if segment:IsA("BasePart") and segment.Name == "Segment" then
					segment.Color = color
				end
			end
		end
	end
end

return GateController
