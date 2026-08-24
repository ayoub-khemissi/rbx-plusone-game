--!strict
--[[
	Server entry point.

	Deliberately empty of logic: it only starts the composition root. Everything
	testable lives in Domain/ and Application/.
]]

local Bootstrap = require(script.Composition.Bootstrap)

Bootstrap.start()
