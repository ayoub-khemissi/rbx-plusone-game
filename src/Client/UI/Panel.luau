--!strict
--[[
	Panel — the shared shell of every window (title, close button, content).

	A window is a bright card laid over the world with a heavy outline, a title big
	enough to read across the room, and a close button no one has to hunt for. Views
	fill `content` and never draw their own frame.
]]

local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Panel = {}
Panel.__index = Panel

local HEADER = 62

function Panel.new(parent: Instance, options)
	local frame = Widgets.card(parent, {
		name = options.name or "Window",
		size = options.size or UDim2.fromOffset(560, 460),
		position = UDim2.fromScale(0.5, 0.5),
		anchorPoint = Vector2.new(0.5, 0.5),
		-- The one place the grain belongs: a window is large, and its padding lives
		-- on the content frame rather than on the card.
		pattern = true,
		visible = false,
	})
	frame.ZIndex = 5

	local header = Widgets.label(frame, {
		name = "Title",
		size = UDim2.new(1, -80, 0, HEADER - 14),
		position = UDim2.fromOffset(24, 12),
		font = Theme.font.title,
		textSize = options.titleSize or Theme.text.title,
		color = Theme.color.textOnColor,
		outline = Theme.stroke.textHeavy,
		text = options.title or "",
	})
	header.ZIndex = 6

	-- Straddling the corner is deliberate: it is the one control a player looks for
	-- without reading, and it must never hide behind the content.
	local close = Widgets.button(frame, {
		name = "Close",
		text = "X",
		size = UDim2.fromOffset(46, 46),
		position = UDim2.new(1, -6, 0, -6),
		anchorPoint = Vector2.new(1, 0),
		color = Theme.color.negative,
		radius = Theme.radius.chip,
		textSize = Theme.text.big,
	})
	close.ZIndex = 7

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -36, 1, -(HEADER + 20))
	content.Position = UDim2.fromOffset(18, HEADER)
	content.BackgroundTransparency = 1
	content.ZIndex = 6
	content.Parent = frame

	local self = setmetatable({ frame = frame, content = content, isOpen = false, onOpen = nil }, Panel)

	close.Activated:Connect(function()
		self:close()
	end)

	return self
end

function Panel.open(self)
	self.isOpen = true
	self.frame.Visible = true
	-- Grown from the button that opened it, rather than blinked into place: the
	-- window has to read as having come from somewhere.
	Motion.appear(self.frame)
	if self.onOpen then
		self.onOpen()
	end
end

function Panel.close(self)
	self.isOpen = false
	self.frame.Visible = false
end

function Panel.toggle(self)
	if self.isOpen then
		self:close()
	else
		self:open()
	end
end

return Panel
