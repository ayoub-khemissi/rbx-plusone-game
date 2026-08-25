--!strict
--[[
	World — one arc, with its own reading of the same ten courses.

	A world does not describe its courses. It SCALES the single ladder every world
	shares, multiplying both what a course costs in experience and the level curve
	by the same factor.

	That pairing is the point. Because the two move together, level 131 is level 131
	in every world and the character runs at the same speed there: one table of
	speeds and jump distances builds all of them, and the gaps of a tenth course are
	identical in the last world and the first. Only the raw number grows.

	It also means the permanent multiplier a rebirth grants never shortens a world.
	Scale and multiplier climb at the same pace, so the reward is a bigger world in
	the same time, never the same world in less.

	Worlds are built ONCE and cached. Two players in the same world share one ladder,
	and nothing here holds anything about a player.
]]

local StageLadder = require(script.Parent.StageLadder)
local LevelCurve = require(script.Parent.LevelCurve)
local Requirements = require(script.Parent.Parent.Progression.Requirements)

export type Definition = {
	id: number,
	name: string,
	scale: number,
	requires: { any }?,
}

export type Tuning = {
	stages: { any },
	level: { base: number, exponent: number },
	-- How many rebirths a world is made of. One per world unless told otherwise.
	rebirthsPerWorld: number?,
}

local World = {}

local Registry = {}
Registry.__index = Registry

local gate = Requirements.new()

--[[ The ten courses, priced for this world. Only the experience moves. ]]
local function scaleStages(stages: { any }, scale: number): { any }
	local scaled = table.create(#stages)
	for index, stage in stages do
		local copy = table.clone(stage)
		copy.requiredSpeed = math.floor(stage.requiredSpeed * scale)
		scaled[index] = copy
	end
	return scaled
end

local function build(definition: Definition, tuning: Tuning)
	local stages = scaleStages(tuning.stages, definition.scale)

	return {
		id = definition.id,
		name = definition.name,
		scale = definition.scale,
		stages = stages,
		ladder = StageLadder.new(stages),
		-- Scaled with the ladder, which is what keeps a level meaning the same
		-- thing from one world to the next.
		levels = LevelCurve.new({
			base = tuning.level.base * definition.scale,
			exponent = tuning.level.exponent,
		}),
	}
end

function World.registry(definitions: { Definition }, tuning: Tuning)
	local byId, built = {}, {}
	for _, definition in definitions do
		byId[definition.id] = definition
	end

	return setmetatable({
		definitions = definitions,
		_byId = byId,
		_built = built,
		_tuning = tuning,
	}, Registry)
end

function Registry.get(self, id: number)
	local definition = self._byId[id]
	if not definition then
		return nil
	end

	local existing = self._built[id]
	if not existing then
		existing = build(definition, self._tuning)
		self._built[id] = existing
	end
	return existing
end

--[[
	The world a profile is in: one per batch of rebirths, stopping at the last one.

	Deriving it rather than storing it means a profile cannot end up pointing at a
	world it has not earned, and adding worlds later needs no migration.
]]
function Registry.forProfile(self, profile: any)
	local taken = math.max(math.floor(profile.prestiges or 0), 0)
	local perWorld = math.max(self._tuning.rebirthsPerWorld or 1, 1)
	local reached = math.clamp(math.floor(taken / perWorld) + 1, 1, #self.definitions)

	return self:get(self.definitions[reached].id)
end

--[[ Whether a profile has earned a world. The first is always open. ]]
function Registry.isOpen(self, id: number, profile: any): boolean
	local definition = self._byId[id]
	if not definition then
		return false
	end
	return gate:evaluate(definition.requires, { profile = profile }).met
end

return World
