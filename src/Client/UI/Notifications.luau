--!strict
--[[
	Notifications — short lived messages stacked near the top of the screen.

	They sit BELOW the Roblox top bar, not at the very top: the ScreenGui ignores the
	GUI inset, so anything within the first ~90 pixels is hidden behind the platform
	bar and the message is never seen.
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
-- The Roblox top bar is 36 px, plus a margin so a toast never touches it.
local TOP_BAR_CLEARANCE = 96

function Notifications.new(parent: ScreenGui)
	local container = Instance.new("Frame")
	container.Name = "Notifications"
	container.Size = UDim2.fromOffset(460, 240)
	container.Position = UDim2.new(0.5, 0, 0, TOP_BAR_CLEARANCE)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	Widgets.list(container, { padding = 6, horizontalAlignment = Enum.HorizontalAlignment.Center })

	return setmetatable({ container = container, order = 0 }, Notifications)
end

function Notifications.push(self, message: string, kind: string?)
	self.order += 1

	local toast = Widgets.card(self.container, {
		name = "Message",
		size = UDim2.new(1, 0, 0, 46),
		transparency = 0.05,
	})
	toast.ZIndex = 20
	toast.LayoutOrder = self.order
	Widgets.padding(toast, 8)

	Widgets.label(toast, {
		text = message,
		align = Enum.TextXAlignment.Center,
		font = Theme.font.number,
		color = COLORS[kind or "info"] or Theme.color.text,
		wrapped = true,
	})

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
