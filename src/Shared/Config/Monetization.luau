--!strict
--[[
	Monetization — settings of the business model.

	Four pillars, each proven on Roblox:

	  1. FREE AND STICKY  : daily streak, session chest, and above all the hatchery —
	     eggs incubate in real time, even offline, which gives a reason to come back
	     tomorrow instead of paying a player to stand on a pad;
	  2. PERMANENT        : gamepasses, bought once, high perceived value;
	  3. REPEATABLE       : consumable products bought at every hard step — the main
	     source of revenue;
	  4. SOCIAL & REACH   : a server-wide festival everyone sees, promo codes that
	     spread on social media, and a timed welcome offer.

	Nothing here gates content: everything is reachable by playing.
]]

local HOUR = 3600
local DAY = 86400

return table.freeze({
	-- Rarity ladder, shared by eggs and dragons. Order matters: commonest first.
	rarities = table.freeze({
		{ rarity = "common", weight = 68, color = { 176, 186, 178 } },
		{ rarity = "rare", weight = 24, color = { 96, 172, 232 } },
		{ rarity = "epic", weight = 7, color = { 168, 112, 226 } },
		{ rarity = "legendary", weight = 1, color = { 244, 196, 84 } },
	}),

	hatchery = table.freeze({
		slots = 3,
		perchMultiplier = 2, -- staying at the Nest doubles incubation speed
		durations = table.freeze({
			common = 300,
			rare = 1200,
			epic = 5400,
			legendary = 21600,
		}),
	}),

	boosts = table.freeze({
		definitions = table.freeze({
			swiftRush = table.freeze({ name = "Swift Rush", icon = "⚡", speed = 2 }),
			goldFever = table.freeze({ name = "Gold Fever", icon = "🔥", gold = 3 }),
			skyFestival = table.freeze({ name = "Sky Festival", icon = "🎉", speed = 1.5, gold = 1.5 }),
			dailyGift = table.freeze({ name = "Daily Gift", icon = "📅", speed = 1.5 }),
		}),
		maxStackedDuration = 4 * HOUR,
	}),

	daily = table.freeze({
		dayLength = DAY,
		graceWindow = 2 * DAY,
		rewards = table.freeze({
			{ day = 1, label = "Day 1", grant = { gold = 500 } },
			{ day = 2, label = "Day 2", grant = { gold = 1500 } },
			{ day = 3, label = "Day 3", grant = { boost = { id = "dailyGift", duration = 900 } } },
			{ day = 4, label = "Day 4", grant = { eggs = { rarity = "rare", amount = 1 } } },
			{ day = 5, label = "Day 5", grant = { boost = { id = "goldFever", duration = 900 } } },
			{ day = 6, label = "Day 6", grant = { gold = 15000 } },
			{
				day = 7,
				label = "Day 7",
				grant = { gold = 40000, eggs = { rarity = "epic", amount = 1 } },
			},
		}),
	}),

	sessionChest = table.freeze({
		key = "sessionChest",
		interval = 300,
		label = "Sky Chest",
		grant = { gold = 750 },
	}),

	codes = table.freeze({
		{ code = "FIRSTFLIGHT", label = "Launch", grant = { gold = 2500 } },
		{ code = "DRAGON", label = "Thanks", grant = { gold = 1000 } },
		{ code = "ALTAR", label = "Tip", grant = { boost = { id = "swiftRush", duration = 600 } } },
	}),

	offers = table.freeze({
		{
			id = "starterPack",
			productKey = "starterPack",
			title = "Hatchling Pack",
			description = "5 000 gold, a rare egg and 30 min of x2 speed",
			triggerAfterSeconds = 240,
			durationSeconds = 900,
			oncePerProfile = true,
		},
		{
			id = "wallOffer",
			productKey = "flightInsurance",
			title = "Lost it all again?",
			description = "Keep half your pouch on your next three flights",
			trigger = "pouchLost",
			durationSeconds = 600,
		},
	}),
})
