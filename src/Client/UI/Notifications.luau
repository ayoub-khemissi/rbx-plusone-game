--!strict
--[[
	Notifications — short lived messages stacked near the top of the screen.

	They sit BELOW the Roblox top bar, not at the very top: the ScreenGui ignores the
	GUI inset, so anything drawn in the first pixels of the screen hides behind the
	platform bar and the message is never seen.

	The toast is coloured by what it means, so a refusal and a reward do not have to
	be read to be told apart. It is also sized to be read WHILE RUNNING, at a glance
	and without stopping — which is the only way any of these are ever read.

	And it is only as WIDE as what it says. A full-width bar around the word
	A short word reads as a banner rather than as a message, and covers more of the
	course than the message is worth.

	THE STACK IS A PERSPECTIVE, NOT A LIST. The newest message sits on top at full
	size; the ones under it shrink and fade with depth, and only three are ever
	visible. Coins, stages and boosts can all fire within a second of each
	other, and an unbounded stack would walk down the screen and bury the game. The
	depth ranking also answers "which of these just happened" without reading any of
	them.
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

--[[
	One entry per visible depth. Anything pushed past the last one is dropped, so
	adding a fourth row here is all it takes to show four.
]]
local DEPTHS = {
	{ height = 66, textSize = Theme.text.title, faded = 0 },
	{ height = 56, textSize = Theme.text.big, faded = 0.3 },
	{ height = 48, textSize = Theme.text.body, faded = 0.55 },
}

-- A toast is only as wide as what it says. The cap stops one long message from
-- reaching across the screen; past it the text truncates rather than spilling.
local MAX_WIDTH = 520
local SIDE_PADDING = 22

local SETTLE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DISMISS = TweenInfo.new(0.3)

local function tween(instance: Instance?, goal: { [string]: any })
	if instance then
		TweenService:Create(instance :: any, SETTLE, goal):Play()
	end
end

function Notifications.new(parent: Instance)
	local container = Instance.new("Frame")
	container.Name = "Notifications"
	container.Size = UDim2.fromOffset(580, 260)
	container.Position = UDim2.new(0.5, 0, 0, TOP_BAR_CLEARANCE)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	Widgets.list(container, { padding = 8, horizontalAlignment = Enum.HorizontalAlignment.Center })

	return setmetatable({ container = container, stack = {} }, Notifications)
end

--[[ Sends every toast to the look of its current depth. ]]
function Notifications.restack(self)
	for index, entry in self.stack do
		local depth = DEPTHS[index]
		if depth then
			-- The layout sorts ascending, so the newest message owns the top slot.
			entry.card.LayoutOrder = index
			-- Only the height is driven. The width belongs to the text, and a tween
			-- fighting AutomaticSize would snap between the two every frame.
			tween(entry.card, {
				Size = UDim2.fromOffset(0, depth.height),
				BackgroundTransparency = depth.faded,
			})
			tween(entry.cardStroke, { Transparency = depth.faded })
			tween(entry.label, {
				Size = UDim2.fromOffset(0, depth.height),
				TextSize = depth.textSize,
				TextTransparency = depth.faded,
			})
			tween(entry.labelStroke, { Transparency = depth.faded })
		end
	end
end

function Notifications.dismiss(self, entry)
	if not entry.alive then
		return
	end
	entry.alive = false

	for index, candidate in self.stack do
		if candidate == entry then
			table.remove(self.stack, index)
			break
		end
	end

	local card = entry.card
	TweenService:Create(card, DISMISS, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(entry.label, DISMISS, { TextTransparency = 1 }):Play()
	if entry.cardStroke then
		TweenService:Create(entry.cardStroke, DISMISS, { Transparency = 1 }):Play()
	end
	if entry.labelStroke then
		TweenService:Create(entry.labelStroke, DISMISS, { Transparency = 1 }):Play()
	end

	task.delay(DISMISS.Time, function()
		card:Destroy()
	end)

	self:restack()
end

function Notifications.push(self, message: string, kind: string?)
	local toast = Widgets.card(self.container, {
		name = "Message",
		size = UDim2.fromOffset(0, DEPTHS[1].height),
		color = COLORS[kind or "info"] or Theme.color.info,
		radius = Theme.radius.chip,
	})
	toast.ZIndex = 20
	toast.AutomaticSize = Enum.AutomaticSize.X
	Widgets.gradient(toast)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, SIDE_PADDING)
	padding.PaddingRight = UDim.new(0, SIDE_PADDING)
	padding.Parent = toast

	local text = Widgets.label(toast, {
		text = message,
		size = UDim2.fromOffset(0, DEPTHS[1].height),
		align = Enum.TextXAlignment.Center,
		font = Theme.font.number,
		textSize = DEPTHS[1].textSize,
		color = Theme.color.textOnColor,
		outline = true,
	})
	text.ZIndex = 21
	text.AutomaticSize = Enum.AutomaticSize.X
	text.TextTruncate = Enum.TextTruncate.AtEnd

	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(MAX_WIDTH, math.huge)
	cap.Parent = text

	local entry = {
		card = toast,
		label = text,
		-- The strokes are built inside the widgets; fading a toast without them
		-- would leave two crisp outlines floating over the world.
		cardStroke = toast:FindFirstChildOfClass("UIStroke"),
		labelStroke = text:FindFirstChildOfClass("UIStroke"),
		alive = true,
	}

	table.insert(self.stack, 1, entry)

	-- Anything past the last depth has nowhere to be drawn: it goes now rather than
	-- waiting out a lifetime nobody can see.
	while #self.stack > #DEPTHS do
		self:dismiss(self.stack[#self.stack])
	end

	self:restack()

	task.delay(LIFETIME, function()
		self:dismiss(entry)
	end)
end

return Notifications
