--!strict
--[[
	Stages — what each Stage of a course costs to enter and what it pays.

	The MAP decides where a Stage begins: a Checkpoint tagged with `StageId = 3`
	belongs to Stage 3. This file only decides the balance.

	Adding a Stage to a map means adding a line here. Nothing else.

	`requiredSpeed` and `coinMultiplier` must both stay STRICTLY rising, which
	Domain.Run.StageLadder verifies at start-up.
]]

local StageLadder = require(script.Parent.Parent.Domain.Run.StageLadder)

type Stage = StageLadder.Stage

local stages: { Stage } = {
	{ id = 1, name = "Warm-up", requiredSpeed = 0, coinMultiplier = 1 },
	{ id = 2, name = "Ramp", requiredSpeed = 250, coinMultiplier = 1.6 },
	{ id = 3, name = "Climb", requiredSpeed = 1000, coinMultiplier = 2.4 },
	{ id = 4, name = "Gauntlet", requiredSpeed = 4000, coinMultiplier = 3.5 },
	{ id = 5, name = "Summit", requiredSpeed = 15000, coinMultiplier = 5 },
}

return table.freeze(stages)
