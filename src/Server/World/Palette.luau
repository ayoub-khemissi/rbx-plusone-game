--!strict
--[[ Palette — petites fabriques de parties, pour que WorldBuilder reste lisible. ]]

local Palette = {}

export type PartOptions = {
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?,
	shape: Enum.PartType?,
	parent: Instance?,
	orientation: Vector3?,
}

function Palette.color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

--[[ Eclaircit ou assombrit une couleur (variations de terrain, murs, decor). ]]
function Palette.shade(color: Color3, amount: number): Color3
	local function mix(channel: number): number
		return math.clamp(channel + amount, 0, 1)
	end
	return Color3.new(mix(color.R), mix(color.G), mix(color.B))
end

function Palette.block(options: PartOptions): Part
	local part = Instance.new("Part")
	part.Name = options.name
	part.Size = options.size
	part.Position = options.position
	part.Color = options.color
	part.Material = options.material or Enum.Material.SmoothPlastic
	part.Transparency = options.transparency or 0
	part.CanCollide = if options.canCollide == nil then true else options.canCollide
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	if options.shape then
		part.Shape = options.shape
	end
	if options.orientation then
		part.Orientation = options.orientation
	end

	part.Parent = options.parent
	return part
end

--[[ Panneau de texte affiche sur une face verticale (barrieres, pads). ]]
function Palette.label(parent: BasePart, text: string, color: Color3, face: Enum.NormalId?): SurfaceGui
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Panneau"
	surface.Face = face or Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 24
	surface.LightInfluence = 0
	surface.AlwaysOnTop = false

	local label = Instance.new("TextLabel")
	label.Name = "Texte"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = surface

	surface.Parent = parent
	return surface
end

return Palette
