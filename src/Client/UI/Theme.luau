--!strict
--[[ Theme — visual identity: bright fantasy sky, readable on mobile and desktop. ]]

return table.freeze({
	color = table.freeze({
		background = Color3.fromRGB(24, 28, 40),
		panel = Color3.fromRGB(36, 42, 60),
		panelLight = Color3.fromRGB(50, 58, 80),
		accent = Color3.fromRGB(250, 206, 110),
		accentDark = Color3.fromRGB(214, 162, 62),
		positive = Color3.fromRGB(120, 214, 150),
		negative = Color3.fromRGB(226, 96, 92),
		info = Color3.fromRGB(120, 176, 236),
		text = Color3.fromRGB(244, 244, 250),
		textMuted = Color3.fromRGB(174, 182, 200),
		locked = Color3.fromRGB(96, 102, 118),
		pouch = Color3.fromRGB(236, 168, 96),
	}),

	rarity = table.freeze({
		common = Color3.fromRGB(176, 186, 178),
		rare = Color3.fromRGB(96, 172, 232),
		epic = Color3.fromRGB(168, 112, 226),
		legendary = Color3.fromRGB(244, 196, 84),
	}),

	font = table.freeze({
		title = Enum.Font.FredokaOne,
		body = Enum.Font.GothamMedium,
		number = Enum.Font.GothamBold,
	}),

	radius = table.freeze({
		panel = UDim.new(0, 14),
		button = UDim.new(0, 10),
		chip = UDim.new(1, 0),
	}),
})
