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
	textures: { [string]: string? },
}

local theme: Theme = {
	id = "default",
	name = "Runner",
	tagline = "Every step makes you faster.",

	labels = {
		-- The gauge that never resets except on prestige.
		speed = { name = "Speed", icon = "⚡", image = "rbxassetid://112003667186542" }, -- icon:speed
		-- The soft currency, spent on upgrades.
		coins = { name = "Coin", plural = "Coins", icon = "🪙", image = "rbxassetid://121223833708562" }, -- icon:coins
		-- The reset that multiplies everything.
		prestige = {
			name = "Prestige",
			plural = "Prestiges",
			verb = "PRESTIGE",
			icon = "🔁",
			image = "rbxassetid://79810123991740", -- icon:prestige
		},
		-- A segment of the course, delimited by checkpoints in the map.
		stage = { name = "Stage", plural = "Stages", icon = "🚩", image = "rbxassetid://122962606025816" }, -- icon:stage
		checkpoint = {
			name = "Checkpoint",
			plural = "Checkpoints",
			icon = "🏁",
			image = "rbxassetid://133175370281266", -- icon:checkpoint
		},
		-- The safe area with the shop, the prestige pad and the idle zone.
		hub = { name = "Hub", icon = "🏠", image = "rbxassetid://103151849319813" }, -- icon:hub
		-- The passive collection, kept in the vocabulary for a later milestone.
		charm = { name = "Charm", plural = "Charms", icon = "🔮", image = "rbxassetid://109982212844429" }, -- icon:charm
	},

	-- Icons that name no concept: menus, abilities, states.
	icons = {
		shop = "rbxassetid://76880977958392", -- icon:shop
		gifts = "rbxassetid://131339612599410", -- icon:gifts
		store = "rbxassetid://125260470554584", -- icon:store
		codes = "rbxassetid://82072427560833", -- icon:codes
		settings = "rbxassetid://112964219386095", -- icon:settings

		jump = "rbxassetid://123146356799048", -- icon:jump
		dash = "rbxassetid://99508257502715", -- icon:dash
		upgrade = "rbxassetid://70459844484448", -- icon:upgrade
		magnet = "rbxassetid://95404918115378", -- icon:magnet

		locked = "rbxassetid://120220653823154", -- icon:locked
		unlocked = "rbxassetid://101235179177979", -- icon:unlocked
		playtime = "rbxassetid://97880576771378", -- icon:playtime
		boost = "rbxassetid://86362137803303", -- icon:boost
		luck = "rbxassetid://137338136533007", -- icon:luck
	},

	palette = {
		-- Panels are LIGHT and text on them is dark. The simulator look reads as a
		-- paper card laid over the world, not as a dark overlay swallowing it.
		panel = { 250, 249, 246 },
		panelSoft = { 233, 231, 226 },
		panelEdge = { 46, 50, 72 },
		background = { 30, 34, 52 },

		-- `outline` is the black worn by every big number so it survives being read
		-- over a bright sky, a lava pit or a white wall.
		outline = { 20, 22, 34 },
		text = { 52, 56, 78 },
		textMuted = { 122, 128, 150 },
		textOnColor = { 255, 255, 255 },

		-- Saturated fills. Each one names a meaning, not a hue: a theme may repaint
		-- them all and the interface keeps saying the same things.
		accent = { 247, 197, 37 },
		accentDark = { 206, 152, 16 },
		info = { 59, 178, 240 },
		positive = { 92, 201, 74 },
		negative = { 229, 51, 60 },
		special = { 150, 60, 220 },
		locked = { 152, 156, 172 },
	},

	-- Optional decoration. Leave a field out and the surface stays flat, which is
	-- perfectly readable: a texture is polish, never a requirement.
	textures = {
		-- A seamless tile laid faintly over every panel, at 8% opacity: it gives the
		-- surface a grain instead of a colour. Any seamless texture works — see
		-- docs/TEXTURES.md for the ones already available.
		panelPattern = "rbxassetid://4621488899",
	},
}

return table.freeze(theme)
