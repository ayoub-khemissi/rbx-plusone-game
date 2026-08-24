--!strict
--[[ Palette — small part factories, so SkyBuilder stays readable. ]]

local Palette = {}

export type PartOptions = {
	name: string,
	size: Vector3,
	cframe: CFrame?,
	position: Vector3?,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?,
	canTouch: boolean?,
	shape: Enum.PartType?,
	parent: Instance?,
}

function Palette.color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

--[[ Lightens or darkens a colour (terrain variation, decor). ]]
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
	part.Color = options.color
	part.Material = options.material or Enum.Material.SmoothPlastic
	part.Transparency = options.transparency or 0
	part.CanCollide = if options.canCollide == nil then true else options.canCollide
	part.CanTouch = if options.canTouch == nil then true else options.canTouch
	part.CanQuery = false
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	if options.shape then
		part.Shape = options.shape
	end
	if options.cframe then
		part.CFrame = options.cframe
	elseif options.position then
		part.Position = options.position
	end

	part.Parent = options.parent
	return part
end

--[[
	A ring, built from segments arranged in a circle.

	Roblox has no torus primitive, and a mesh would mean shipping an asset. A dozen
	blocks read perfectly well at flight speed and keep the project asset-free.
]]
function Palette.ring(options: {
	name: string,
	center: Vector3,
	radius: number,
	thickness: number,
	color: Color3,
	segments: number?,
	parent: Instance?,
}): Model
	local model = Instance.new("Model")
	model.Name = options.name

	local segments = options.segments or 12
	local segmentLength = (2 * math.pi * options.radius) / segments * 1.15

	for index = 1, segments do
		local angle = (index / segments) * math.pi * 2
		local offset = Vector3.new(0, math.cos(angle), math.sin(angle)) * options.radius

		Palette.block({
			name = "Segment",
			size = Vector3.new(options.thickness, options.thickness, segmentLength),
			cframe = CFrame.new(options.center + offset) * CFrame.Angles(angle, 0, 0),
			color = options.color,
			material = Enum.Material.Neon,
			canCollide = false,
			canTouch = false,
			parent = model,
		})
	end

	model.Parent = options.parent
	return model
end

--[[ Invisible sensor filling a ring: this is what the dragon actually touches. ]]
function Palette.sensor(options: {
	name: string,
	center: Vector3,
	radius: number,
	parent: Instance?,
}): Part
	return Palette.block({
		name = options.name,
		size = Vector3.new(3, options.radius * 2, options.radius * 2),
		position = options.center,
		color = Color3.new(1, 1, 1),
		transparency = 1,
		canCollide = false,
		canTouch = true,
		parent = options.parent,
	})
end

function Palette.label(parent: BasePart, text: string, color: Color3, face: Enum.NormalId?): SurfaceGui
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Sign"
	surface.Face = face or Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 24
	surface.LightInfluence = 0

	local label = Instance.new("TextLabel")
	label.Name = "Text"
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
