--!nocheck
local IdleAccrual = require(Domain.Idle.IdleAccrual)

local TUNING = { coinsPerMinute = 600, payoutInterval = 60, sessionCapSeconds = 180 }

describe("IdleAccrual", function()
	local idle, state
	beforeEach(function()
		idle = IdleAccrual.new(TUNING)
		state = IdleAccrual.newState()
	end)

	it("pays nothing before the interval is over", function()
		local outcome = idle:accumulate(state, 59)
		expect(outcome.payouts).toBe(0)
		expect(outcome.coins).toBe(0)
	end)

	it("pays on every completed interval", function()
		local outcome = idle:accumulate(state, 60)
		expect(outcome.payouts).toBe(1)
		expect(outcome.coins).toBe(600)
	end)

	it("catches up several intervals at once", function()
		local outcome = idle:accumulate(state, 125)
		expect(outcome.payouts).toBe(2)
		-- les 5 secondes restantes ne sont pas perdues
		expect(idle:accumulate(state, 55).payouts).toBe(1)
	end)

	it("caps the time credited over a session", function()
		idle:accumulate(state, 180)
		local outcome = idle:accumulate(state, 600)
		expect(outcome.payouts).toBe(0)
		expect(outcome.capped).toBe(true)
	end)

	it("loses the partial time when the player leaves the zone", function()
		idle:accumulate(state, 45)
		idle:reset(state)
		expect(idle:accumulate(state, 30).payouts).toBe(0)
	end)

	it("keeps the cap counter across a leave", function()
		idle:accumulate(state, 120)
		idle:reset(state)
		idle:accumulate(state, 120)
		expect(state.creditedSeconds).toBe(180)
	end)

	it("ignores nonsensical time steps", function()
		expect(idle:accumulate(state, -10).payouts).toBe(0)
		expect(idle:accumulate(state, 0 / 0).payouts).toBe(0)
	end)
end)
