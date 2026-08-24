--!strict
--[[
	Monetization — settings of the business model.

	Four pillars, each proven on Roblox:

	  1. FREE AND STICKY  : daily streak, session chest, idle zone;
	  2. PERMANENT        : gamepasses, bought once, high perceived value;
	  3. REPEATABLE       : consumable products bought at every hard step — the main
	     source of revenue;
	  4. SOCIAL & REACH   : a server-wide party everyone sees, promo codes that spread
	     on social media, and a timed welcome offer.

	Nothing here gates content: everything is reachable by playing. Nothing here is
	themed either — a theme renames what the player reads, never what they get.
]]

local HOUR = 3600
local DAY = 86400

return table.freeze({
	boosts = table.freeze({
		definitions = table.freeze({
			speedRush = table.freeze({ name = "Speed Rush", icon = "⚡", speed = 2 }),
			coinRush = table.freeze({ name = "Coin Rush", icon = "🔥", coins = 3 }),
			partyTime = table.freeze({ name = "Party Time", icon = "🎉", speed = 1.5, coins = 1.5 }),
			dailyGift = table.freeze({ name = "Daily Gift", icon = "📅", speed = 1.5 }),
		}),
		maxStackedDuration = 4 * HOUR,
	}),

	daily = table.freeze({
		dayLength = DAY,
		graceWindow = 2 * DAY,
		rewards = table.freeze({
			{ day = 1, label = "Day 1", grant = { coins = 500 } },
			{ day = 2, label = "Day 2", grant = { coins = 1500 } },
			{ day = 3, label = "Day 3", grant = { boost = { id = "dailyGift", duration = 900 } } },
			{ day = 4, label = "Day 4", grant = { coins = 5000 } },
			{ day = 5, label = "Day 5", grant = { boost = { id = "coinRush", duration = 900 } } },
			{ day = 6, label = "Day 6", grant = { coins = 15000 } },
			{
				day = 7,
				label = "Day 7",
				grant = { coins = 40000, boost = { id = "speedRush", duration = 1800 } },
			},
		}),
	}),

	sessionChest = table.freeze({
		key = "sessionChest",
		interval = 300,
		label = "Session Chest",
		grant = { coins = 750 },
	}),

	codes = table.freeze({
		{ code = "FIRSTRUN", label = "Launch", grant = { coins = 2500 } },
		{ code = "DOUBLEJUMP", label = "Thanks", grant = { coins = 1000 } },
		{ code = "CHECKPOINT", label = "Tip", grant = { boost = { id = "speedRush", duration = 600 } } },
	}),

	--[[
		Codes for balancing the game, redeemed in the Gifts window like any other.

		They are REPEATABLE, so an upgrade curve can be walked as many times as it
		takes, and they exist only when the server is started with `devMode` — which
		Bootstrap only does inside Studio. A published server never knows them, so
		there is nothing to remember to remove before shipping.
	]]
	devCodes = table.freeze({
		{ code = "DEVCOINS", label = "Dev", repeatable = true, grant = { coins = 1000000 } },
		{ code = "DEVSPEED", label = "Dev", repeatable = true, grant = { speed = 20000 } },
		{ code = "DEVPRESTIGE", label = "Dev", repeatable = true, grant = { prestiges = 1 } },
		{
			code = "DEVBOOST",
			label = "Dev",
			repeatable = true,
			grant = { boost = { id = "speedRush", duration = 1800 } },
		},
	}),

	offers = table.freeze({
		{
			id = "starterPack",
			productKey = "starterPack",
			title = "Starter Pack",
			description = "5 000 Coins and 30 min of x2 speed",
			triggerAfterSeconds = 240,
			durationSeconds = 900,
			oncePerProfile = true,
		},
		{
			id = "gateOffer",
			productKey = "coinsMedium",
			title = "Stuck at the gate?",
			description = "8 000 Coins to buy your way past it",
			trigger = "gateBlocked",
			durationSeconds = 600,
		},
	}),
})
