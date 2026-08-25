--!strict
--[[
	Hud — what stays on screen.

	NOTHING IS DRAWN IN THE TOP LEFT. That corner belongs to Roblox: the menu, the
	chat and the voice controls live there, and anything of ours put behind them is
	either hidden or in the way. Everything gathers at the bottom instead, in one
	cluster the eye finds once and never has to search for again.

	No counter sits in a panel of its own. A panel would eat the world; a thick
	black stroke on the glyphs keeps a number readable over anything the map puts
	behind it, and costs no screen space at all.

	Every word and every icon comes from the theme: this file hardcodes no noun and
	no asset id.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Hud = {}
Hud.__index = Hud

local LABELS = Config.Theme.labels
local ICONS = Config.Theme.icons

local BAR_INSET = 20
local GAUGE_HEIGHT = 16
local GAUGE_WIDTH = 76 -- a single continuous gauge, such as a cooldown
local SEGMENT_WIDTH = 34 -- one charge, when there are several
local GAUGE_GAP = 4
local DASH_COOLDOWN = Config.Balance.dash.cooldown
local REBIRTHS_PER_WORLD = math.max(Config.Balance.prestige.rebirthsPerWorld or 1, 1)

--[[
	One readout: a rounded chip carrying an icon and a value.

	It has no position and no width of its own. The row lays it out, and it grows
	to fit its content, so a six figure Coin count does not overflow a box sized
	for three. A chip hidden because the thing it reports does not exist yet leaves
	the layout entirely and the row recentres itself.
]]
local function chip(parent: Instance, options)
	local frame = Widgets.card(parent, {
		name = options.name,
		size = UDim2.fromOffset(0, 46),
		color = Theme.color.panel,
		transparency = 0.12,
		radius = Theme.radius.chip,
		visible = false,
	})
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.LayoutOrder = options.layoutOrder or 0

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = frame

	Widgets.list(frame, {
		direction = Enum.FillDirection.Horizontal,
		padding = 8,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	Widgets.icon(frame, {
		image = options.image,
		fallback = options.fallback,
		size = UDim2.fromOffset(28, 28),
		layoutOrder = 1,
	})

	local value = Widgets.label(frame, {
		name = "Value",
		size = UDim2.fromOffset(0, 30),
		font = Theme.font.number,
		textSize = Theme.text.big,
		align = Enum.TextXAlignment.Left,
		color = Theme.color.text,
		layoutOrder = 2,
	})
	value.AutomaticSize = Enum.AutomaticSize.X

	return { frame = frame, value = value }
end

--[[
	The Rebirth readout, and the only thing on screen that is allowed to be loud.

	It reports the one number a player shows other players. Everything else on the
	HUD answers a question they asked themselves — how much, how far, can I dash yet
	— and is drawn to be read and forgotten. This one is a rank, so it is built like
	a badge: filled rather than pale, gradient rather than flat, with the multiplier
	on a plate of its own.

	IT IS ALSO THE ONLY PLACE THE INTERFACE SAYS WHICH WORLD THE PLAYER IS IN, and it
	says it without a word. The count is the rebirths taken; the colour is the world
	those rebirths bought. A player who has never seen a violet chip knows there is
	one, which is worth more than a label reading "World 3".

	The world is derived here rather than published: it is the rebirth count divided
	by how many a world takes, and both of those already crossed the wire.
]]
local function rebirthChip(parent: Instance, options)
	--[[
		Two frames, not one. The outer carries the fill, the gradient and the shape;
		the inner arranges the contents. They are split because the sweep that
		celebrates a rebirth is a child laid OVER the badge, and a child of anything
		holding a UIListLayout is laid out INSIDE it — one more item in the row,
		sized to the whole chip, which on an auto-sizing chip grows the chip to fit
		the band and the band to fit the chip. That is a blue slab across the bottom
		of the screen, which is exactly what it was.
	]]
	local frame = Widgets.card(parent, {
		name = "Rebirth",
		size = UDim2.fromOffset(0, 46),
		color = Theme.worlds[1][1],
		radius = Theme.radius.chip,
		visible = false,
	})
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.LayoutOrder = options.layoutOrder or 0

	-- Top to bottom, the two colours of the world. A flat fill at this size reads as
	-- a sticker; the gradient is what makes it read as a made object.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Parent = frame

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.fromOffset(0, 46)
	content.AutomaticSize = Enum.AutomaticSize.X
	content.BackgroundTransparency = 1
	content.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = content

	Widgets.list(content, {
		direction = Enum.FillDirection.Horizontal,
		padding = 8,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	Widgets.icon(content, {
		image = options.image,
		fallback = options.fallback,
		size = UDim2.fromOffset(28, 28),
		layoutOrder = 1,
	})

	local count = Widgets.label(content, {
		name = "Count",
		size = UDim2.fromOffset(0, 30),
		font = Theme.font.title,
		textSize = Theme.text.big,
		align = Enum.TextXAlignment.Left,
		color = Theme.color.textOnColor,
		outline = Theme.stroke.textHeavy,
		layoutOrder = 2,
	})
	count.AutomaticSize = Enum.AutomaticSize.X

	-- The multiplier gets a plate of its own because it is a different KIND of fact
	-- from the count: one is how far the player has come, the other is what it is
	-- worth from now on. Run together they read as one long number.
	local plate = Instance.new("Frame")
	plate.Name = "Multiplier"
	plate.Size = UDim2.fromOffset(0, 30)
	plate.AutomaticSize = Enum.AutomaticSize.X
	plate.BackgroundColor3 = Color3.new(0, 0, 0)
	plate.BackgroundTransparency = 0.72
	plate.BorderSizePixel = 0
	plate.LayoutOrder = 3
	plate.Parent = content
	Widgets.corner(plate, Theme.radius.chip)

	local platePadding = Instance.new("UIPadding")
	platePadding.PaddingLeft = UDim.new(0, 10)
	platePadding.PaddingRight = UDim.new(0, 10)
	platePadding.Parent = plate

	local multiplier = Widgets.label(plate, {
		name = "Value",
		size = UDim2.fromOffset(0, 30),
		font = Theme.font.number,
		textSize = Theme.text.body,
		align = Enum.TextXAlignment.Center,
		color = Theme.color.textOnColor,
		layoutOrder = 1,
	})
	multiplier.AutomaticSize = Enum.AutomaticSize.X

	local badge = { frame = frame, count = count, multiplier = multiplier, world = 0 }

	--[[ Repaints for a world, and only when the world actually changed. ]]
	function badge.setWorld(index: number)
		local clamped = math.clamp(index, 1, #Theme.worlds)
		if badge.world == clamped then
			return
		end
		badge.world = clamped

		local pair = Theme.worlds[clamped]
		frame.BackgroundColor3 = pair[1]
		gradient.Color = ColorSequence.new(pair[1], pair[2])
	end

	return badge
end

--[[
	An ability readout: the icon, then a gauge that empties and refills.

	A gauge instead of "1/2" and a countdown because neither is READ during a jump.
	A bar is a shape the eye takes in without parsing, and both of these are only
	ever consulted while the hands are busy.

	`segments` is how many discrete charges the gauge holds. One segment is a
	continuous fill, which is what a cooldown is; several are one charge each, which
	is what air jumps are — and 1/2 as two boxes needs no reading at all.
]]
local function gaugeChip(parent: Instance, options)
	local frame = Widgets.card(parent, {
		name = options.name,
		size = UDim2.fromOffset(0, 46),
		color = Theme.color.panel,
		transparency = 0.12,
		radius = Theme.radius.chip,
		visible = false,
	})
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.LayoutOrder = options.layoutOrder or 0

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = frame

	Widgets.list(frame, {
		direction = Enum.FillDirection.Horizontal,
		padding = 8,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	Widgets.icon(frame, {
		image = options.image,
		fallback = options.fallback,
		size = UDim2.fromOffset(28, 28),
		layoutOrder = 1,
	})

	local track = Instance.new("Frame")
	track.Name = "Gauge"
	track.Size = UDim2.fromOffset(0, GAUGE_HEIGHT)
	track.AutomaticSize = Enum.AutomaticSize.X
	track.BackgroundTransparency = 1
	track.LayoutOrder = 2
	track.Parent = frame
	Widgets.list(track, {
		direction = Enum.FillDirection.Horizontal,
		padding = GAUGE_GAP,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	local gauge = { frame = frame, segments = {}, container = track, color = options.color }

	--[[
		Rebuilds the segments when the number of charges changes.

		Buying an air jump has to change the shape of the gauge, and there is no
		sensible way to animate a box into existence — it simply has one more.
	]]
	function gauge.resize(count: number)
		if #gauge.segments == count then
			return
		end

		for _, segment in gauge.segments do
			segment.instance:Destroy()
		end
		gauge.segments = {}

		local width = if count > 1 then SEGMENT_WIDTH else GAUGE_WIDTH
		for index = 1, count do
			local bar = Widgets.bar(track, {
				size = UDim2.fromOffset(width, GAUGE_HEIGHT),
				color = gauge.color,
				trackColor = Theme.color.background,
				outline = false,
				rim = 2,
			})
			bar.instance.LayoutOrder = index
			table.insert(gauge.segments, bar)
		end
	end

	--[[ Spreads a single ratio across however many segments there are. ]]
	function gauge.set(ratio: number)
		local count = #gauge.segments
		if count == 0 then
			return
		end

		local filled = math.clamp(ratio, 0, 1) * count
		for index, segment in gauge.segments do
			segment.set(math.clamp(filled - (index - 1), 0, 1))
		end
	end

	return gauge
end

function Hud.new(parent: Instance, state)
	local self = setmetatable({ state = state }, Hud)

	-- The run, centre bottom: the bar the player watches fill.
	self.stageBar = Widgets.bar(parent, {
		name = "LevelProgress",
		size = UDim2.fromOffset(480, 40),
		position = UDim2.new(0.5, 0, 1, -18),
		anchorPoint = Vector2.new(0.5, 1),
		color = Theme.color.info,
	})

	self.stageLabel = Widgets.label(self.stageBar.instance, {
		name = "Level",
		-- Clear of the rounded cap: the glyphs must stay in the middle band, where
		-- the shape is at full width.
		size = UDim2.new(0.5, -BAR_INSET, 1, 0),
		position = UDim2.fromOffset(BAR_INSET, 0),
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.textOnColor,
		outline = true,
	})
	self.stageLabel.ZIndex = 3

	-- Progress reads "331/1K" followed by the speed icon: the unit is shown, never
	-- spelled. The pair hangs from a right anchor and grows leftwards, so a long
	-- number reaches into the bar instead of off the end of it.
	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.Size = UDim2.fromOffset(0, 30)
	progress.AutomaticSize = Enum.AutomaticSize.X
	progress.Position = UDim2.new(1, -BAR_INSET, 0.5, 0)
	progress.AnchorPoint = Vector2.new(1, 0.5)
	progress.BackgroundTransparency = 1
	progress.ZIndex = 3
	progress.Parent = self.stageBar.instance
	Widgets.list(progress, {
		direction = Enum.FillDirection.Horizontal,
		padding = 6,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	self.stageValue = Widgets.label(progress, {
		name = "Value",
		size = UDim2.fromOffset(0, 30),
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.textOnColor,
		outline = true,
		layoutOrder = 1,
	})
	self.stageValue.AutomaticSize = Enum.AutomaticSize.X
	self.stageValue.ZIndex = 3

	local speedIcon = Widgets.icon(progress, {
		name = "LevelIcon",
		image = LABELS.level.image,
		fallback = LABELS.level.icon,
		size = UDim2.fromOffset(26, 26),
		layoutOrder = 2,
	})
	speedIcon.ZIndex = 3

	-- Everything else, in one centred row just above the bar.
	local row = Instance.new("Frame")
	row.Name = "Status"
	row.Size = UDim2.fromOffset(0, 46)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Position = UDim2.new(0.5, 0, 1, -68)
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.BackgroundTransparency = 1
	row.Parent = parent
	Widgets.list(row, {
		direction = Enum.FillDirection.Horizontal,
		padding = 8,
		horizontalAlignment = Enum.HorizontalAlignment.Center,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	-- Coins sit apart, bottom left. They are consulted rather than watched: the
	-- question they answer is "can I afford it", asked on the way to the shop, not
	-- during a jump. Keeping them out of the centre row also keeps that row for
	-- what changes second by second.
	self.coins = chip(parent, {
		name = "Coins",
		image = LABELS.coins.image,
		fallback = LABELS.coins.icon,
	})
	self.coins.frame.Position = UDim2.new(0, 18, 1, -18)
	self.coins.frame.AnchorPoint = Vector2.new(0, 1)

	-- Coins are the number that moves most often, so they are the number that has
	-- to move well: it travels to the new total and punches when it grows.
	self.setCoins = Motion.roll(self.coins.value, {
		onGrow = function()
			Motion.pop(self.coins.value, 0.14)
		end,
	})

	self.prestige = rebirthChip(row, {
		image = LABELS.prestige.image,
		fallback = LABELS.prestige.icon,
		layoutOrder = 1,
	})
	self.shownPrestiges = nil

	self.jump = gaugeChip(row, {
		name = "Jump",
		image = ICONS.jump,
		fallback = "^",
		color = Theme.color.info,
		layoutOrder = 2,
	})

	self.dash = gaugeChip(row, {
		name = "Dash",
		image = ICONS.dash,
		fallback = ">>",
		color = Theme.color.positive,
		layoutOrder = 3,
	})

	-- The server publishes the cooldown every sampling tick, which is far too
	-- coarse to refill a bar with. The remaining time is counted down locally
	-- between publishes and resynced by each one.
	self.dashRemaining = 0
	RunService.RenderStepped:Connect(function(deltaTime)
		self:_drainDash(deltaTime)
	end)

	self.boosts = chip(row, {
		name = "Boosts",
		image = ICONS.boost,
		fallback = "*",
		layoutOrder = 4,
	})

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function Hud.render(self)
	local state = self.state

	-- The bar reads as a rank, not as a place on the map. Stage names still gate
	-- the course and multiply the Coins; they are simply not what a player watches
	-- while running.
	local level = math.max(state:get("Level"), 1)
	self.stageLabel.Text = `{LABELS.level.name} {level}`
	self.stageValue.Text =
		`{Format.abbreviate(state:get("LevelCurrent"))}/{Format.abbreviate(state:get("LevelRequired"))}`
	self.stageBar.set(state:get("LevelProgress"))

	--[[
		A level is the one thing a running player earns that they did not ask for, and
		it arrives while they are looking at the world rather than at the bar. It gets
		the loudest thing the interface has, and almost nothing else does.
	]]
	if self.shownLevel and level > self.shownLevel then
		Motion.pop(self.stageLabel, 0.28)
		Motion.shine(self.stageBar.instance)
	end
	self.shownLevel = level

	self.coins.frame.Visible = true
	self.setCoins(state:get("Coins"))

	-- A player who has never prestiged has nothing to read here, and a "0" only
	-- raises the question of what it is for.
	local prestiges = state:get("Prestiges")
	self.prestige.frame.Visible = prestiges > 0
	if self.prestige.frame.Visible then
		self.prestige.count.Text = tostring(prestiges)
		self.prestige.multiplier.Text = Format.multiplier(state:get("SpeedMultiplier"))
		-- Seven rebirths to a world, and the count already crossed the wire.
		self.prestige.setWorld(prestiges // REBIRTHS_PER_WORLD + 1)

		if self.shownPrestiges and prestiges > self.shownPrestiges then
			Motion.pop(self.prestige.frame, 0.25)
			Motion.shine(self.prestige.frame)
		end
	end
	self.shownPrestiges = prestiges

	-- Level 1 is the jump everybody already has: there is no air jump to count.
	local jumpLevel = math.max(state:get("JumpLevel"), 1)
	local capacity = jumpLevel - 1
	self.jump.frame.Visible = capacity > 0
	if self.jump.frame.Visible then
		self.jump.resize(capacity)
		self.jump.set(state:get("JumpsLeft") / capacity)
	end

	self.dash.frame.Visible = state:flag("DashUnlocked")
	if self.dash.frame.Visible then
		self.dash.resize(1)
		-- Resynced from the server, then counted down locally until the next one.
		self.dashRemaining = state:get("DashCooldown")
		self:_drainDash(0)
	end

	local parts = {}
	for _, boost in state:list("ActiveBoosts") do
		table.insert(parts, `{math.ceil((boost.remaining or 0) / 60)}m`)
	end
	self.boosts.frame.Visible = #parts > 0
	self.boosts.value.Text = table.concat(parts, " ")
end

--[[
	Empties the dash gauge and refills it in real time.

	Full means ready. It drains to nothing the moment the dash is spent and climbs
	back over the cooldown, so the answer to "can I dash yet" is a shape rather than
	a number to read and subtract.
]]
function Hud._drainDash(self, deltaTime: number)
	if not self.dash.frame.Visible then
		return
	end

	local before = self.dashRemaining
	self.dashRemaining = math.max(self.dashRemaining - deltaTime, 0)
	self.dash.set(1 - self.dashRemaining / DASH_COOLDOWN)

	-- The moment it becomes usable again, said as a wash of colour rather than a
	-- full bar the player has to notice is full. It fires on the crossing, so a
	-- gauge that was already full stays quiet.
	if before > 0 and self.dashRemaining <= 0 then
		Motion.flash(self.dash.frame, Theme.color.positive)
	end
end

return Hud
