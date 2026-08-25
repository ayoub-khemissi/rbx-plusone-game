--!strict
--[[
	Sounds — what the game says out loud, by moment rather than by file.

	Every entry is a MOMENT, not an audio clip: `coin`, `levelUp`, `refused`. Views
	and controllers ask for the moment, so swapping a clip, retuning a volume or
	handing the whole set to a themed variant never touches a line of logic.

	`variants` is for anything heard hundreds of times in a session. A single coin
	clip becomes grating within a minute; three picked at random stay pleasant far
	longer, and cost nothing but three ids.

	An entry left at `nil` is simply silent. That is the honest default for a moment
	nobody has chosen a sound for yet, and it means the game never plays a wrong
	sound while a set is half filled in.

	All of these come from the Free Audio of `thienbao2109` on the Roblox store.
]]

export type Cue = {
	id: string?,
	variants: { string }?,
	volume: number?,
	speed: number?,
}

local sounds: { [string]: Cue } = {
	-- Heard constantly. Three variants, quiet: this one has to survive a whole
	-- session without becoming an irritation.
	coin = {
		variants = {
			"rbxassetid://4612374807",
			"rbxassetid://4612374937",
			"rbxassetid://4612375051",
		},
		volume = 0.22,
	},

	-- The reward moment. Louder than everything else on purpose: it is the one
	-- event the whole progression builds towards.
	levelUp = { id = "rbxassetid://3120909354", volume = 0.75 },

	-- A stage cleared, which is rarer and bigger than a level.
	stageReached = { id = "rbxassetid://5711770745", volume = 0.7 },

	-- The long loop closing. Three seconds, and it should feel like an event.
	prestige = { id = "rbxassetid://2789424255", volume = 0.8 },

	-- Movement. Short whooshes, quiet, because they fire under the player's hands
	-- many times a minute and must never compete with the reward sounds.
	airJump = { id = "rbxassetid://3809085250", volume = 0.3 },
	dash = { id = "rbxassetid://3809085996", volume = 0.4 },

	-- Stage events.
	checkpoint = { id = "rbxassetid://4612384434", volume = 0.5 },
	fall = { id = "rbxassetid://4612384231", volume = 0.45 },

	-- Economy. `buy` carries a cash register, which is the sound a purchase is
	-- expected to make; `refused` is deliberately dry and short.
	buy = { id = "rbxassetid://4612383453", volume = 0.6 },
	refused = { id = "rbxassetid://7153932260", volume = 0.4 },
	reward = { id = "rbxassetid://4612373756", volume = 0.65 },
	boost = { id = "rbxassetid://3406813517", volume = 0.6 },
}

return table.freeze(sounds)
