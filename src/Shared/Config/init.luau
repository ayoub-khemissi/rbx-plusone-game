--!strict
--[[
	Config — agregat de toute la configuration du jeu.

	Point d'entree unique : `local Config = require(ReplicatedStorage.Shared.Config)`.
	Les tables sont gelees pour qu'aucun module ne puisse modifier l'equilibrage
	a chaud sans passer par ce dossier.
]]

return table.freeze({
	Balance = require(script.Balance),
	Upgrades = require(script.Upgrades),
	Zones = require(script.Zones),
	Passes = require(script.Passes),
	World = require(script.World),
})
