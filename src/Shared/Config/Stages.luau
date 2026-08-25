--!strict
--[[
	Stages — what each Stage of a world costs to enter and what it pays.

	A STAGE IS A SECTION OF THE MAP, ten to a world. It is not a level: a level is
	the rank experience buys, and the two are counted separately on purpose — "Stage
	3" says where you are, "Level 37" says how far you have come.

	A world is TEN of these. The MAP decides where one begins: a Checkpoint tagged
	`StageId = 3` belongs to Stage 3. This file only decides the balance.

	No stage carries a name. The word is the theme's — `labels.stage` — and a stage
	is announced as that word and its number, so renaming Stage to Zone renames all
	ten at once instead of editing this file.

	`requiredLevel` is what the gate ANNOUNCES, and it is the number the course was
	built for: the walk speed at that level is what clears its gaps. It is advisory
	on purpose — anyone may walk into a course early and try, and finding out the
	hard way is part of it.

	`requiredSpeed` is the same threshold expressed in experience, since that is what
	the ladder compares against. The two are two readings of one number.

	Both it and `coinMultiplier` must stay STRICTLY rising, which
	Domain.Run.StageLadder verifies at start-up.

	TWENTY LEVELS TO A STAGE, two hundred to a world. That regularity is the point:
	a player always knows how far the next gate is, and every world is built to the
	same ruler. Stage 10 opens at level 180 and the world tops out at 200, which is
	also where the seventh rebirth lands — so the loop covers the whole world rather
	than leaving the last stages for nobody.

	`requiredSpeed` is `requiredLevel` read through the level curve in Balance.
	Retuning that curve moves these, and the config spec fails when they stop
	agreeing.
]]

local StageLadder = require(script.Parent.Parent.Domain.Run.StageLadder)

type Stage = StageLadder.Stage

local stages: { Stage } = {
	{ id = 1, requiredLevel = 1, requiredSpeed = 0, coinMultiplier = 1 },
	{ id = 2, requiredLevel = 20, requiredSpeed = 6106, coinMultiplier = 1.3 },
	{ id = 3, requiredLevel = 40, requiredSpeed = 22791, coinMultiplier = 1.65 },
	{ id = 4, requiredLevel = 60, requiredSpeed = 49244, coinMultiplier = 2.1 },
	{ id = 5, requiredLevel = 80, requiredSpeed = 85062, coinMultiplier = 2.65 },
	{ id = 6, requiredLevel = 100, requiredSpeed = 129977, coinMultiplier = 3.35 },
	{ id = 7, requiredLevel = 120, requiredSpeed = 183785, coinMultiplier = 4.2 },
	{ id = 8, requiredLevel = 140, requiredSpeed = 246326, coinMultiplier = 5.3 },
	{ id = 9, requiredLevel = 160, requiredSpeed = 317464, coinMultiplier = 6.6 },
	{ id = 10, requiredLevel = 180, requiredSpeed = 397086, coinMultiplier = 8.3 },
}

return table.freeze(stages)
