--!strict
--[[ Theme — identite visuelle : jungle chaude, lisible sur mobile comme sur PC. ]]

return table.freeze({
	color = table.freeze({
		background = Color3.fromRGB(22, 30, 26),
		panel = Color3.fromRGB(32, 44, 37),
		panelLight = Color3.fromRGB(44, 60, 50),
		accent = Color3.fromRGB(250, 204, 66),
		accentDark = Color3.fromRGB(214, 160, 40),
		positive = Color3.fromRGB(92, 206, 118),
		negative = Color3.fromRGB(226, 92, 84),
		info = Color3.fromRGB(96, 172, 232),
		text = Color3.fromRGB(245, 245, 238),
		textMuted = Color3.fromRGB(178, 190, 180),
		locked = Color3.fromRGB(96, 104, 98),
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
