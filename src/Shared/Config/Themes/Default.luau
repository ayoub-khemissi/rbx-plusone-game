--!strict
--[[
	Default theme — the display layer.

	THE POINT OF THIS FILE: the code only ever knows neutral concepts — speed, coins,
	prestige, stage, checkpoint, hub. A theme decides what the player reads and sees.

	Swapping theme is a data change: copy this file, rename the labels, repoint the
	images, repaint the palette, then point `Config.activeTheme` at it. No game rule
	moves, no test breaks, and several themes can ship side by side.

	What a theme may NOT change: the numbers. Balance lives in Balance.luau, so two
	themes of the same game stay comparable and a leaderboard stays fair.

	Images come from the Simulator Icon Pack. Each entry keeps its emoji as a
	fallback, so a missing or unapproved asset degrades to a readable glyph instead
	of an empty square.
]]

export type Label = {
	name: string,
	icon: string,
	image: string?,
	plural: string?,
	verb: string?,
}

export type Theme = {
	id: string,
	name: string,
	tagline: string,
	labels: { [string]: Label },
	icons: { [string]: string },
	palette: { [string]: { number } },
}

local theme: Theme = {
	id = "default",
	name = "Runner",
	tagline = "Every step makes you faster.",

	labels = {
		-- The gauge that never resets except on prestige.
		speed = { name = "Speed", icon = "⚡", image = "rbxassetid://17368052918" },
		-- The soft currency, spent on upgrades.
		coins = { name = "Coin", plural = "Coins", icon = "🪙", image = "rbxassetid://17368060122" },
		-- The reset that multiplies everything.
		prestige = {
			name = "Prestige",
			plural = "Prestiges",
			verb = "PRESTIGE",
			icon = "🔁",
			image = "rbxassetid://17368214873",
		},
		-- A segment of the course, delimited by checkpoints in the map.
		stage = { name = "Stage", plural = "Stages", icon = "🚩", image = "rbxassetid://17368097932" },
		checkpoint = {
			name = "Checkpoint",
			plural = "Checkpoints",
			icon = "🏁",
			image = "rbxassetid://15402908284",
		},
		-- The safe area with the shop, the prestige pad and the idle zone.
		hub = { name = "Hub", icon = "🏠", image = "rbxassetid://15403180857" },
		-- The passive collection, kept in the vocabulary for a later milestone.
		charm = { name = "Charm", plural = "Charms", icon = "🔮", image = "rbxassetid://15402964203" },
	},

	-- Icons that name no concept: menus, abilities, states.
	icons = {
		shop = "rbxassetid://17368188494",
		gifts = "rbxassetid://17368068524",
		store = "rbxassetid://15403000023",
		codes = "rbxassetid://17368032566",
		settings = "rbxassetid://17368089841",

		jump = "rbxassetid://14569017448",
		dash = "rbxassetid://16670799841",
		upgrade = "rbxassetid://17368045028",
		magnet = "rbxassetid://17368210998",

		locked = "rbxassetid://17368080973",
		unlocked = "rbxassetid://17368081924",
		playtime = "rbxassetid://15937828418",
		boost = "rbxassetid://15403265114",
		luck = "rbxassetid://17368084270",
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
