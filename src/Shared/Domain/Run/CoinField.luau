--!strict
--[[
	CoinField — which Coins a player has already taken, and when they come back.

	COINS ARE COUNTED PER PLAYER, never per server. A course swept by whoever ran it
	a minute ago is a course that pays the next player nothing, and two friends
	running it together should not be racing each other for the same pickup. Each
	player empties their own field.

	The state is a plain table of when each Coin was taken, held on the session and
	never persisted: a Coin belongs to a run, not to progress. A new body finds the
	whole course full again, which is what makes a fall cost time rather than money.

	Nothing here knows what a Coin IS — it takes an identifier and a clock. That is
	what lets the rule be tested without a map.
]]

export type State = { taken: { [any]: number } }

local CoinField = {}

function CoinField.newState(): State
	return { taken = {} }
end

--[[
	Takes a Coin if the player may have it, and says whether they could.

	A refusal is ordinary, not an error. The client asks the moment a Coin comes
	within reach and may ask again while the first answer is still travelling; the
	window is what stops one Coin paying twice.
]]
function CoinField.claim(state: State, coin: any, now: number, respawn: number): boolean
	local takenAt = state.taken[coin]
	if takenAt ~= nil and now - takenAt < respawn then
		return false
	end

	state.taken[coin] = now
	return true
end

--[[ Every Coin back on the course. ]]
function CoinField.clear(state: State)
	table.clear(state.taken)
end

return CoinField
