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
		speed = { name = "Speed", icon = "⚡", image = "rbxassetid://72489491614400" }, -- icon:speed
		-- The soft currency, spent on upgrades.
		coins = { name = "Coin", plural = "Coins", icon = "🪙", image = "rbxassetid://125836677978670" }, -- icon:coins
		-- The reset that multiplies everything.
		prestige = {
			name = "Prestige",
			plural = "Prestiges",
			verb = "PRESTIGE",
			icon = "🔁",
			image = "rbxassetid://127090701921262", -- icon:prestige
		},
		-- A segment of the course, delimited by checkpoints in the map.
		stage = { name = "Stage", plural = "Stages", icon = "🚩", image = "rbxassetid://96482815583599" }, -- icon:stage
		checkpoint = {
			name = "Checkpoint",
			plural = "Checkpoints",
			icon = "🏁",
			image = "rbxassetid://129183707233642", -- icon:checkpoint
		},
		-- The safe area with the shop, the prestige pad and the idle zone.
		hub = { name = "Hub", icon = "🏠", image = "rbxassetid://109388024418475" }, -- icon:hub
		-- The passive collection, kept in the vocabulary for a later milestone.
		charm = { name = "Charm", plural = "Charms", icon = "🔮", image = "rbxassetid://138178398760441" }, -- icon:charm
	},

	-- Icons that name no concept: menus, abilities, states.
	icons = {
		shop = "rbxassetid://104318005297065", -- icon:shop
		gifts = "rbxassetid://79028116148308", -- icon:gifts
		store = "rbxassetid://128827199445477", -- icon:store
		codes = "rbxassetid://104054453018101", -- icon:codes
		settings = "rbxassetid://107581476943991", -- icon:settings

		jump = "rbxassetid://138557052197452", -- icon:jump
		dash = "rbxassetid://112290599395227", -- icon:dash
		upgrade = "rbxassetid://74610614337917", -- icon:upgrade
		magnet = "rbxassetid://106597009085290", -- icon:magnet

		locked = "rbxassetid://80543302321098", -- icon:locked
		unlocked = "rbxassetid://93610144216997", -- icon:unlocked
		playtime = "rbxassetid://119952373300752", -- icon:playtime
		boost = "rbxassetid://89679533751682", -- icon:boost
		luck = "rbxassetid://70630857900711", -- icon:luck
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
