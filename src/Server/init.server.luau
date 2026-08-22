--!strict
--[[
	Point d'entree du serveur.

	Volontairement vide de toute logique : il ne fait que demarrer la racine de
	composition. Tout ce qui est testable vit dans Domain/ et Application/.
]]

local Bootstrap = require(script.Composition.Bootstrap)

Bootstrap.start()
