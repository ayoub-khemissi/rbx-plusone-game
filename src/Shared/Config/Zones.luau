--!strict
--[[
	Zones — l'echelle de progression du jeu.

	`requiredSpeed` doit rester STRICTEMENT croissant (verifie au demarrage par
	Domain.Zones.ZoneLadder). `color` est un triplet RGB 0-255 utilise par le
	generateur de map.
]]

local ZoneLadder = require(script.Parent.Parent.Domain.Zones.ZoneLadder)

type Zone = ZoneLadder.Zone

local zones: { Zone } = {
	{
		id = 1,
		name = "Clairiere des Bananiers",
		requiredSpeed = 0,
		stepMultiplier = 1,
		bananaMultiplier = 1,
		length = 420,
		color = { 96, 168, 84 },
	},
	{
		id = 2,
		name = "Canopee Basse",
		requiredSpeed = 200,
		stepMultiplier = 1.35,
		bananaMultiplier = 1.6,
		length = 420,
		color = { 62, 140, 96 },
	},
	{
		id = 3,
		name = "Lianes du Ravin",
		requiredSpeed = 700,
		stepMultiplier = 1.8,
		bananaMultiplier = 2.4,
		length = 460,
		color = { 74, 120, 148 },
	},
	{
		id = 4,
		name = "Temple Moussu",
		requiredSpeed = 2000,
		stepMultiplier = 2.5,
		bananaMultiplier = 3.6,
		length = 460,
		color = { 128, 118, 96 },
	},
	{
		id = 5,
		name = "Cascade Rugissante",
		requiredSpeed = 6000,
		stepMultiplier = 3.4,
		bananaMultiplier = 5.5,
		length = 500,
		color = { 84, 148, 196 },
	},
	{
		id = 6,
		name = "Falaises de Braise",
		requiredSpeed = 18000,
		stepMultiplier = 4.8,
		bananaMultiplier = 8.5,
		length = 500,
		color = { 176, 88, 62 },
	},
	{
		id = 7,
		name = "Cite des Nuages",
		requiredSpeed = 55000,
		stepMultiplier = 7,
		bananaMultiplier = 14,
		length = 540,
		color = { 168, 172, 200 },
	},
	{
		id = 8,
		name = "Sommet du Singe Roi",
		requiredSpeed = 160000,
		stepMultiplier = 10,
		bananaMultiplier = 25,
		length = 600,
		color = { 208, 168, 72 },
	},
}

return table.freeze(zones)
