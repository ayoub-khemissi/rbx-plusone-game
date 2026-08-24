--!strict
--[[
	Sound — plays a MOMENT, by name.

	Callers say `Sound.play("coin")`, never an asset id. The moment is the stable
	thing; the clip behind it is a configuration detail that changes with a theme,
	a retune or somebody's ear.

	Two decisions worth keeping:

	Sounds are POOLED and reparented, never created per event. A collectible fires
	this dozens of times a minute, and building an Instance each time hands the
	garbage collector a job it does not need during a run.

	A moment with no clip configured is SILENT, not an error. Half a set filled in
	has to leave the game playable, and a missing sound is the one failure the
	player forgives.
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Sound = {}

local CUES = Config.Sounds

local container = Instance.new("Folder")
container.Name = "GameSounds"
container.Parent = SoundService

local pool: { [string]: Sound } = {}

local function instanceFor(id: string): Sound
	local existing = pool[id]
	if existing then
		return existing
	end

	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Parent = container
	pool[id] = sound
	return sound
end

--[[ Which clip a moment uses right now: one of its variants, or its single id. ]]
local function clipFor(cue): string?
	if cue.variants and #cue.variants > 0 then
		return cue.variants[math.random(#cue.variants)]
	end
	return cue.id
end

function Sound.play(name: string, options: { volume: number?, speed: number? }?)
	local cue = CUES[name]
	if not cue then
		return
	end

	local id = clipFor(cue)
	if not id then
		return
	end

	local sound = instanceFor(id)
	sound.Volume = (options and options.volume) or cue.volume or 0.5
	sound.PlaybackSpeed = (options and options.speed) or cue.speed or 1
	sound:Play()
end

--[[
	Plays a moment that comes in streaks, with a pitch that climbs.

	A collectible answering with the same note every time reads as a metronome; a
	note that climbs reads as a combo. The rise is capped so a long streak does not
	end in a squeak, and the streak resets after a pause, so picking up two coins a
	minute apart sounds like two coins.

	The counter lives HERE rather than in the caller: a streak is a property of the
	sound being repeated, and every caller would otherwise reimplement the same
	clock.
]]
local STREAK_WINDOW = 1.2
local STREAK_CAP = 8
local STREAK_STEP = 0.06

local streaks: { [string]: { count: number, at: number } } = {}

function Sound.playRepeating(name: string)
	local now = os.clock()
	local previous = streaks[name]
	local count = if previous and now - previous.at <= STREAK_WINDOW then previous.count + 1 else 0

	streaks[name] = { count = count, at = now }
	Sound.play(name, { speed = 1 + math.min(count, STREAK_CAP) * STREAK_STEP })
end

return Sound
