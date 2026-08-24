--!strict
--[[
	Notifications — short lived messages stacked near the top of the screen.

	They sit BELOW the Roblox top bar, not at the very top: the ScreenGui ignores the
	GUI inset, so anything drawn in the first pixels of the screen hides behind the
	platform bar and the message is never seen.

	The toast is coloured by what it means, so a refusal and a reward do not have to
	be read to be told apart.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Notifications = {}
Notifications.__index = Notifications

local COLORS = {
	info = Theme.color.info,
	success = Theme.color.positive,
	warning = Theme.color.accent,
	error = Theme.color.negative,
}

local LIFETIME = 3.5
-- The platform bar is a fixed 36 real pixels; this is written in design pixels and
-- clears it comfortably at every scale the interface allows.
local TOP_BAR_CLEARANCE = 64

function Notifications.new(parent: Instance)
	local container = Instance.new("Frame")
	container.Name = "Notifications"
	container.Size = UDim2.fromOffset(500, 260)
	container.Position = UDim2.new(0.5, 0, 0, TOP_BAR_CLEARANCE)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	Widgets.list(container, { padding = 8, horizontalAlignment = Enum.HorizontalAlignment.Center })

	return setmetatable({ container = container, order = 0 }, Notifications)
end

function Notifications.push(self, message: string, kind: string?)
	self.order += 1

	local toast = Widgets.card(self.container, {
		name = "Message",
		size = UDim2.new(1, 0, 0, 52),
		color = COLORS[kind or "info"] or Theme.color.info,
		radius = Theme.radius.chip,
	})
	toast.ZIndex = 20
	toast.LayoutOrder = self.order
	Widgets.padding(toast, 10)
	Widgets.gradient(toast)

	local text = Widgets.label(toast, {
		text = message,
		align = Enum.TextXAlignment.Center,
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.textOnColor,
		outline = true,
		wrapped = true,
	})
	text.ZIndex = 21

	task.delay(LIFETIME, function()
		if not toast.Parent then
			return
		end
		local fade = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

return Notifications
