--!strict
--[[
	RewardApplier — the shared path of EVERY reward (purchase, daily, chest, code).

	Applies the reward to the profile, republishes the snapshot, tells the player and
	triggers a save. Centralising this sequence is what stops one revenue source from
	quietly forgetting to persist what it just granted.
]]

local Shared = require(script.Parent.Parent.Shared)
local Grants = require(Shared.Domain.Monetization.Grants)
local Format = require(Shared.Domain.Support.Format)

local RewardApplier = {}
RewardApplier.__index = RewardApplier

function RewardApplier.new(dependencies)
	return setmetatable(table.clone(dependencies), RewardApplier)
end

--[[ Readable summary of a reward, for the player notification. ]]
function RewardApplier.describe(self, summary): string
	local parts = {}
	if summary.coins then
		table.insert(parts, `+{Format.abbreviate(summary.coins)} Coins`)
	end
	if summary.speed then
		table.insert(parts, `+{Format.abbreviate(summary.speed)} speed`)
	end
	if summary.boost then
		local definition = self.boosts:definitionOf(summary.boost.id)
		table.insert(parts, `{definition and definition.name or summary.boost.id} active`)
	end
	if summary.prestiges then
		table.insert(parts, `+{summary.prestiges} prestige`)
	end
	if summary.chestOpened then
		table.insert(parts, "session chest opened")
	end
	return table.concat(parts, ", ")
end

--[[ Grants that reach beyond the profile fields themselves. ]]
function RewardApplier.applyExtras(self, session, grant, summary)
	-- The instant chest simply makes the session chest claimable right now.
	if grant.instantChest == true then
		session.profile.timers[self.chestKey] = 0
		summary.chestOpened = true
	end

	return summary
end

function RewardApplier.award(self, session, grant, options)
	options = options or {}
	local now = self.clock.now()

	local summary = Grants.apply(grant, {
		profile = session.profile,
		boosts = self.boosts,
		prestigePolicy = self.prestigePolicy,
		now = now,
	})
	self:applyExtras(session, grant or {}, summary)

	if session.player then
		self.publisher:publish(session.player, self.snapshots:build(session))

		if options.silent ~= true then
			local description = self:describe(summary)
			local prefix = options.title or "Reward"
			local message = if description ~= "" then `{prefix}: {description}` else prefix
			self.notifier:notify(session.player, message, options.kind or "success", options.cue)
		end
	end

	if options.save ~= false then
		self.save:run(session.userId)
	end

	return summary
end

return RewardApplier
