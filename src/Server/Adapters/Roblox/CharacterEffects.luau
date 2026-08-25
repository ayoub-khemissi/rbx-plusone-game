--!strict
--[[
	CharacterEffects — the Effects port: things that happen ON a character, in front
	of everyone.

	THIS ONE IS THE SERVER'S, and that is the opposite of the rule Coins follow. A
	Coin is drawn on the machine of the player taking it, because it is THEIR pickup
	and nobody else has a stake in it. A rebirth is the other kind of moment: the
	whole point is that the room sees it. So the emitter is built on the server and
	replicates, once, to everyone who can see the character.

	Emitted rather than left running. A burst is `Rate = 0` plus one `Emit`, so the
	attachment carries nothing after its particles have fallen — and Debris takes the
	attachment away rather than a task nobody is watching.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local CharacterEffects = {}
CharacterEffects.__index = CharacterEffects

-- Present in every Roblox install, so the celebration never depends on an upload.
-- A theme may name something better; see Config.Theme.textures.confetti.
local FALLBACK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local COUNT = 150
local LIFETIME = 4

--[[ The palette, as something particles can be tinted along. ]]
local function festiveColors(): ColorSequence
	local palette = Config.Theme.palette
	local names = { "accent", "info", "positive", "negative", "special" }

	local points = {}
	for index, name in names do
		local entry = palette[name]
		local color = if typeof(entry) == "table" and #entry >= 3
			then Color3.fromRGB(entry[1], entry[2], entry[3])
			else Color3.new(1, 1, 1)
		table.insert(points, ColorSequenceKeypoint.new((index - 1) / (#names - 1), color))
	end

	return ColorSequence.new(points)
end

local function confetti(): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Confetti"
	emitter.Texture = (Config.Theme.textures and Config.Theme.textures.confetti) or FALLBACK_TEXTURE
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(1.4, 2.6)
	emitter.Speed = NumberRange.new(26, 48)
	-- Thrown up and out in every direction, then pulled down: the shape of a party
	-- popper rather than a fountain.
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -68, 0)
	-- Air. Without it the pieces fall as fast as they rose, which reads as debris.
	emitter.Drag = 3.2
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-340, 340)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.75, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = festiveColors()
	emitter.LightEmission = 0.35
	emitter.LockedToPart = false

	return emitter
end

function CharacterEffects.new()
	return setmetatable({}, CharacterEffects)
end

--[[
	Plays a celebration on a player's character. An unknown kind does nothing: a
	missing effect must never be the reason a rebirth fails.
]]
function CharacterEffects.celebrate(_self, player: Player, kind: string)
	if kind ~= "rebirth" then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "CelebrationAttachment"
	-- Chest height: confetti that starts at the feet is walked out of.
	attachment.Position = Vector3.new(0, 1, 0)
	attachment.Parent = root

	local emitter = confetti()
	emitter.Parent = attachment
	emitter:Emit(COUNT)

	Debris:AddItem(attachment, LIFETIME)
end

return CharacterEffects
