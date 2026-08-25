--!strict
--[[
	Widgets — reusable interface bricks.

	Every view goes through here: one definition of the button, the card, the icon and
	the progress bar, so the interface stays consistent and the views stay short.

	Two rules the whole interface leans on:

	  * SIZES ARE WRITTEN IN DESIGN PIXELS, for a 1280x720 screen. `Widgets.scaled`
	    builds the single UIScale that turns them into real pixels. Nothing else in
	    the client should ever look at the viewport.

	  * TEXT OVER THE WORLD WEARS A BLACK STROKE. A sky, a lava pit and a white wall
	    all pass behind the same number; contrast against one background is not
	    enough.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Widgets = {}

--[[ A colour lifted towards white, which is what a highlight is made of. ]]
local function lift(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

--[[
	How a button answers the pointer, and it answers WITHOUT CHANGING SIZE.

	It used to grow, and growing is the wrong tool: a button that swells takes room
	from whatever is beside it. In the shop it covered the description of the row
	below; in the Rebirth window the two buttons ate each other's edges. An effect
	that changes an element's footprint will eventually collide with something,
	because the layout was measured for the element, not for the effect.

	So it lights instead. The fill lifts towards white, the outline brightens to a
	rim, and neither occupies a single pixel more than before — which means it is
	safe on anything, in any layout, forever.

	The press darkens, by hand rather than through AutoButtonColor: that property
	dims on hover as well, and would spend its time cancelling the lift.
]]
local HOVER_LIFT = 0.16
local PRESS_DROP = 0.14
local HOVER_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- How wide the transparency jump of a progress bar is, and how fast the bar chases
-- a new value. Both are shared by every bar, so they move together.
local BAR_EDGE = 0.002
local BAR_SPEED = 12

--[[
	The sheen: how a filled bar keeps looking filled rather than painted.

	A highlight crosses it, then the bar rests. The rest is the point — a shimmer
	that never stops is wallpaper within a minute, and it also means writing a
	ColorSequence on every frame forever. This writes during the sweep and once
	when it ends, which is a fifth of the time.
]]
local SHEEN_PERIOD = 3.4 -- seconds between one sweep and the next
local SHEEN_SWEEP = 0.75 -- how long a sweep takes to cross
local SHEEN_WIDTH = 0.18 -- how wide the highlight is, as a share of the bar
local SHEEN_LIFT = 0.22 -- how much lighter the left end rests than the right
local SHEEN_GLOW = 0.55 -- how much lighter the highlight is at its centre

function Widgets.corner(parent: Instance, radius: UDim?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or Theme.radius.button
	corner.Parent = parent
	return corner
end

--[[ The outline drawn around a surface: panels and buttons both wear one. ]]
function Widgets.stroke(parent: Instance, color: Color3?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.color.panelEdge
	stroke.Thickness = thickness or Theme.stroke.panel
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

--[[
	The outline drawn around the GLYPHS of a text object.

	`Contextual` on a text object strokes the letters rather than the frame, which is
	what makes a big number readable over anything the map happens to put behind it.
]]
function Widgets.textStroke(label: Instance, thickness: number?, color: Color3?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.color.outline
	stroke.Thickness = thickness or Theme.stroke.text
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return stroke
end

--[[ The soft top-to-bottom shading that makes a flat fill look moulded. ]]
function Widgets.gradient(parent: Instance, strength: number?)
	local floor = 1 - (strength or 0.22)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(floor, floor, floor)),
	})
	gradient.Parent = parent
	return gradient
end

function Widgets.padding(parent: Instance, amount: number)
	local padding = Instance.new("UIPadding")
	local offset = UDim.new(0, amount)
	padding.PaddingTop = offset
	padding.PaddingBottom = offset
	padding.PaddingLeft = offset
	padding.PaddingRight = offset
	padding.Parent = parent
	return padding
end

--[[
	The single scaling layer of the interface.

	The frame counter-scales its own size so that, once the UIScale has been applied,
	it covers exactly the viewport. Without that counter-scale a scale of 1.5 would
	push everything anchored to the right or the bottom off the screen.
]]
function Widgets.scaled(screen: ScreenGui): Frame
	local root = Instance.new("Frame")
	root.Name = "Scaled"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = root

	local function fit()
		local camera = workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		if viewport.Y <= 0 then
			return
		end

		local ratio = viewport.Y / Theme.scale.referenceHeight
		local scale = math.clamp(ratio, Theme.scale.minimum, Theme.scale.maximum)
		uiScale.Scale = scale
		root.Size = UDim2.fromScale(1 / scale, 1 / scale)
	end

	fit()
	root.Parent = screen

	-- The camera object itself is replaced on respawn, so follow the property too.
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(fit)
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	return root
end

--[[
	A seamless tile laid over a surface, to keep a flat fill from reading as paint.

	Colour alone renders as vinyl at this size; a grain under it reads as a moulded
	object, which is the look every simulator interface is after. It has to be low
	contrast and seamless — a motif with an edge in it becomes a pattern the eye
	follows instead of a texture it ignores, and text has to sit on top of it.

	`inset` CANCELS THE PARENT'S PADDING. The grain is a child, so a UIPadding on the
	surface shrinks it too, and what shows is a textured box floating inside a bare
	margin of flat colour. Giving the padding to the widget that owns the surface is
	what makes the compensation exact.

	On a button it lies over the glyphs as well, because a TextButton draws its own
	text and no child can get underneath that. At this opacity the veil is nothing;
	at a heavier one it would be the reason to move the text into a child.
]]
function Widgets.surface(parent: GuiObject, options): ImageLabel?
	if not options.image then
		return nil
	end

	local inset = options.inset or { left = 0, right = 0, top = 0, bottom = 0 }
	local grain = Instance.new("ImageLabel")
	grain.Name = "Surface"
	grain.BackgroundTransparency = 1
	grain.Image = options.image
	grain.ScaleType = Enum.ScaleType.Tile
	grain.TileSize = UDim2.fromOffset(options.tile or 64, options.tile or 64)
	grain.ImageTransparency = options.transparency or 0.92
	grain.Position = UDim2.fromOffset(-inset.left, -inset.top)
	grain.Size = UDim2.new(1, inset.left + inset.right, 1, inset.top + inset.bottom)
	grain.ZIndex = options.zIndex or 0
	grain.Active = false
	grain.Parent = parent

	Widgets.corner(grain, options.radius)
	return grain
end

function Widgets.card(parent: Instance, options): Frame
	local card = Instance.new("Frame")
	card.Name = options.name or "Card"
	card.Size = options.size
	card.Position = options.position or UDim2.fromScale(0, 0)
	card.AnchorPoint = options.anchorPoint or Vector2.zero
	card.BackgroundColor3 = options.color or Theme.color.panel
	card.BackgroundTransparency = options.transparency or 0
	card.BorderSizePixel = 0
	card.Visible = if options.visible == nil then true else options.visible
	card.Parent = parent

	local radius = options.radius or Theme.radius.panel
	Widgets.corner(card, radius)
	Widgets.stroke(card, options.edge or Theme.color.panelEdge, options.edgeThickness)

	--[[
		The tile is OPT-IN, and only windows ask for it.

		A card's padding lives on an inner content frame rather than on the card, so
		there is nothing here for the grain to compensate for; a chip that padded
		itself would have to say so.
	]]
	if options.pattern == true then
		Widgets.surface(card, {
			image = Theme.texture.panelPattern,
			radius = radius,
			tile = Theme.texture.panelTile,
			transparency = 1 - Theme.texture.panelOpacity,
		})
	end

	return card
end

--[[
	A piece of text.

	`textSize` pins a size in design pixels — preferred, because a column of rows then
	keeps one typography whatever each row is worth. Without it the text fills its
	frame, which is only ever what a single big number wants.
]]
function Widgets.label(parent: Instance, options): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = options.name or "Text"
	label.Size = options.size or UDim2.fromScale(1, 1)
	label.Position = options.position or UDim2.fromScale(0, 0)
	label.AnchorPoint = options.anchorPoint or Vector2.zero
	label.BackgroundTransparency = 1
	label.Font = options.font or Theme.font.body
	label.Text = options.text or ""
	label.TextColor3 = options.color or Theme.color.text
	label.TextXAlignment = options.align or Enum.TextXAlignment.Left
	label.TextYAlignment = options.verticalAlign or Enum.TextYAlignment.Center
	label.TextWrapped = options.wrapped or false
	label.LayoutOrder = options.layoutOrder or 0

	if options.textSize then
		label.TextScaled = false
		label.TextSize = options.textSize
	else
		label.TextScaled = if options.textScaled == nil then true else options.textScaled
	end

	label.Parent = parent

	if options.outline then
		Widgets.textStroke(label, if options.outline == true then nil else options.outline)
	end

	return label
end

function Widgets.button(parent: Instance, options): TextButton
	local button = Instance.new("TextButton")
	button.Name = options.name or "Button"
	button.Size = options.size or UDim2.fromOffset(160, 50)
	button.Position = options.position or UDim2.fromScale(0, 0)
	button.AnchorPoint = options.anchorPoint or Vector2.zero
	-- Green, not the accent. The accent is the currency colour, and a gold price on
	-- a gold button is a button nobody can read.
	button.BackgroundColor3 = options.color or Theme.color.positive
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Font = options.font or Theme.font.title
	button.Text = options.text or ""
	button.TextColor3 = options.textColor or Theme.color.textOnColor
	button.LayoutOrder = options.layoutOrder or 0

	if options.textSize then
		button.TextScaled = false
		button.TextSize = options.textSize
	else
		button.TextScaled = true
	end

	button.Parent = parent

	--[[
		A button owns its padding rather than being given one afterwards.

		Not a preference: the grain below is a child, so a UIPadding added later
		shrinks it and leaves a bare margin of flat colour around a textured box.
		Owning the padding is what lets the compensation be exact.
	]]
	local inset = {
		left = options.padding or 0,
		right = options.paddingRight or options.padding or 0,
		top = options.padding or 0,
		bottom = options.padding or 0,
	}
	if inset.left > 0 or inset.right > 0 then
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, inset.left)
		padding.PaddingRight = UDim.new(0, inset.right)
		padding.PaddingTop = UDim.new(0, inset.top)
		padding.PaddingBottom = UDim.new(0, inset.bottom)
		padding.Parent = button
	end

	Widgets.corner(button, options.radius)
	-- Grain, then gloss: a flat fill at this size reads as vinyl without both.
	if options.pattern ~= false then
		Widgets.surface(button, {
			image = Theme.texture.buttonPattern,
			radius = options.radius or Theme.radius.button,
			inset = inset,
			tile = Theme.texture.buttonTile,
			transparency = 1 - Theme.texture.buttonOpacity,
		})
	end
	if options.gradient ~= false then
		Widgets.gradient(button)
	end

	--[[
		The resting colour, remembered from the start.

		Read by the hover, the press and `setEnabled` alike, so none of them can
		capture a colour one of the others was in the middle of applying — which is
		how a button ends up permanently stuck in its hover tint.
	]]
	button:SetAttribute("RestingColor", button.BackgroundColor3)

	local rim = Widgets.stroke(button, options.edge or Theme.color.panelEdge, Theme.stroke.button)
	local edge = rim.Color
	button:SetAttribute("RestingEdge", edge)
	local hovered, pressed = false, false

	local function paint()
		if button:GetAttribute("Disabled") == true then
			return
		end

		local resting = button:GetAttribute("RestingColor") :: Color3
		local target = resting
		if pressed then
			target = resting:Lerp(Color3.new(0, 0, 0), PRESS_DROP)
		elseif hovered then
			target = lift(resting, HOVER_LIFT)
		end

		TweenService:Create(button, HOVER_TWEEN, { BackgroundColor3 = target }):Play()
		TweenService:Create(rim, HOVER_TWEEN, {
			Color = if hovered then lift(edge, 0.55) else edge,
		}):Play()
	end

	--[[
		A dead button must not answer: lighting under the pointer is a promise that
		pressing will do something.

		Descendants are not lit — only the button itself. A caption or a price that
		belongs to a button should still BE a child of it, so it moves and hides with
		it; set `Active = false` on such a child so it does not swallow the click.
	]]
	button.MouseEnter:Connect(function()
		hovered = true
		paint()
	end)
	button.MouseLeave:Connect(function()
		hovered, pressed = false, false
		paint()
	end)
	button.MouseButton1Down:Connect(function()
		pressed = true
		paint()
	end)
	button.MouseButton1Up:Connect(function()
		pressed = false
		paint()
	end)

	if options.onClick then
		button.Activated:Connect(function()
			if button:GetAttribute("Disabled") == true then
				return
			end
			options.onClick()
		end)
	end

	return button
end

--[[
	Turns a button off, and back on.

	OFF MEANS OFF, everywhere at once: it stops answering the pointer, stops
	darkening under a press, stops firing, and goes grey. Half of that — a grey
	button that still grows and still clicks — is worse than no state at all,
	because the player learns to distrust the colour.

	The resting colour is remembered on the button itself, so a caller never has to
	hand it back to re-enable one.
]]
function Widgets.setEnabled(button: TextButton, enabled: boolean)
	local resting = button:GetAttribute("RestingColor")
	if typeof(resting) ~= "Color3" then
		resting = button.BackgroundColor3
		button:SetAttribute("RestingColor", resting)
	end

	button:SetAttribute("Disabled", not enabled)
	button.Active = enabled
	button.Selectable = enabled
	button.BackgroundColor3 = if enabled then resting else Theme.color.locked
	button.TextTransparency = if enabled then 0 else 0.25

	-- A button switched off while the pointer is on it would otherwise keep the
	-- bright rim the hover gave it, and go on advertising itself.
	local rim = button:FindFirstChildOfClass("UIStroke")
	local edge = button:GetAttribute("RestingEdge")
	if rim and typeof(edge) == "Color3" then
		rim.Color = edge
	end
end

--[[
	A progress bar.

	THE FILL IS ALWAYS THE FULL SHAPE; A TRANSPARENCY MASK DECIDES WHERE IT STOPS.

	Two obvious approaches both fail, and it is worth writing down why.

	Sizing the fill to the ratio and rounding it does not work: a UICorner radius is
	capped by the SMALLER side of what it rounds, so a narrow fill gets a tiny radius
	and sits inside the track's much rounder cap, leaving a dark crescent to its
	left. Holding it to a minimum width hides that crescent and costs more than it
	buys — the bar then shows the same pip at 0.5% and at 3%, so the first percents
	move nothing, exactly when a player is watching for movement.

	Squaring the fill and asking the track to clip it does not work either:
	ClipsDescendants clips to the RECTANGLE, not to the rounded corners, so the
	square left edge simply hangs out past the cap.

	So the fill never changes size. It fills the track, carries the same rounded
	shape, and a horizontal UIGradient turns it transparent past the ratio. The cap
	is therefore always exactly right, the edge is a straight vertical cut, and the
	visible width is strictly proportional down to the first pixel.

	The cost is that a NumberSequence cannot be tweened, so the bar animates itself
	on Heartbeat while it is moving and disconnects the moment it settles.
]]
--[[
	The colour ramp along a bar: a resting gradient, plus a highlight centred on
	`phase`.

	It has to be ONE ColorSequence on ONE UIGradient, because that gradient is
	already the transparency mask that gives the fill its cut edge — a second
	gradient cannot be added to the same frame, and a child carrying it would not be
	masked and would spill past the cut. Colour and mask therefore share an object,
	which works because they are separate properties of it.

	`phase` runs from below zero to above one so the highlight enters and leaves
	rather than appearing in place. Keypoints must be strictly increasing and must
	start at 0 and end at 1, so they are pushed through a filter rather than
	assumed.
]]
local function sheenRamp(base: Color3, phase: number): ColorSequence
	local resting = lift(base, SHEEN_LIFT)

	local function at(position: number): Color3
		local ground = resting:Lerp(base, position)
		local distance = math.abs(position - phase) / SHEEN_WIDTH
		if distance >= 1 then
			return ground
		end
		-- Squared, so the band has no edge to catch the eye on.
		return ground:Lerp(lift(base, SHEEN_GLOW), (1 - distance) ^ 2)
	end

	local points = {}
	local function push(position: number)
		local clamped = math.clamp(position, 0, 1)
		local previous = points[#points]
		if previous and clamped <= previous.Time + 0.01 then
			return
		end
		table.insert(points, ColorSequenceKeypoint.new(clamped, at(clamped)))
	end

	push(0)
	for _, offset in { -1, -0.5, 0, 0.5, 1 } do
		push(phase + offset * SHEEN_WIDTH)
	end

	local last = points[#points]
	if last.Time < 1 then
		if last.Time > 0.99 then
			points[#points] = ColorSequenceKeypoint.new(1, last.Color)
		else
			table.insert(points, ColorSequenceKeypoint.new(1, at(1)))
		end
	end

	return ColorSequence.new(points)
end

function Widgets.bar(parent: Instance, options)
	local track = Instance.new("Frame")
	track.Name = options.name or "Bar"
	track.Size = options.size or UDim2.new(1, 0, 0, 20)
	track.Position = options.position or UDim2.fromScale(0, 0)
	track.AnchorPoint = options.anchorPoint or Vector2.zero
	track.BackgroundColor3 = options.trackColor or Theme.color.background
	track.BorderSizePixel = 0
	track.Parent = parent
	Widgets.corner(track, Theme.radius.chip)
	-- A gauge small enough to sit inside a chip is mostly outline if it keeps one.
	if options.outline ~= false then
		Widgets.stroke(track, Theme.color.panelEdge, Theme.stroke.button)
	end

	-- Inset so the track keeps a visible rim, and so the two rounded edges never
	-- fight each other over the same pixel.
	local rim = options.rim or 3
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, -rim * 2, 1, -rim * 2)
	fill.Position = UDim2.fromScale(0.5, 0.5)
	fill.AnchorPoint = Vector2.new(0.5, 0.5)
	fill.BackgroundColor3 = options.color or Theme.color.positive
	fill.BorderSizePixel = 0
	fill.Parent = track
	Widgets.corner(fill, Theme.radius.chip)

	local mask = Instance.new("UIGradient")
	mask.Parent = fill

	local shown, target = 0, 0
	local stepper: RBXScriptConnection? = nil
	local sheen: RBXScriptConnection? = nil

	local function paint(ratio: number)
		if ratio <= 0 then
			fill.Visible = false
			return
		end

		fill.Visible = true
		if ratio >= 1 then
			mask.Transparency = NumberSequence.new(0)
			return
		end

		-- A jump needs two keypoints: one last opaque, one first clear. EDGE is how
		-- wide that jump is, and it is what keeps the cut looking like an edge.
		local cut = math.min(ratio, 1 - BAR_EDGE * 2)
		mask.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(cut, 0),
			NumberSequenceKeypoint.new(cut + BAR_EDGE, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
	end

	local function step(deltaTime: number)
		local remaining = target - shown
		if math.abs(remaining) < 0.0015 then
			shown = target
			paint(shown)
			if stepper then
				stepper:Disconnect()
				stepper = nil
			end
			return
		end

		shown += remaining * math.min(deltaTime * BAR_SPEED, 1)
		paint(shown)
	end

	paint(0)

	--[[
		The sheen, opt-in. It is worth its frames on the one bar a player watches
		fill; on a dash cooldown the size of a thumbnail it would be a twitch.
	]]
	if options.sheen == true then
		local fillColor = fill.BackgroundColor3
		local resting = ColorSequence.new(lift(fillColor, SHEEN_LIFT), fillColor)
		local sweeping = false

		mask.Color = resting
		sheen = RunService.Heartbeat:Connect(function()
			local cycle = os.clock() % SHEEN_PERIOD
			if cycle < SHEEN_SWEEP then
				-- Entering from off one end and leaving past the other.
				local travel = cycle / SHEEN_SWEEP
				mask.Color = sheenRamp(fillColor, -SHEEN_WIDTH + travel * (1 + SHEEN_WIDTH * 2))
				sweeping = true
			elseif sweeping then
				-- Written once, then nothing until the next sweep.
				mask.Color = resting
				sweeping = false
			end
		end)
	end

	return {
		instance = track,
		destroy = function()
			if sheen then
				sheen:Disconnect()
				sheen = nil
			end
			if stepper then
				stepper:Disconnect()
				stepper = nil
			end
			track:Destroy()
		end,
		set = function(ratio: number)
			target = math.clamp(ratio, 0, 1)
			if not stepper and shown ~= target then
				stepper = RunService.Heartbeat:Connect(step)
			end
		end,
	}
end

function Widgets.icon(parent: Instance, options): GuiObject
	if options.image then
		local image = Instance.new("ImageLabel")
		image.Name = options.name or "Icon"
		image.Size = options.size or UDim2.fromOffset(32, 32)
		image.Position = options.position or UDim2.fromScale(0, 0)
		image.AnchorPoint = options.anchorPoint or Vector2.zero
		image.BackgroundTransparency = 1
		image.Image = options.image
		image.ScaleType = Enum.ScaleType.Fit
		image.ImageColor3 = options.color or Color3.new(1, 1, 1)
		image.LayoutOrder = options.layoutOrder or 0
		image.Visible = if options.visible == nil then true else options.visible
		image.Parent = parent
		return image
	end

	local fallback = Widgets.label(parent, {
		name = options.name or "Icon",
		size = options.size or UDim2.fromOffset(32, 32),
		position = options.position,
		anchorPoint = options.anchorPoint,
		align = Enum.TextXAlignment.Center,
		text = options.fallback or "",
		layoutOrder = options.layoutOrder,
		outline = options.outline,
	})
	fallback.Visible = if options.visible == nil then true else options.visible
	return fallback
end

--[[ An icon followed by a value: the shape every stat takes. ]]
function Widgets.statRow(parent: Instance, options)
	local row = Instance.new("Frame")
	row.Name = options.name or "Stat"
	row.Size = options.size or UDim2.new(1, 0, 0, 36)
	row.Position = options.position or UDim2.fromScale(0, 0)
	row.AnchorPoint = options.anchorPoint or Vector2.zero
	row.BackgroundTransparency = 1
	row.LayoutOrder = options.layoutOrder or 0
	row.Parent = parent

	local iconSize = options.iconSize or 34
	Widgets.icon(row, {
		image = options.image,
		fallback = options.fallback,
		size = UDim2.fromOffset(iconSize, iconSize),
		position = UDim2.fromScale(0, 0.5),
		anchorPoint = Vector2.new(0, 0.5),
	})

	local gap = iconSize + 10
	local value = Widgets.label(row, {
		name = "Value",
		size = UDim2.new(1, -gap, 1, 0),
		position = UDim2.fromOffset(gap, 0),
		font = options.font or Theme.font.number,
		color = options.color or Theme.color.textOnColor,
		textSize = options.textSize,
		outline = if options.outline == nil then Theme.stroke.textHeavy else options.outline,
		text = options.text or "",
	})

	return { frame = row, value = value }
end

function Widgets.list(parent: Instance, options)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = options.direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, options.padding or 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = options.horizontalAlignment or Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = options.verticalAlignment or Enum.VerticalAlignment.Top
	layout.Parent = parent
	return layout
end

--[[
	A scrolling list.

	`inset` is not decoration. A ScrollingFrame clips its descendants, and an outline
	is drawn OUTSIDE the frame it belongs to: a row flush against the edge loses the
	outline the eye needs to separate it from the next one. The inset gives the
	outline somewhere to be drawn, and keeps the rows clear of the scrollbar.
]]
function Widgets.scroll(parent: Instance, options): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = options.name or "List"
	scroll.Size = options.size or UDim2.fromScale(1, 1)
	scroll.Position = options.position or UDim2.fromScale(0, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Theme.color.panelEdge
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.Parent = parent

	if options.inset ~= false then
		Widgets.padding(scroll, options.inset or 8)
	end

	return scroll
end

return Widgets
