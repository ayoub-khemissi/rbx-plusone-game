--!strict
--[[
	Default theme — the display layer.

	THE POINT OF THIS FILE: the code only ever knows neutral concepts — speed, coins,
	prestige, stage, hub. A theme decides what the player reads and sees.

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
		--[[
			The word for the reset. "Rebirth" is what Roblox players expect and what
			the platform's own translation turns into "Renaissance" in French — which
			is the word this game wants and the one on every reference screenshot.
			The code keeps calling the mechanic Prestige; only this is read.
		]]
		prestige = {
			name = "Rebirth",
			plural = "Rebirths",
			verb = "REBIRTH",
			icon = "🔁",
			image = "rbxassetid://79810123991740", -- icon:prestige
		},
		-- Speed read as a rank: what the progress bar announces.
		level = { name = "Level", plural = "Levels", icon = "⚡", image = "rbxassetid://112003667186542" }, -- icon:speed
		-- A segment of the course, opened by reaching the Speed it asks for.
		stage = { name = "Stage", plural = "Stages", icon = "🚩", image = "rbxassetid://122962606025816" }, -- icon:stage
		-- The safe area with the shop, the prestige pad and the treadmills.
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

		--[[
			The rim a button wears WHILE THE POINTER IS ON IT, and nothing else in the
			game wears at all.

			At rest every button keeps the dark edge, like every card and chip: a
			screen where all of them are outlined in gold is a screen with a dozen
			calls to action and therefore none. Spending the colour on the one under
			the pointer is what makes it mean "this one".

			Pale rather than saturated: it has to read as light catching the rim, and a
			deep gold reads as paint. It is well clear of `accent`, the Coin colour,
			for the same reason — a rim that matches the currency looks like a price.
		]]
		hoverEdge = { 255, 230, 140 },
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

		--[[
			One pair per world, top and bottom of the gradient the Rebirth chip
			wears. It is the only place the interface says WHICH world the player is
			in, and it says it without a word: the number on the chip counts the
			rebirths, the colour says what they bought.

			They climb the way a player expects rarity to climb — sky, green, violet,
			crimson — and the last one is the only two-colour pair, because the end of
			the game should not look like another rung.

			The first is deliberately the LIGHTEST of the five. It is the one every
			player sees first and most, and a dark plate under white glyphs is heavy
			in the corner of a screen somebody is running across.
		]]
		worlds = {
			{ { 110, 205, 255 }, { 45, 145, 230 } },
			{ { 92, 201, 74 }, { 38, 148, 60 } },
			{ { 168, 88, 232 }, { 104, 40, 190 } },
			{ { 240, 88, 96 }, { 188, 32, 58 } },
			{ { 255, 118, 200 }, { 88, 190, 255 } },
		},
	},

	-- Optional decoration. Leave a field out and the surface stays flat, which is
	-- perfectly readable: a texture is polish, never a requirement.
	--[[
		Built assets the game inserts rather than draws: a Coin is a model somebody
		modelled, not a cylinder the server can make.

		The id is a theme decision like every other asset here — a theme may point at
		its own Coin, or at none, and the map keeps working either way. Nothing is
		inserted if a map already contains its own tagged Coins; this is only what
		the test platform builds with.
	]]
	models = {
		coin = 14861633855, -- Coin, by BryanROBLOXgamer10
	},

	textures = {
		--[[
			Two seamless tiles, laid faintly over the flat fills: colour alone renders
			as vinyl, and a grain under it reads as a moulded object.

			They are chosen for what they sit on. The panels wear a grid of large
			squares, which is the plate a simulator window is built from and reads
			well across a wide surface. The buttons wear brushed metal: a streak
			rather than a motif, which is what a small, saturated, glossy surface can
			carry — a grid at that size becomes a pattern competing with the word
			written across it, and a plaster noise disappears into the gloss.

			The opacities are the dial, and the tiles are how big one repeat is drawn.
			Too faint and the grain is a rumour nobody sees; too strong and it becomes
			a pattern the eye reads instead of the words on top of it.

			The grain DARKENS the surface it lies on — it is tinted with a shade of
			that surface's own colour — so these numbers buy depth rather than haze.
			A light tile laid on top would bleach a saturated button and take the
			contrast of the white text with it.

			The panels carry twice what the buttons do, and can. Their grain is drawn
			UNDER their content, so it costs the text nothing however strong it gets;
			a button draws its own words over its own face and has to leave room. It
			also has more to cover — a near-white plate the size of a window reads as
			blank paper long after the same value has textured a button.

			A tile wants to be large enough that a button shows one or two repeats
			rather than a mosaic of them — the texture should read as the surface the
			thing is made of, not as something printed on it.

			Any seamless, low-contrast texture works — see docs/TEXTURES.md. Set
			either to nil and that surface goes smooth again.
		]]
		panelPattern = "rbxassetid://4621488899", -- large_square_pattern
		panelOpacity = 0.35,
		panelTile = 64,
		buttonPattern = "rbxassetid://4549727994", -- metal
		buttonOpacity = 0.22,
		buttonTile = 96,
		--[[
			The confetti thrown when a player takes a Rebirth. Left unset, the engine's
			own sparkle texture is used, which ships with every Roblox install — so the
			celebration never waits on an upload. Set it to a small square of confetti
			and the burst reads as paper rather than light.
		]]
		confetti = nil,
	},
}

return table.freeze(theme)
