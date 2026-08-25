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

	The levels are not guesses. They come from simulating uninterrupted play against
	the curve in Balance: course 2 at eight minutes, course 6 at an hour and twenty,
	course 10 at four and a half hours. Retuning the curve moves these, and the
	config spec fails when they stop agreeing.
]]

local StageLadder = require(script.Parent.Parent.Domain.Run.StageLadder)

type Stage = StageLadder.Stage

local stages: { Stage } = {
	{ id = 1, requiredLevel = 1, requiredSpeed = 0, coinMultiplier = 1 },
	{ id = 2, requiredLevel = 12, requiredSpeed = 2246, coinMultiplier = 1.3 },
	{ id = 3, requiredLevel = 22, requiredSpeed = 7106, coinMultiplier = 1.65 },
	{ id = 4, requiredLevel = 31, requiredSpeed = 13633, coinMultiplier = 2.1 },
	{ id = 5, requiredLevel = 43, requiredSpeed = 25387, coinMultiplier = 2.65 },
	{ id = 6, requiredLevel = 56, requiredSpeed = 41936, coinMultiplier = 3.35 },
	{ id = 7, requiredLevel = 70, requiredSpeed = 64079, coinMultiplier = 4.2 },
	{ id = 8, requiredLevel = 87, requiredSpeed = 96853, coinMultiplier = 5.3 },
	{ id = 9, requiredLevel = 108, requiredSpeed = 146061, coinMultiplier = 6.6 },
	{ id = 10, requiredLevel = 131, requiredSpeed = 210787, coinMultiplier = 8.3 },
}

return table.freeze(stages)
