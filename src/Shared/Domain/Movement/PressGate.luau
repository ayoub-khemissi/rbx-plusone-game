--!strict
--[[
	PressGate — tells a NEW press apart from a held one.

	`UserInputService.JumpRequest` does not fire once per press. It repeats for as
	long as the input is held, and Roblox has no matching "jump released". So a
	single press on the ground produces a stream: the first event arrives while the
	character is still standing and is ignored, and the next one — a frame later,
	from the same uninterrupted press — arrives mid-jump and spends an air jump the
	player never asked for. One press, two jumps.

	The stream carries the answer. A held input arrives every frame; a genuine
	second press cannot, because a hand has to release and press again. A gap in the
	stream is therefore a new press, and no gap is the same one still going.

	Every event must be OFFERED to the gate, including the ones the caller then
	throws away. A held stream that is only partly reported grows a gap it never
	had, and the bug comes straight back.

	This lives in the domain because it is a rule about timestamps, not about
	Roblox: it can be tested at whatever instants a test likes, which the event
	itself never could.
]]

export type State = { lastAt: number }

local PressGate = {}
PressGate.__index = PressGate

export type PressGate = typeof(setmetatable({} :: { window: number }, PressGate))

--[[
	`window` is the longest gap still counted as one held press. It sits above a
	frame and below a human double tap: too short lets a held key through, too long
	swallows a deliberate second press.
]]
function PressGate.new(window: number): PressGate
	return setmetatable({ window = window }, PressGate)
end

function PressGate.newState(): State
	return { lastAt = -math.huge }
end

--[[ Records an event and answers whether it opens a new press. ]]
function PressGate.offer(self: PressGate, state: State, now: number): boolean
	local gap = now - state.lastAt
	state.lastAt = now
	return gap > self.window
end

return PressGate
