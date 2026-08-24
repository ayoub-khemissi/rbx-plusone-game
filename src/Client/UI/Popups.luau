--!strict
--[[
	Popups — the numbers that fly off the player.

	A gain the player only reads on a counter is a gain they have to go looking for.
	Thrown off the character, it is the same information delivered where they are
	already looking, and it makes the moment of earning visible.

	THE MOTION IS A THROW. Out along a random direction, up over an arc, and back
	towards where it came from — the shape of something tossed and caught. A single
	`sin(pi * progress)` drives the whole thing: zero at both ends, one at the peak,
	and slow around the top, which is exactly how a thrown object hangs.

	Small, then large at the peak, then small again. The growth is what makes it
	read as coming towards the camera rather than sliding across it.

	It draws in SCREEN space, not on a BillboardGui in the world. These fire several
	times a second at the centre of the screen where the character already is, and a
	world-anchored label would fight the camera, clip through geometry and cost a
	part each.
]]

local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Popups = {}
Popups.__index = Popups

local LIFETIME = 1.15
local SPREAD = 130 -- how far out it travels, in design pixels
local LIFT = 90 -- how much of that is upwards, whatever direction it took
local MIN_SCALE = 0.55
local PEAK_SCALE = 1.25
local MAX_TILT = 18 -- degrees at full horizontal reach
local FADE_FROM = 0.6 -- share of the life spent fully opaque

function Popups.new(parent: Instance)
	local layer = Instance.new("Frame")
	layer.Name = "Popups"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	-- The numbers pass over the world and under every window.
	layer.ZIndex = 2
	layer.Parent = parent

	return setmetatable({ layer = layer, live = {}, stepper = nil }, Popups)
end

--[[
	Throws one number, from the middle of the screen — which is where the character
	is, and where the eye already is.
]]
function Popups.spawn(self, text: string, image: string?)
	local frame = Instance.new("Frame")
	frame.Name = "Popup"
	frame.Size = UDim2.fromOffset(0, 40)
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.Parent = self.layer

	Widgets.list(frame, {
		direction = Enum.FillDirection.Horizontal,
		padding = 6,
		verticalAlignment = Enum.VerticalAlignment.Center,
	})

	local label = Widgets.label(frame, {
		name = "Amount",
		size = UDim2.fromOffset(0, 40),
		font = Theme.font.title,
		textSize = Theme.text.title,
		color = Theme.color.accent,
		outline = Theme.stroke.textHeavy,
		text = text,
		layoutOrder = 1,
	})
	label.AutomaticSize = Enum.AutomaticSize.X

	local icon = if image
		then Widgets.icon(frame, {
			image = image,
			size = UDim2.fromOffset(30, 30),
			layoutOrder = 2,
		})
		else nil

	local scale = Instance.new("UIScale")
	scale.Parent = frame

	-- A direction anywhere around the character, then pulled upwards so it always
	-- reads as thrown rather than dropped.
	local angle = math.random() * math.pi * 2

	table.insert(self.live, {
		frame = frame,
		label = label,
		icon = icon,
		scale = scale,
		stroke = label:FindFirstChildOfClass("UIStroke"),
		direction = Vector2.new(math.cos(angle), math.sin(angle)),
		elapsed = 0,
	})

	self:_ensureStepper()
end

function Popups._ensureStepper(self)
	if self.stepper then
		return
	end

	self.stepper = RunService.RenderStepped:Connect(function(deltaTime)
		self:_step(deltaTime)
	end)
end

function Popups._step(self, deltaTime: number)
	for index = #self.live, 1, -1 do
		local popup = self.live[index]
		popup.elapsed += deltaTime

		if popup.elapsed >= LIFETIME or not popup.frame.Parent then
			popup.frame:Destroy()
			table.remove(self.live, index)
			continue
		end

		local progress = popup.elapsed / LIFETIME
		-- Zero at both ends, one at the peak, and slow around the top: out, up and
		-- back, from a single curve.
		local arc = math.sin(progress * math.pi)

		local offsetX = popup.direction.X * SPREAD * arc
		local offsetY = popup.direction.Y * SPREAD * arc - LIFT * arc

		popup.frame.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
		popup.scale.Scale = MIN_SCALE + (PEAK_SCALE - MIN_SCALE) * arc

		-- Tilted by how far out to the side it has travelled, so the pair leaning
		-- away from each other reads as two objects rather than one repeated.
		popup.frame.Rotation = -MAX_TILT * (offsetX / SPREAD)

		local faded = math.clamp((progress - FADE_FROM) / (1 - FADE_FROM), 0, 1)
		popup.label.TextTransparency = faded
		if popup.stroke then
			popup.stroke.Transparency = faded
		end
		-- The icon falls back to a text label when a theme has no image for it, so
		-- the right property depends on what came back.
		if popup.icon then
			if popup.icon:IsA("ImageLabel") then
				popup.icon.ImageTransparency = faded
			elseif popup.icon:IsA("TextLabel") then
				popup.icon.TextTransparency = faded
			end
		end
	end

	if #self.live == 0 and self.stepper then
		self.stepper:Disconnect()
		self.stepper = nil
	end
end

return Popups
