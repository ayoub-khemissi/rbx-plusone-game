--!strict
--[[
	Config — the whole configuration of the game, in one aggregate.

	Single entry point: `local Config = require(ReplicatedStorage.Shared.Config)`.
	Every table is frozen so no module can quietly retune the balance at runtime
	without going through this folder.
]]

return table.freeze({
	Balance = require(script.Balance),
	Tiers = require(script.Tiers),
	Upgrades = require(script.Upgrades),
	Dragons = require(script.Dragons),
	Passes = require(script.Passes),
	Products = require(script.Products),
	Monetization = require(script.Monetization),
	World = require(script.World),
})
