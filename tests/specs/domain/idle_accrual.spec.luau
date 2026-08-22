--!nocheck
local IdleAccrual = require(Domain.Progression.IdleAccrual)

local TUNING = {
	bananasPerMinute = 600,
	payoutInterval = 60,
	sessionCapSeconds = 180,
	station = { x = 10, z = -10, radius = 20 },
}

describe("IdleAccrual (zone AFK)", function()
	local accrual, idle
	beforeEach(function()
		accrual = IdleAccrual.new(TUNING)
		idle = IdleAccrual.newState()
	end)

	it("reconnait les joueurs presents dans la zone", function()
		expect(accrual:covers({ x = 12, y = 5, z = -12 })).toBe(true)
		expect(accrual:covers({ x = 200, y = 5, z = 0 })).toBe(true == false)
	end)

	it("ignore la hauteur : rester au-dessus du pad suffit", function()
		expect(accrual:covers({ x = 10, y = 80, z = -10 })).toBe(true)
	end)

	it("ne paie rien avant la fin de l'intervalle", function()
		local outcome = accrual:accumulate(idle, 59)
		expect(outcome.payouts).toBe(0)
		expect(outcome.bananas).toBe(0)
	end)

	it("paie a chaque intervalle complet", function()
		local outcome = accrual:accumulate(idle, 60)
		expect(outcome.payouts).toBe(1)
		expect(outcome.bananas).toBe(600)
	end)

	it("rattrape plusieurs intervalles d'un coup", function()
		local outcome = accrual:accumulate(idle, 125)
		expect(outcome.payouts).toBe(2)
		expect(outcome.bananas).toBe(1200)
		-- les 5 secondes restantes ne sont pas perdues
		expect(accrual:accumulate(idle, 55).payouts).toBe(1)
	end)

	it("plafonne le temps credite sur une session", function()
		accrual:accumulate(idle, 180)
		local outcome = accrual:accumulate(idle, 600)
		expect(outcome.payouts).toBe(0)
		expect(outcome.capped).toBe(true)
	end)

	it("perd la progression partielle quand le joueur quitte la zone", function()
		accrual:accumulate(idle, 45)
		accrual:reset(idle)
		expect(accrual:accumulate(idle, 30).payouts).toBe(0)
	end)

	it("conserve le compteur de plafond apres une sortie de zone", function()
		accrual:accumulate(idle, 120)
		accrual:reset(idle)
		accrual:accumulate(idle, 120)
		expect(idle.creditedSeconds).toBe(180)
	end)

	it("expose le temps restant avant le plafond", function()
		accrual:accumulate(idle, 60)
		expect(accrual:remainingFor(idle)).toBe(120)
	end)

	it("ignore les pas de temps absurdes", function()
		expect(accrual:accumulate(idle, -10).payouts).toBe(0)
		expect(accrual:accumulate(idle, 0 / 0).payouts).toBe(0)
	end)
end)
