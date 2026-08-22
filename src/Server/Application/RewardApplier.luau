--!strict
--[[
	RewardApplier — chemin commun a TOUTE recompense (achat, quotidien, coffre, code).

	Applique la recompense au profil, republie l'instantane, previent le joueur et
	declenche une sauvegarde. Centraliser cette sequence evite qu'une source de
	revenu oublie, par exemple, de sauvegarder.
]]

local Shared = require(script.Parent.Parent.Shared)
local Grants = require(Shared.Domain.Monetization.Grants)
local Format = require(Shared.Domain.Support.Format)

local RewardApplier = {}
RewardApplier.__index = RewardApplier

function RewardApplier.new(dependencies)
	return setmetatable(table.clone(dependencies), RewardApplier)
end

--[[ Resume lisible d'une recompense, pour la notification joueur. ]]
function RewardApplier.describe(self, summary): string
	local parts = {}
	if summary.bananas then
		table.insert(parts, `+{Format.abbreviate(summary.bananas)} bananes`)
	end
	if summary.speed then
		table.insert(parts, `+{Format.abbreviate(summary.speed)} vitesse`)
	end
	if summary.boost then
		local definition = self.boosts:definitionOf(summary.boost.id)
		table.insert(parts, `{definition and definition.name or summary.boost.id} active`)
	end
	if summary.rebirths then
		table.insert(parts, `+{summary.rebirths} renaissance`)
	end
	return table.concat(parts, ", ")
end

function RewardApplier.award(self, session, grant, options)
	options = options or {}
	local now = self.clock.now()

	local summary = Grants.apply(grant, {
		profile = session.profile,
		boosts = self.boosts,
		rebirthPolicy = self.rebirthPolicy,
		now = now,
	})

	if session.player then
		self.publisher:publish(session.player, self.snapshots:build(session))

		if options.silent ~= true then
			local description = self:describe(summary)
			local prefix = options.title or "Recompense"
			local message = if description ~= "" then `{prefix} : {description}` else prefix
			self.notifier:notify(session.player, message, options.kind or "success")
		end
	end

	if options.save ~= false then
		self.save:run(session.userId)
	end

	return summary
end

return RewardApplier
