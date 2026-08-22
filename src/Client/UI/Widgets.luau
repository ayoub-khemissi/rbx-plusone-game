--!strict
--[[
	Widgets — briques d'interface reutilisables.

	Toutes les vues passent par ici : une seule definition du bouton, de la carte et
	de la barre de progression, donc une interface homogene et peu de code.
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

function Widgets.stroke(parent: Instance, color: Color3?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.color.panelLight
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
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

function Widgets.card(parent: Instance, options): Frame
	local card = Instance.new("Frame")
	card.Name = options.name or "Carte"
	card.Size = options.size
	card.Position = options.position or UDim2.fromScale(0, 0)
	card.AnchorPoint = options.anchorPoint or Vector2.zero
	card.BackgroundColor3 = options.color or Theme.color.panel
	card.BackgroundTransparency = options.transparency or 0.08
	card.BorderSizePixel = 0
	card.Visible = if options.visible == nil then true else options.visible
	card.Parent = parent

	Widgets.corner(card, Theme.radius.panel)
	Widgets.stroke(card)
	return card
end

function Widgets.label(parent: Instance, options): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = options.name or "Texte"
	label.Size = options.size or UDim2.fromScale(1, 1)
	label.Position = options.position or UDim2.fromScale(0, 0)
	label.AnchorPoint = options.anchorPoint or Vector2.zero
	label.BackgroundTransparency = 1
	label.Font = options.font or Theme.font.body
	label.Text = options.text or ""
	label.TextColor3 = options.color or Theme.color.text
	label.TextScaled = if options.textScaled == nil then true else options.textScaled
	label.TextXAlignment = options.align or Enum.TextXAlignment.Left
	label.TextWrapped = options.wrapped or false
	label.LayoutOrder = options.layoutOrder or 0
	label.Parent = parent
	return label
end

function Widgets.button(parent: Instance, options): TextButton
	local button = Instance.new("TextButton")
	button.Name = options.name or "Bouton"
	button.Size = options.size or UDim2.fromOffset(150, 46)
	button.Position = options.position or UDim2.fromScale(0, 0)
	button.AnchorPoint = options.anchorPoint or Vector2.zero
	button.BackgroundColor3 = options.color or Theme.color.accent
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	button.Font = options.font or Theme.font.title
	button.Text = options.text or ""
	button.TextColor3 = options.textColor or Theme.color.background
	button.TextScaled = true
	button.LayoutOrder = options.layoutOrder or 0
	button.Parent = parent

	Widgets.corner(button)
	if options.padding then
		Widgets.padding(button, options.padding)
	end

	if options.onClick then
		button.Activated:Connect(options.onClick)
	end

	return button
end

--[[ Barre de progression : fond + remplissage anime. ]]
function Widgets.bar(parent: Instance, options)
	local track = Instance.new("Frame")
	track.Name = options.name or "Barre"
	track.Size = options.size or UDim2.new(1, 0, 0, 14)
	track.Position = options.position or UDim2.fromScale(0, 0)
	track.BackgroundColor3 = Theme.color.background
	track.BorderSizePixel = 0
	track.Parent = parent
	Widgets.corner(track, Theme.radius.chip)

	local fill = Instance.new("Frame")
	fill.Name = "Remplissage"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = options.color or Theme.color.accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	Widgets.corner(fill, Theme.radius.chip)

	return {
		instance = track,
		set = function(ratio: number)
			local clamped = math.clamp(ratio, 0, 1)
			TweenService:Create(fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(clamped, 1) }):Play()
		end,
	}
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
	scroll.Name = options.name or "Liste"
	scroll.Size = options.size or UDim2.fromScale(1, 1)
	scroll.Position = options.position or UDim2.fromScale(0, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = Theme.color.accent
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.Parent = parent
	return scroll
end

return Widgets
