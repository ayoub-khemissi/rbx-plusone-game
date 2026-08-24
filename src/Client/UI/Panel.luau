--!strict
--[[ Panel — the shared shell of every window (title, close button, content). ]]

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Panel = {}
Panel.__index = Panel

function Panel.new(parent: ScreenGui, options)
	local frame = Widgets.card(parent, {
		name = options.name or "Window",
		size = options.size or UDim2.fromOffset(540, 440),
		position = UDim2.fromScale(0.5, 0.5),
		anchorPoint = Vector2.new(0.5, 0.5),
		transparency = 0.02,
		visible = false,
	})
	frame.ZIndex = 5

	local header = Widgets.label(frame, {
		name = "Title",
		size = UDim2.new(1, -60, 0, 44),
		position = UDim2.fromOffset(18, 10),
		font = Theme.font.title,
		color = Theme.color.accent,
		text = options.title or "",
	})
	header.ZIndex = 6

	local close = Widgets.button(frame, {
		name = "Close",
		text = "✕",
		size = UDim2.fromOffset(38, 38),
		position = UDim2.new(1, -14, 0, 14),
		anchorPoint = Vector2.new(1, 0),
		color = Theme.color.negative,
		textColor = Theme.color.text,
	})
	close.ZIndex = 6

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -28, 1, -74)
	content.Position = UDim2.fromOffset(14, 62)
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
