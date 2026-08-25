--!strict
--[[
	SoundController — decides WHEN the game speaks.

	Every moment is wired to the most specific signal available, never to a
	convenient one. The distinction matters more than it looks:

	  * a Coin plays where it is caught, in MagnetController, not when the counter
	    moves. The counter also moves on treadmill income and on rewards, and it
	    written on every sampling tick — hanging the sound off it would turn a run
	    into a metronome;

	  * a purchase plays when an upgrade LEVEL rises, which is the one signal that
	    only ever means "the server accepted and charged you". Watching the Coin
	    balance fall would fire on every price the shop merely displays;

	  * a refusal plays on a cue the server sends, because a refusal is always
	    answered. Guessing it from a balance that failed to move would catch every
	    frame the player simply could not afford something;

	  * a fall plays on a cue the SERVER names, since it has no client-side signal
	    worth trusting. The server names the moment, never the clip — which sound it
	    makes stays a client decision.

	Nothing here sends anything. This controller only listens.
]]

local Sound = require(script.Parent.Parent.Sound)

local SoundController = {}
SoundController.__index = SoundController

function SoundController.new(state, remotes)
	local self = setmetatable({
		state = state,
		previous = {
			level = state:get("Level"),
			stage = state:get("ReachedStage"),
			prestiges = state:get("Prestiges"),
			boosts = #state:list("ActiveBoosts"),
			upgrades = {},
		},
	}, SoundController)

	state.changed:connect(function()
		self:_onStateChanged()
	end)

	-- Movement answers to the server's grant, not to the key press: the sound then
	-- marks what actually happened rather than what was asked for.
	remotes.events.JumpGranted.OnClientEvent:Connect(function()
		Sound.play("airJump")
	end)

	remotes.events.DashGranted.OnClientEvent:Connect(function()
		Sound.play("dash")
	end)

	remotes.events.Notify.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		-- Only what the server named. There is no fallback on the kind: a toast is
		-- not a sound, and guessing one from the other is how every message on the
		-- screen ended up making a noise.
		if typeof(payload.cue) == "string" then
			Sound.play(payload.cue)
		end
	end)

	return self
end

function SoundController._onStateChanged(self)
	local state = self.state
	local previous = self.previous

	-- Only ever upwards. A prestige drops the level back to 1, and announcing that
	-- with the level-up jingle would celebrate the wrong half of the trade.
	local level = state:get("Level")
	if level > previous.level then
		Sound.play("levelUp")
	end
	previous.level = level

	local stage = state:get("ReachedStage")
	if stage > previous.stage then
		Sound.play("stageReached")
	end
	previous.stage = stage

	local prestiges = state:get("Prestiges")
	if prestiges > previous.prestiges then
		Sound.play("prestige")
	end
	previous.prestiges = prestiges

	-- The list only lengthens when a boost starts; it shortens when one expires,
	-- which is not an event worth announcing.
	local boosts = #state:list("ActiveBoosts")
	if boosts > previous.boosts then
		Sound.play("boost")
	end
	previous.boosts = boosts

	self:_checkUpgrades()
end

--[[
	An upgrade level that rose means a purchase went through, whatever bought it.

	The first pass only records what is already owned: a player joining with twelve
	upgrades must not be greeted by twelve purchase sounds.
]]
function SoundController._checkUpgrades(self)
	local state = self.state
	local known = self.previous.upgrades

	for upgradeId, level in state.upgrades do
		local before = known[upgradeId]
		if before ~= nil and level > before then
			Sound.play("buy")
		end
		known[upgradeId] = level
	end
end

return SoundController
