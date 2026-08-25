--!strict
--[[
	Worlds — the arcs a player crosses, and what it costs to reach each one.

	A world is TEN courses. `Stages.luau` describes those ten once; a world does not
	repeat them, it SCALES them.

	`scale` multiplies both the experience a course sits behind AND the level curve,
	by the same factor. That pairing is the whole trick, and it buys two things:

	  * inside any world, level 131 is level 131 and the character runs at 75. One
	    table of speeds and jump distances therefore builds every world — the gaps
	    of a tenth course are the same in world 6 as in world 1, and only the
	    decoration and the reading of it change;

	  * the permanent multiplier a rebirth grants never shortens a world. It rises
	    at the same pace as the scale, so it lets a player swallow a bigger world in
	    the same time rather than the same world in less. A world stays four to five
	    hours, and drifts slowly longer.

	`requires` is read by Domain.Progression.Requirements, so a world opens on the
	same rule as everything else. Rebirths are the key, and it takes SEVEN of them
	to move on: a world is seven loops of reset-and-climb, not one.

	Adding a world is a line here. Nothing else moves.
]]

export type World = {
	id: number,
	name: string,
	scale: number,
	requires: { any }?,
}

--[[
	Seven rebirths open the next one, and a world's scale is the multiplier a player
	holds when they arrive: 1.6 to the power of the rebirths behind them. That is
	what makes a world absorb exactly what the player gained rather than being
	cleared faster by it, so every world lasts about as long as the last.

	The numbers grow quickly, which is the point. A speed that ended world 1 is a
	beginner's speed in world 2 — the same experience, read on a scale six times
	larger.
]]
local worlds: { World } = {
	{ id = 1, name = "World 1", scale = 1 },
	{ id = 2, name = "World 2", scale = 26.84, requires = { { kind = "prestiges", value = 7 } } },
	{ id = 3, name = "World 3", scale = 720.58, requires = { { kind = "prestiges", value = 14 } } },
	{ id = 4, name = "World 4", scale = 19342.81, requires = { { kind = "prestiges", value = 21 } } },
	{ id = 5, name = "World 5", scale = 519229.69, requires = { { kind = "prestiges", value = 28 } } },
}

return table.freeze(worlds)
