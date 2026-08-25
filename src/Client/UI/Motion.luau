--!strict
--[[
	Motion — the four things the interface is allowed to do when a number changes.

	A counter that snaps from 1 200 to 1 340 tells the player the same thing as one
	that rolls, and neither is hard to read. The difference is that the second one is
	SEEN: movement is what the eye is built to catch, and a value that never moves
	stops being looked at. Everything here exists to make a change noticed without
	asking the player to read anything.

	FOUR VERBS, DELIBERATELY. `pop` says something grew, `roll` says by how much,
	`shine` says something rare happened, `appear` says a thing arrived. Anything the
	interface wants to say falls into one of those, and a fifth would only be a
	slower way of saying one of the four. Keeping the vocabulary small is also what
	keeps the screen from becoming a fairground: when every element has its own
	flourish, none of them signals anything.

	TWEENS, NOT LOOPS. TweenService runs on the engine side and needs no per-frame
	Lua; the one exception is `roll`, which has a number to recompute every frame,
	and it disconnects the moment it arrives.

	Nothing here reads state or knows what a Coin is. It takes an instance and a
	number, which is what lets the HUD, the shop and a panel share one vocabulary.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Format = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Domain.Support.Format)

local Motion = {}

-- A punch: out past the target, then back. The overshoot is what reads as alive;
-- without it the same duration reads as a slow zoom.
local POP_OUT = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_BACK = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_IN = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_OUT = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SHINE_TIME = 0.55
local APPEAR_TIME = 0.22

-- How fast a rolling number closes the gap, as a share of what is left per second.
-- Fast enough that the value is never stale, slow enough that the movement reads.
local ROLL_SPEED = 9
-- Below this the roll is a stutter rather than a movement: snap instead.
local ROLL_EPSILON = 0.5

local function scaleOf(instance: GuiObject): UIScale
	local existing = instance:FindFirstChildOfClass("UIScale")
	if existing then
		return existing
	end

	local scale = Instance.new("UIScale")
	scale.Parent = instance
	return scale
end

--[[
	Something grew: a quick punch of scale.

	Used on the value that changed and nothing else. Popping a whole row because one
	number in it moved makes the player look at the row and hunt for what happened.
]]
function Motion.pop(instance: GuiObject, strength: number?)
	local scale = scaleOf(instance)
	scale.Scale = 1

	local out = TweenService:Create(scale, POP_OUT, { Scale = 1 + (strength or 0.18) })
	out.Completed:Connect(function()
		TweenService:Create(scale, POP_BACK, { Scale = 1 }):Play()
	end)
	out:Play()
end

--[[
	A wash of colour over a frame, fading out.

	For a state that BECAME true — a cooldown that finished, a purchase that went
	through. It is deliberately short on the way in and slow on the way out: the
	arrival is the event, the fade is just the eye letting go.
]]
function Motion.flash(frame: GuiObject, color: Color3)
	local wash = frame:FindFirstChild("MotionFlash") :: Frame?
	if not wash then
		wash = Instance.new("Frame")
		wash.Name = "MotionFlash"
		wash.Size = UDim2.fromScale(1, 1)
		wash.BackgroundColor3 = color
		wash.BorderSizePixel = 0
		wash.ZIndex = (frame.ZIndex or 1) + 1
		wash.Parent = frame

		local corner = frame:FindFirstChildOfClass("UICorner")
		if corner then
			local copy = corner:Clone()
			copy.Parent = wash
		end
	end

	local target = wash :: Frame
	target.BackgroundColor3 = color
	target.BackgroundTransparency = 1
	target.Visible = true

	local up = TweenService:Create(target, FLASH_IN, { BackgroundTransparency = 0.45 })
	up.Completed:Connect(function()
		TweenService:Create(target, FLASH_OUT, { BackgroundTransparency = 1 }):Play()
	end)
	up:Play()
end

--[[
	A highlight sweeping across, once.

	Reserved for the rare and the earned — a level gained, a rebirth taken. It is the
	strongest thing in this file, which is exactly why almost nothing may use it: a
	sweep that happens every few seconds is wallpaper, and then nothing is left to
	say that something mattered.
]]
function Motion.shine(frame: GuiObject)
	local existing = frame:FindFirstChild("MotionShine")
	if existing then
		existing:Destroy()
	end

	local band = Instance.new("Frame")
	band.Name = "MotionShine"
	band.Size = UDim2.fromScale(1, 1)
	band.BackgroundColor3 = Color3.new(1, 1, 1)
	band.BackgroundTransparency = 0.55
	band.BorderSizePixel = 0
	band.ZIndex = (frame.ZIndex or 1) + 2
	band.Parent = frame

	local corner = frame:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = band
	end

	-- The band IS a gradient: a narrow opaque window travelling over a transparent
	-- field, which costs one instance and clips itself to the frame's own shape.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 18
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Offset = Vector2.new(-1, 0)
	gradient.Parent = band

	local sweep = TweenService:Create(
		gradient,
		TweenInfo.new(SHINE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Offset = Vector2.new(1, 0) }
	)
	sweep.Completed:Connect(function()
		band:Destroy()
	end)
	sweep:Play()
end

--[[
	A thing arrived: up from slightly small and transparent, with a little overshoot.

	Panels open this way rather than blinking into existence, which is what tells the
	player the window came from the button they pressed instead of replacing the
	screen they were looking at.
]]
function Motion.appear(frame: GuiObject)
	local scale = scaleOf(frame)
	scale.Scale = 0.9

	TweenService
		:Create(
			scale,
			TweenInfo.new(APPEAR_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		:Play()
end

--[[
	A number that travels to its new value instead of jumping to it.

	Returns a `set`. The label is written every frame while it is moving, so the
	player sees the SIZE of the gain — a hundred and a hundred thousand look
	different on the way — and reads the exact figure the moment it settles.

	A drop is not rolled. Progress falls on a rebirth, and watching a counter tick
	down through everything it took to earn is not a moment anybody wants stretched.
]]
function Motion.roll(label: TextLabel, options)
	options = options or {}
	local format = options.format or Format.abbreviate
	local onGrow = options.onGrow

	local shown, target = nil :: number?, 0
	local stepper: RBXScriptConnection? = nil

	local function paint()
		label.Text = format(shown or 0)
	end

	local function stop()
		if stepper then
			stepper:Disconnect()
			stepper = nil
		end
	end

	local function step(deltaTime: number)
		local current = shown or target
		local remaining = target - current
		if math.abs(remaining) < ROLL_EPSILON then
			shown = target
			paint()
			stop()
			return
		end

		shown = current + remaining * math.min(deltaTime * ROLL_SPEED, 1)
		paint()
	end

	return function(value: number)
		if typeof(value) ~= "number" then
			return
		end

		-- The first value is where the player already is, not something they just
		-- earned: rolling it up from zero on every join would be a lie.
		if shown == nil then
			shown, target = value, value
			paint()
			return
		end

		if value <= target then
			stop()
			shown, target = value, value
			paint()
			return
		end

		target = value
		if onGrow then
			onGrow()
		end
		if not stepper then
			stepper = RunService.Heartbeat:Connect(step)
		end
	end
end

return Motion
