--!strict
--[[
	Config — the whole configuration of the game, in one aggregate.

	Single entry point: `local Config = require(ReplicatedStorage.Shared.Config)`.
	Every table is frozen so no module can quietly retune the balance at runtime
	without going through this folder.

	`Theme` is the only part meant to be swapped per universe: it holds names, icons
	and colours, never numbers.
]]

local ACTIVE_THEME = "Default"

return table.freeze({
	Balance = require(script.Balance),
	Stages = require(script.Stages),
	Upgrades = require(script.Upgrades),
	Passes = require(script.Passes),
	Products = require(script.Products),
	Monetization = require(script.Monetization),
	Theme = require(script.Themes[ACTIVE_THEME]),
})
