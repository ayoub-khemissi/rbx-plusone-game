--!nocheck
local PressGate = require(Domain.Movement.PressGate)

local WINDOW = 0.1
local FRAME = 1 / 60

describe("PressGate", function()
	local gate, state
	beforeEach(function()
		gate = PressGate.new(WINDOW)
		state = PressGate.newState()
	end)

	it("opens on the very first event", function()
		expect(gate:offer(state, 0)).toBe(true)
	end)

	--[[
		The bug this exists for. A press held from the ground repeats every frame:
		the first event arrives while standing and is discarded, the next arrives
		mid-jump. Without the gate that second one spends an air jump, and a single
		press costs two.
	]]
	it("stays shut for a press held across frames", function()
		expect(gate:offer(state, 0)).toBe(true)
		for frame = 1, 120 do
			expect(gate:offer(state, frame * FRAME)).toBe(false)
		end
	end)

	it("opens again once the input has been released", function()
		gate:offer(state, 0)
		expect(gate:offer(state, WINDOW + 0.01)).toBe(true)
	end)

	it("keeps a deliberate double tap intact", function()
		expect(gate:offer(state, 0)).toBe(true)
		expect(gate:offer(state, 0.15)).toBe(true)
		expect(gate:offer(state, 0.3)).toBe(true)
	end)

	--[[
		Every event has to be offered, even one the caller discards. Reporting only
		the airborne half of a held stream leaves a gap that was never there, and
		the original bug walks back in.
	]]
	it("counts an event the caller went on to ignore", function()
		expect(gate:offer(state, 0)).toBe(true)
		expect(gate:offer(state, FRAME)).toBe(false)
		expect(gate:offer(state, 2 * FRAME)).toBe(false)
	end)

	it("holds two states apart", function()
		local other = PressGate.newState()
		gate:offer(state, 0)
		expect(gate:offer(other, 0)).toBe(true)
	end)
end)
