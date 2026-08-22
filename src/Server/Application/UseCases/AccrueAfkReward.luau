--!strict
--[[
	AccrueAfkReward — revenu passif de la zone AFK.

	Appele par la meme boucle d'echantillonnage que le gain de vitesse : c'est le
	serveur qui constate la presence sur le pad, le client ne declare rien.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Result = require(Shared.Domain.Support.Result)

local AccrueAfkReward = {}
AccrueAfkReward.__index = AccrueAfkReward

function AccrueAfkReward.new(dependencies)
	return setmetatable(table.clone(dependencies), AccrueAfkReward)
end

function AccrueAfkReward.run(self, player, position, deltaTime: number)
	local session = self.sessions:forPlayer(player)
	if not session then
		return Result.err("NO_SESSION", "Aucune session ouverte")
	end

	local inStation = self.idle:covers(position)

	if not inStation then
		if session.afkActive then
			self.idle:reset(session.idle)
			session.afkActive = false
			self.publisher:publish(player, self.snapshots:build(session))
		end
		return Result.ok({ active = false })
	end

	if not session.afkActive then
		session.afkActive = true
		self.publisher:publish(player, self.snapshots:build(session))
		self.notifier:notify(player, "💤 Zone AFK : tu gagnes des bananes sans bouger.", "info")
	end

	local outcome = self.idle:accumulate(session.idle, deltaTime)
	if outcome.bananas > 0 then
		-- Recompense plate : aucun multiplicateur, la zone AFK ne doit jamais
		-- devenir la meilleure facon de jouer.
		self.rewards:award(session, { bananas = outcome.bananas }, {
			title = "💤 Zone AFK",
			save = false, -- l'autosave s'en charge : pas d'ecriture toutes les minutes
		})
	end

	if outcome.capped and not session.afkCapNotified then
		session.afkCapNotified = true
		self.notifier:notify(player, "Plafond AFK atteint : reviens courir pour gagner plus !", "warning")
	end

	return Result.ok({ active = true, payouts = outcome.payouts, bananas = outcome.bananas })
end

return AccrueAfkReward
