--!strict
--[[ Sidebar — colonne de boutons ouvrant les fenetres du jeu. ]]

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Sidebar = {}

function Sidebar.new(parent: ScreenGui, entries)
	local container = Instance.new("Frame")
	container.Name = "MenuLateral"
	container.Size = UDim2.fromOffset(72, 340)
	container.Position = UDim2.new(0, 14, 0.5, 0)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = parent

	Widgets.list(container, { padding = 8 })

	for index, entry in entries do
		local button = Widgets.button(container, {
			name = entry.name,
			text = entry.icon,
			size = UDim2.fromOffset(64, 64),
			color = entry.color or Theme.color.panel,
			textColor = Theme.color.text,
			layoutOrder = index,
			onClick = entry.onClick,
		})
		Widgets.stroke(button, Theme.color.accent, 2)
	end

	return container
end

return Sidebar
