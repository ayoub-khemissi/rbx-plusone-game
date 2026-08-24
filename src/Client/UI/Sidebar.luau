--!strict
--[[ Sidebar — the column of buttons opening the windows of the game. ]]

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Sidebar = {}

function Sidebar.new(parent: ScreenGui, entries)
	local container = Instance.new("Frame")
	container.Name = "Sidebar"
	container.Size = UDim2.fromOffset(72, 400)
	container.Position = UDim2.new(0, 14, 0.5, 0)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = parent

	Widgets.list(container, { padding = 8 })

	for index, entry in entries do
		local button = Widgets.button(container, {
			name = entry.name,
			text = if entry.image then "" else entry.icon,
			size = UDim2.fromOffset(64, 64),
			color = entry.color or Theme.color.panel,
			textColor = Theme.color.text,
			layoutOrder = index,
			onClick = entry.onClick,
		})
		Widgets.stroke(button, Theme.color.accent, 2)

		if entry.image then
			local icon = Widgets.icon(button, {
				image = entry.image,
				size = UDim2.fromOffset(44, 44),
				position = UDim2.fromScale(0.5, 0.5),
				anchorPoint = Vector2.new(0.5, 0.5),
			}); -- The icon must not swallow the click meant for the button under it.
			(icon :: any).Active = false
		end
	end

	return container
end

return Sidebar
