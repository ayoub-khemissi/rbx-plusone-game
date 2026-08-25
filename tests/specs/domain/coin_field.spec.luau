--!nocheck
local CoinField = require(Domain.Run.CoinField)

local RESPAWN = 30

describe("CoinField", function()
	local state
	beforeEach(function()
		state = CoinField.newState()
	end)

	it("hands over a coin nobody has taken", function()
		expect(CoinField.claim(state, "a", 0, RESPAWN)).toBe(true)
	end)

	--[[
		The client asks the moment a coin comes within reach, and asks again on the
		next tick while the first answer is still travelling. Without this the coin
		pays for every tick it spends flying towards the player.
	]]
	it("refuses the same coin until it has come back", function()
		CoinField.claim(state, "a", 0, RESPAWN)

		expect(CoinField.claim(state, "a", 0.1, RESPAWN)).toBe(false)
		expect(CoinField.claim(state, "a", RESPAWN - 0.1, RESPAWN)).toBe(false)
		expect(CoinField.claim(state, "a", RESPAWN, RESPAWN)).toBe(true)
	end)

	it("keeps one coin's window out of another's", function()
		CoinField.claim(state, "a", 0, RESPAWN)
		expect(CoinField.claim(state, "b", 0, RESPAWN)).toBe(true)
	end)

	--[[
		Two players on the same course hold two fields, which is the whole point:
		what one of them collects is still there for the other.
	]]
	it("empties per player, not per coin", function()
		local other = CoinField.newState()
		CoinField.claim(state, "a", 0, RESPAWN)

		expect(CoinField.claim(other, "a", 0, RESPAWN)).toBe(true)
	end)

	it("puts the whole course back when cleared", function()
		CoinField.claim(state, "a", 0, RESPAWN)
		CoinField.claim(state, "b", 0, RESPAWN)
		CoinField.clear(state)

		expect(CoinField.claim(state, "a", 1, RESPAWN)).toBe(true)
		expect(CoinField.claim(state, "b", 1, RESPAWN)).toBe(true)
	end)
end)
