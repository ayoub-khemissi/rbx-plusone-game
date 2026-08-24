--!strict
--[[
	Default theme — the display layer.

	THE POINT OF THIS FILE: the code only ever knows neutral concepts — speed, coins,
	prestige, stage, checkpoint, hub. A theme decides what the player reads.

	Swapping theme is a data change: copy this file, rename the labels, repaint the
	palette, point `Config.activeTheme` at it. No game rule moves, no test breaks, and
	several themes can ship side by side.

	What a theme may NOT change: the numbers. Balance lives in Balance.luau, so two
	themes of the same game stay comparable and a leaderboard stays fair.
]]

export type Label = {
	name: string,
	icon: string,
	plural: string?,
	verb: string?,
}

export type Theme = {
	id: string,
	name: string,
	tagline: string,
	labels: { [string]: Label },
	palette: { [string]: { number } },
}

local theme: Theme = {
	id = "default",
	name = "Runner",
	tagline = "Every step makes you faster.",

	labels = {
		-- The gauge that never resets except on prestige.
		speed = { name = "Speed", icon = "⚡" },
		-- The soft currency, spent on upgrades.
		coins = { name = "Coin", plural = "Coins", icon = "🪙" },
		-- The reset that multiplies everything.
		prestige = { name = "Prestige", plural = "Prestiges", verb = "PRESTIGE", icon = "🔁" },
		-- A segment of the course, delimited by checkpoints in the map.
		stage = { name = "Stage", plural = "Stages", icon = "🚩" },
		checkpoint = { name = "Checkpoint", plural = "Checkpoints", icon = "🏁" },
		-- The safe area with the shop, the prestige pad and the idle zone.
		hub = { name = "Hub", icon = "🏠" },
		-- The passive collection, kept in the vocabulary for a later milestone.
		charm = { name = "Charm", plural = "Charms", icon = "🔮" },
	},

	palette = {
		background = { 24, 28, 40 },
		panel = { 36, 42, 60 },
		accent = { 250, 206, 110 },
		positive = { 120, 214, 150 },
		negative = { 226, 96, 92 },
		speed = { 250, 206, 110 },
		coins = { 250, 214, 120 },
	},
}

return table.freeze(theme)
