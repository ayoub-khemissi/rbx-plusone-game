--!strict
--[[
	GainController — throws a number off the player every time they earn.

	WHY IT ACCUMULATES. The server credits progress on every sampling tick, and one
	tick is worth a fraction of a point. Popping a label per tick would spray "+0"
	five times a second, which is noise pretending to be feedback. The gain is
	summed instead and thrown as a whole number, so every popup says something true
	and worth reading.

	WHY IT ALSO WAITS. Even whole numbers arrive faster than an eye can follow once
	the character is quick. A fixed interval keeps them legible, and the amount
	simply grows to cover the wait — the total is the same, told in fewer, larger
	pieces.

	WHY THE CADENCE IS FIXED RATHER THAN CONDITIONAL. Waiting for the accumulator to
	pass a whole point before showing anything makes the popups ragged at low speed:
	a tick is worth 0.8 at the starting pace, so one tick shows nothing, the next
	shows "+1", and the rhythm limps. Every interval now produces exactly one popup,
	rounded, with the remainder carried — which lets a remainder go briefly negative
	and corrects itself on the following one.

	A drop is never shown. Progress falls on a prestige, and "-14 000" is not a
	thing anybody wants thrown at them.

	Nothing appears while standing still, and that is not a fault: only horizontal
	movement earns. Jumping on the spot pays nothing, by the same rule that stops a
	player farming progress without running.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local GainController = {}
GainController.__index = GainController

local INTERVAL = 0.3
-- Below this the interval simply passes: a remainder this small is a rounding
-- artefact, not a gain worth announcing.
local MINIMUM_GAIN = 0.5
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
	if now - self.lastShownAt < INTERVAL or self.pending < MINIMUM_GAIN then
		return
	end

	-- At least one: an interval that earned something has something to say, and
	-- "+0" says nothing. The remainder carries, so nothing is invented over time.
	local amount = math.max(math.round(self.pending), 1)
	self.pending -= amount
	self.lastShownAt = now

	self.popups:spawn(`+{amount}`, LABEL.image)
end

return GainController
