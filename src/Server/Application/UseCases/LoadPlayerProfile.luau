--!strict
--[[
	LoadPlayerProfile — ouvre la session d'un joueur qui rejoint la partie.

	Regle de securite majeure : si la lecture du depot echoue, le joueur peut jouer
	mais sa session est marquee NON sauvegardable. On prefere perdre une partie
	qu'ecraser des heures de progression par un profil vide.
]]

local Shared = require(script.Parent.Parent.Parent.Shared)
local Profile = require(Shared.Domain.Profile.Profile)
local Result = require(Shared.Domain.Support.Result)

local LoadPlayerProfile = {}
LoadPlayerProfile.__index = LoadPlayerProfile

function LoadPlayerProfile.new(dependencies)
	return setmetatable(table.clone(dependencies), LoadPlayerProfile)
end

function LoadPlayerProfile.run(self, player)
	local userId = player.UserId

	local loaded, raw = pcall(function()
		return self.repository:load(userId)
	end)

	local session = self.sessions:open(userId, Profile.migrate(if loaded then raw else nil), player)
	session.savable = loaded

	local now = if self.clock then self.clock.now() else 0
	session.joinedAt = now

	-- Hooks d'ouverture de session (nettoyage des boosts expires, armement des
	-- compteurs de coffres...). Injectes par la racine de composition.
	for _, hook in self.sessionHooks or {} do
		hook(session, now)
	end

	local passesLoaded, passes = pcall(function()
		return self.passGateway:ownedPasses(player)
	end)
	session.passes = if passesLoaded and typeof(passes) == "table" then passes else {}

	if self.snapshots and self.publisher then
		self.publisher:publish(player, self.snapshots:build(session))
	end

	if not loaded then
		if self.notifier then
			self.notifier:notify(
				player,
				"Sauvegarde indisponible : ta progression ne sera pas enregistree.",
				"error"
			)
		end
		return Result.err("LOAD_FAILED", tostring(raw), session)
	end

	return Result.ok(session)
end

return LoadPlayerProfile
