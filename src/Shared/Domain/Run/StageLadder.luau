--!strict
--[[
	StageLadder — the Stages of a course, their entry speed and their coin bonus.

	The MAP decides where a Stage begins; this ladder decides what it costs to enter
	and what it pays. Two invariants are enforced at construction so a balancing
	mistake fails on the first server start rather than in production:

	  - entry speed must strictly rise, otherwise a Stage is free;
	  - the coin multiplier must rise too, otherwise going further is pure downside.
]]

export type Stage = {
	id: number,
	name: string?,
	requiredSpeed: number,
	-- What the gate announces. Advisory: nothing enforces it.
	requiredLevel: number?,
	coinMultiplier: number,
}

local StageLadder = {}
StageLadder.__index = StageLadder

export type StageLadder = typeof(setmetatable(
	{} :: { _stages: { Stage }, _byId: { [number]: Stage }, _indexById: { [number]: number } },
	StageLadder
))

function StageLadder.new(stages: { Stage }): StageLadder
	local byId, indexById = {}, {}
	local previousSpeed = -math.huge
	local previousMultiplier = -math.huge

	for index, stage in stages do
		if stage.requiredSpeed <= previousSpeed then
			error(`Stage ladder is invalid: entry speed of stage {stage.id} must be rising`, 2)
		end
		if index > 1 and stage.coinMultiplier <= previousMultiplier then
			error(`Stage ladder is invalid: coin multiplier of stage {stage.id} must be rising`, 2)
		end

		previousSpeed = stage.requiredSpeed
		previousMultiplier = stage.coinMultiplier
		byId[stage.id] = stage
		indexById[stage.id] = index
	end

	return setmetatable({ _stages = stages, _byId = byId, _indexById = indexById }, StageLadder)
end

function StageLadder.count(self: StageLadder): number
	return #self._stages
end

function StageLadder.all(self: StageLadder): { Stage }
	return self._stages
end

function StageLadder.get(self: StageLadder, stageId: number): Stage?
	return self._byId[stageId]
end

function StageLadder.requirementOf(self: StageLadder, stageId: number): number?
	local stage = self._byId[stageId]
	return stage and stage.requiredSpeed
end

function StageLadder.nextOf(self: StageLadder, stageId: number): Stage?
	local index = self._indexById[stageId]
	return if index then self._stages[index + 1] else nil
end

function StageLadder.isUnlocked(self: StageLadder, stageId: number, speed: number): boolean
	local stage = self._byId[stageId]
	return stage ~= nil and speed >= stage.requiredSpeed
end

--[[ Deepest Stage this speed can enter. ]]
function StageLadder.highestUnlocked(self: StageLadder, speed: number): number
	local highest = self._stages[1].id
	for _, stage in self._stages do
		if speed >= stage.requiredSpeed then
			highest = stage.id
		else
			break
		end
	end
	return highest
end

--[[ Progress in [0, 1] between this gate and the next one. ]]
function StageLadder.progressToNext(self: StageLadder, stageId: number, speed: number): number
	local stage = self._byId[stageId]
	local nextStage = self:nextOf(stageId)
	if not stage or not nextStage then
		return 1
	end

	local span = nextStage.requiredSpeed - stage.requiredSpeed
	if span <= 0 then
		return 1
	end
	return math.clamp((speed - stage.requiredSpeed) / span, 0, 1)
end

return StageLadder
