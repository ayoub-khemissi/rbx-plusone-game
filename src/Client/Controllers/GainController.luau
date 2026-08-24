--!strict
--[[
	GainController — throws a number off the player every time they earn.

	WHY IT ACCUMULATES. The server credits progress on every sampling tick, and one
	tick is worth a fraction of a point. Popping a label per tick would spray "+0"
	five times a second, which is noise pretending to be feedback. The gain is
	summed instead and thrown as a whole number, so every popup says something true
	and worth reading.

	WHY IT ALSO WAITS. Even whole numbers arrive faster than an eye can follow once
	the character is quick. A minimum interval keeps them legible, and the amount
	simply grows to cover the wait — the total is the same, told in fewer, larger
	pieces.

	A drop is never shown. Progress falls on a prestige, and "-14 000" is not a
	thing anybody wants thrown at them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local GainController = {}
GainController.__index = GainController

local MINIMUM_INTERVAL = 0.35
local LABEL = Config.Theme.labels.level

function GainController.new(state, popups)
	local self = setmetatable({
		state = state,
		popups = popups,
		last = state:get("Speed"),
		pending = 0,
		lastShownAt = 0,
	}, GainController)

	state.changed:connect(function()
		self:_onChanged()
	end)

	return self
end

function GainController._onChanged(self)
	local speed = self.state:get("Speed")
	local delta = speed - self.last
	self.last = speed

	if delta <= 0 then
		-- A prestige reset, not a loss to announce.
		self.pending = 0
		return
	end

	self.pending += delta

	local now = os.clock()
	if self.pending < 1 or now - self.lastShownAt < MINIMUM_INTERVAL then
		return
	end

	local amount = math.floor(self.pending)
	self.pending -= amount
	self.lastShownAt = now

	self.popups:spawn(`+{amount}`, LABEL.image)
end

return GainController
