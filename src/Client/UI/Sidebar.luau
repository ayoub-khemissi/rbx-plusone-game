--!strict
--[[
	Sidebar — the column of buttons opening the windows of the game.

	Each button carries its icon AND its name. An icon alone is a guess: the caption
	is what turns a row of coloured squares into a menu a first-time player can read.
]]

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Sidebar = {}

local BUTTON = 76
local CAPTION = 20
local GAP = 10

function Sidebar.new(parent: Instance, entries)
	local container = Instance.new("Frame")
	container.Name = "Sidebar"
	container.Size = UDim2.fromOffset(BUTTON, #entries * (BUTTON + CAPTION) + (#entries - 1) * GAP)
	container.Position = UDim2.new(0, 18, 0.5, 0)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = parent

	Widgets.list(container, { padding = GAP })

	for index, entry in entries do
		local slot = Instance.new("Frame")
		slot.Name = entry.name
		slot.Size = UDim2.fromOffset(BUTTON, BUTTON + CAPTION)
		slot.BackgroundTransparency = 1
		slot.LayoutOrder = index
		slot.Parent = container

		local button = Widgets.button(slot, {
			name = "Open",
			text = if entry.image then "" else entry.icon,
			size = UDim2.fromOffset(BUTTON, BUTTON),
			color = entry.color or Theme.color.info,
			textSize = Theme.text.title,
			onClick = entry.onClick,
		})

		if entry.image then
			local icon = Widgets.icon(button, {
				image = entry.image,
				size = UDim2.fromOffset(52, 52),
				position = UDim2.fromScale(0.5, 0.5),
				anchorPoint = Vector2.new(0.5, 0.5),
			}); -- The icon must not swallow the click meant for the button under it.
			(icon :: any).Active = false
		end

		Widgets.label(slot, {
			name = "Caption",
			size = UDim2.new(1, 0, 0, CAPTION),
			position = UDim2.fromOffset(0, BUTTON),
			font = Theme.font.number,
			textSize = Theme.text.small,
			align = Enum.TextXAlignment.Center,
			color = Theme.color.textOnColor,
			outline = true,
			text = entry.name,
		})
	end

	return container
end

return Sidebar
