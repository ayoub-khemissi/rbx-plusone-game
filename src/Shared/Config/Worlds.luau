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
	Seven rebirths open the next one, and the scales are solved rather than picked:
	each was searched for so that its seven cycles come to about four and a half
	hours, against the rebirth ladder in Balance and the way the multiplier climbs.
	They come out very close to linear, which is a consequence, not a rule.
]]
local worlds: { World } = {
	{ id = 1, name = "World 1", scale = 1 },
	{ id = 2, name = "World 2", scale = 2.3, requires = { { kind = "prestiges", value = 7 } } },
	{ id = 3, name = "World 3", scale = 3.54, requires = { { kind = "prestiges", value = 14 } } },
	{ id = 4, name = "World 4", scale = 4.76, requires = { { kind = "prestiges", value = 21 } } },
	{ id = 5, name = "World 5", scale = 5.98, requires = { { kind = "prestiges", value = 28 } } },
}

return table.freeze(worlds)
