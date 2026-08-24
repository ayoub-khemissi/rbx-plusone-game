--!strict
--[[
	Theme — the visual grammar of the interface.

	COLOURS come from the active theme in Config: repainting the whole game is a data
	change, and no view holds a hue of its own.

	EVERYTHING ELSE here — fonts, sizes, stroke weights, the scaling rule — is the
	grammar, shared by every theme. A repaint may change the mood; it can never make
	the interface unreadable.

	The look targeted is the one Roblox players already know from simulators: light
	panels wearing a thick dark outline, saturated buttons, and big numbers wearing a
	black stroke so they stay legible over a bright world.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local palette = Config.Theme.palette

--[[ A theme is allowed to leave a colour out: the fallback keeps things readable. ]]
local function color(key: string, fallback: Color3): Color3
	local entry = palette[key]
	if typeof(entry) == "table" and #entry >= 3 then
		return Color3.fromRGB(entry[1], entry[2], entry[3])
	end
	return fallback
end

return table.freeze({
	color = table.freeze({
		panel = color("panel", Color3.fromRGB(250, 249, 246)),
		panelSoft = color("panelSoft", Color3.fromRGB(233, 231, 226)),
		panelEdge = color("panelEdge", Color3.fromRGB(46, 50, 72)),
		panelLight = color("panelSoft", Color3.fromRGB(233, 231, 226)),
		background = color("background", Color3.fromRGB(30, 34, 52)),

		outline = color("outline", Color3.fromRGB(20, 22, 34)),
		text = color("text", Color3.fromRGB(52, 56, 78)),
		textMuted = color("textMuted", Color3.fromRGB(122, 128, 150)),
		textOnColor = color("textOnColor", Color3.fromRGB(255, 255, 255)),

		accent = color("accent", Color3.fromRGB(247, 197, 37)),
		accentDark = color("accentDark", Color3.fromRGB(206, 152, 16)),
		info = color("info", Color3.fromRGB(59, 178, 240)),
		positive = color("positive", Color3.fromRGB(92, 201, 74)),
		negative = color("negative", Color3.fromRGB(229, 51, 60)),
		special = color("special", Color3.fromRGB(150, 60, 220)),
		locked = color("locked", Color3.fromRGB(152, 156, 172)),
	}),

	texture = table.freeze({
		panelPattern = Config.Theme.textures and Config.Theme.textures.panelPattern,
	}),

	--[[
		FredokaOne carries the simulator look but only Latin glyphs: a symbol it does
		not have is drawn as nothing at all, which is how a close button ends up an
		empty red circle. It is reserved for text whose characters are known — the
		headings and the big counters — and `number` keeps a font that covers the
		dashes, arrows and currency marks a value can contain.
	]]
	font = table.freeze({
		title = Enum.Font.FredokaOne,
		body = Enum.Font.GothamMedium,
		number = Enum.Font.GothamBold,
	}),

	--[[
		Text sizes in DESIGN pixels. The global scale below turns them into real
		pixels, so a number written here means the same thing on a phone and on a
		4K monitor. Fixed sizes beat TextScaled for anything that must stay
		consistent from one row to the next.
	]]
	text = table.freeze({
		hero = 40,
		title = 30,
		big = 24,
		body = 18,
		small = 15,
	}),

	stroke = table.freeze({
		panel = 3,
		button = 2.5,
		text = 2.5,
		textHeavy = 3.5,
	}),

	radius = table.freeze({
		panel = UDim.new(0, 18),
		button = UDim.new(0, 12),
		chip = UDim.new(1, 0),
	}),

	--[[
		THE FIX FOR "everything is too small".

		The interface is drawn once for a 1280x720 screen and scaled to whatever the
		player actually has. Sizing in raw pixels without this makes a card enormous
		on a phone and lost on a large monitor — the same layout simply cannot serve
		both. Clamped at both ends so a very tall or very short viewport degrades
		instead of breaking.
	]]
	scale = table.freeze({
		referenceHeight = 720,
		minimum = 0.8,
		maximum = 1.8,
	}),
})
