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
	if summary.gold then
		table.insert(parts, `+{Format.abbreviate(summary.gold)} gold`)
	end
	if summary.speed then
		table.insert(parts, `+{Format.abbreviate(summary.speed)} speed`)
	end
	if summary.eggs then
		table.insert(parts, `+{summary.eggs.amount} {summary.eggs.rarity} egg`)
	end
	if summary.boost then
		local definition = self.boosts:definitionOf(summary.boost.id)
		table.insert(parts, `{definition and definition.name or summary.boost.id} active`)
	end
	if summary.molts then
		table.insert(parts, `+{summary.molts} molt`)
	end
	if summary.insuredFlights then
		table.insert(parts, `{summary.insuredFlights} insured flights`)
	end
	if summary.hatched then
		table.insert(parts, `{summary.hatched} eggs hatched`)
	end
	return table.concat(parts, ", ")
end

--[[ Grants that need more than the profile — they reach into the Nest. ]]
function RewardApplier.applyExtras(self, session, grant, summary)
	local profile = session.profile

	if typeof(grant.insurance) == "table" then
		local flights = math.max(math.floor(grant.insurance.flights or 0), 0)
		profile.insuredFlights += flights
		summary.insuredFlights = profile.insuredFlights
	end

	if grant.instantHatch == true then
		local hatched = 0
		for _ = 1, #profile.hatchery do
			local egg = profile.hatchery[1]
			if not egg then
				break
			end
			egg.readyAt = 0
			hatched += 1
		end
		summary.hatched = hatched
	end

	return summary
end

function RewardApplier.award(self, session, grant, options)
	options = options or {}
	local now = self.clock.now()

	local summary = Grants.apply(grant, {
		profile = session.profile,
		boosts = self.boosts,
		moltPolicy = self.moltPolicy,
		now = now,
	})
	self:applyExtras(session, grant or {}, summary)

	if session.player then
		self.publisher:publish(session.player, self.snapshots:build(session))

		if options.silent ~= true then
			local description = self:describe(summary)
			local prefix = options.title or "Reward"
			local message = if description ~= "" then `{prefix}: {description}` else prefix
			self.notifier:notify(session.player, message, options.kind or "success")
		end
	end

	if options.save ~= false then
		self.save:run(session.userId)
	end

	return summary
end

return RewardApplier
