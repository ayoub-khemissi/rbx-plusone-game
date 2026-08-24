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

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Widgets = {}

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

	-- A theme may lay a faint tile over its panels. No texture, flat panel, no fuss.
	if Theme.texture.panelPattern and options.pattern ~= false then
		local pattern = Instance.new("ImageLabel")
		pattern.Name = "Pattern"
		pattern.Size = UDim2.fromScale(1, 1)
		pattern.BackgroundTransparency = 1
		pattern.Image = Theme.texture.panelPattern
		pattern.ScaleType = Enum.ScaleType.Tile
		pattern.TileSize = UDim2.fromOffset(64, 64)
		pattern.ImageTransparency = 0.92
		pattern.ZIndex = 0
		pattern.Parent = card
		Widgets.corner(pattern, radius)
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
	button.BackgroundColor3 = options.color or Theme.color.accent
	button.AutoButtonColor = true
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

	Widgets.corner(button, options.radius)
	Widgets.stroke(button, options.edge or Theme.color.panelEdge, Theme.stroke.button)
	if options.gradient ~= false then
		Widgets.gradient(button)
	end

	if options.onClick then
		button.Activated:Connect(options.onClick)
	end

	return button
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
	Widgets.stroke(track, Theme.color.panelEdge, Theme.stroke.button)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = options.color or Theme.color.positive
	fill.BorderSizePixel = 0
	fill.Parent = track
	Widgets.corner(fill, Theme.radius.chip)
	Widgets.gradient(fill)

	return {
		instance = track,
		set = function(ratio: number)
			local clamped = math.clamp(ratio, 0, 1)
			TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(clamped, 1) }):Play()
		end,
	}
end

--[[
	An icon: an image when the theme provides one, the emoji otherwise.

	Keeping the fallback matters — an asset that is missing, still moderated or not
	yet approved would otherwise leave an empty square where a symbol should be.
]]
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
		image.Parent = parent
		return image
	end

	return Widgets.label(parent, {
		name = options.name or "Icon",
		size = options.size or UDim2.fromOffset(32, 32),
		position = options.position,
		anchorPoint = options.anchorPoint,
		align = Enum.TextXAlignment.Center,
		text = options.fallback or "",
		layoutOrder = options.layoutOrder,
		outline = options.outline,
	})
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
	return scroll
end

return Widgets
