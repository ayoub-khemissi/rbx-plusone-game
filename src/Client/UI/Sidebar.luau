--!strict
--[[
	Sidebar — the column of buttons opening the windows of the game.

	Each button carries its icon AND its name. An icon alone is a guess: the caption
	is what turns a row of coloured squares into a menu a first-time player can read.

	THE CAPTION STRADDLES THE BOTTOM EDGE, half over the button and half over the
	world, and it is a CHILD of the button rather than a label sitting under it. Both
	of those are the same decision: a child moves with whatever the button does, so
	the caption grows with it under the pointer instead of staying behind while the
	button swells away from it. Anything meant to belong to a button has to live
	inside it.

	The overhang is why the gap between buttons is what it is — half a caption hangs
	below each one, and the next button starts after that.
]]

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Sidebar = {}

local BUTTON = 76
local CAPTION = 24
-- Half a caption hangs below the button, plus room to breathe.
local GAP = CAPTION / 2 + 14

function Sidebar.new(parent: Instance, entries)
	local container = Instance.new("Frame")
	container.Name = "Sidebar"
	container.Size = UDim2.fromOffset(BUTTON, #entries * BUTTON + (#entries - 1) * GAP)
	container.Position = UDim2.new(0, 18, 0.5, 0)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = parent

	Widgets.list(container, { padding = GAP })

	for index, entry in entries do
		local button = Widgets.button(container, {
			name = entry.name,
			text = if entry.image then "" else entry.icon,
			size = UDim2.fromOffset(BUTTON, BUTTON),
			color = entry.color or Theme.color.info,
			textSize = Theme.text.title,
			layoutOrder = index,
			onClick = entry.onClick,
		})

		if entry.image then
			local icon = Widgets.icon(button, {
				image = entry.image,
				size = UDim2.fromOffset(52, 52),
				-- Pulled up by half the overhang, so the icon stays centred in the
				-- space the caption leaves rather than in the square.
				position = UDim2.new(0.5, 0, 0.5, -CAPTION / 4),
				anchorPoint = Vector2.new(0.5, 0.5),
			}); -- The icon must not swallow the click meant for the button under it.
			(icon :: any).Active = false
		end

		local caption = Widgets.label(button, {
			name = "Caption",
			-- Wider than the button: a long word spills over the sides rather than
			-- shrinking to fit a square nobody sized for it.
			size = UDim2.new(1, 28, 0, CAPTION),
			position = UDim2.fromScale(0.5, 1),
			anchorPoint = Vector2.new(0.5, 0.5),
			font = Theme.font.title,
			textSize = Theme.text.small,
			align = Enum.TextXAlignment.Center,
			color = Theme.color.textOnColor,
			-- Heavier than usual: half of it is read against the button and half
			-- against whatever the map put behind it.
			outline = Theme.stroke.textHeavy,
			text = string.upper(entry.name),
		})
		-- Over the button's own outline, and never in the way of its click.
		caption.ZIndex = button.ZIndex + 2
		caption.Active = false
	end

	return container
end

return Sidebar
