--!strict
--[[
	Requirements — what has to be true before something opens.

	ONE EVALUATOR FOR THE WHOLE GAME. An upgrade that needs another upgrade, a belt
	that needs a level, the next world that needs seven rebirths: all of them are the
	same question asked of the same profile. Writing that question once means a new
	gate is a line of DATA rather than a new branch somewhere in a use case.

		requires = {
			{ kind = "upgrade", id = "dash", level = 1 },
			{ kind = "level", value = 10 },
		}

	Every condition must pass. The ones that did not are RETURNED, because "locked"
	on its own is a dead end for the player while "needs the Dash" tells them what
	to do next — and the interface cannot invent that explanation on its own.

	An unknown condition LOCKS. A typo in a configuration that silently opened
	everything is the kind of bug that ships and is found by a player.
]]

export type Condition = {
	kind: string,
	id: string?,
	level: number?,
	value: number?,
}

export type Context = {
	profile: any,
	level: number?,
	passes: { [string]: boolean }?,
}

export type Outcome = {
	met: boolean,
	unmet: { Condition },
}

local Requirements = {}
Requirements.__index = Requirements

export type Requirements = typeof(setmetatable({}, Requirements))

--[[
	One test per kind. Each returns whether the condition holds, and none of them
	may throw: a malformed condition is a locked one, never a crash in a shop.
]]
local CHECKS: { [string]: (Condition, Context) -> boolean } = {
	upgrade = function(condition, context)
		local owned = context.profile and context.profile.upgrades[condition.id or ""] or 0
		return owned >= (condition.level or 1)
	end,

	level = function(condition, context)
		return (context.level or 0) >= (condition.value or 0)
	end,

	prestiges = function(condition, context)
		local prestiges = context.profile and context.profile.prestiges or 0
		return prestiges >= (condition.value or 0)
	end,

	stage = function(condition, context)
		local reached = context.profile and context.profile.highestStage or 0
		return reached >= (condition.value or 0)
	end,

	pass = function(condition, context)
		local passes = context.passes or {}
		return passes[condition.id or ""] == true
	end,
}

function Requirements.new(): Requirements
	return setmetatable({}, Requirements)
end

--[[ Answers whether a list of conditions holds, and which ones did not. ]]
function Requirements.evaluate(_self: Requirements, conditions: { Condition }?, context: Context): Outcome
	local unmet = {}

	for _, condition in conditions or {} do
		local check = CHECKS[condition.kind]
		if not check or not check(condition, context or {}) then
			table.insert(unmet, condition)
		end
	end

	return { met = #unmet == 0, unmet = unmet }
end

return Requirements
