--!nocheck
--[[
	Doubles de test pour les PORTS de la couche Application.
	Every double records the calls it receives, so a test can assert on them.
]]

local Fakes = {}

function Fakes.clock(startTime: number?)
	local now = startTime or 0
	return {
		now = function()
			return now
		end,
		monotonic = function()
			return now
		end,
		advance = function(seconds: number)
			now += seconds
		end,
	}
end

function Fakes.marketplace()
	local fake = { prompts = {} }

	function fake:promptProduct(player, productId: number)
		table.insert(self.prompts, { player = player, productId = productId })
	end

	function fake:promptGamePass(player, assetId: number)
		table.insert(self.prompts, { player = player, assetId = assetId })
	end

	return fake
end

function Fakes.repository()
	local store = {}
	local fake = { saves = 0, loads = 0, failNext = false }

	function fake:load(userId: number)
		self.loads += 1
		if self.failNext then
			self.failNext = false
			error("panne simulee du datastore")
		end
		return store[userId]
	end

	function fake:save(userId: number, profile)
		self.saves += 1
		if self.failNext then
			self.failNext = false
			error("panne simulee du datastore")
		end
		store[userId] = profile
		return true
	end

	function fake:seed(userId: number, profile)
		store[userId] = profile
	end

	function fake:raw(userId: number)
		return store[userId]
	end

	return fake
end

function Fakes.publisher()
	local fake = { snapshots = {}, last = nil }

	function fake:publish(playerRef, snapshot)
		table.insert(self.snapshots, { player = playerRef, snapshot = snapshot })
		self.last = snapshot
	end

	return fake
end

function Fakes.notifier()
	local fake = { messages = {} }

	function fake:notify(playerRef, message: string, kind: string?, cue: string?)
		table.insert(
			self.messages,
			{ player = playerRef, message = message, kind = kind or "info", cue = cue }
		)
	end

	function fake:lastMessage(): string?
		local entry = self.messages[#self.messages]
		return entry and entry.message
	end

	function fake:cues(): { string }
		local cues = {}
		for _, entry in self.messages do
			if entry.cue then
				table.insert(cues, entry.cue)
			end
		end
		return cues
	end

	return fake
end

function Fakes.actuator()
	local fake = { applied = {}, last = nil }

	function fake:apply(playerRef, flight)
		table.insert(self.applied, flight)
		self.last = flight
	end

	return fake
end

--[[ Deterministic generator: walks the given list, then loops. ]]
function Fakes.random(values: { number }?)
	local sequence = values or { 0.5 }
	local cursor = 0

	return {
		nextNumber = function()
			cursor += 1
			return sequence[((cursor - 1) % #sequence) + 1]
		end,
	}
end

function Fakes.body()
	local fake = { destinations = {}, kills = 0 }

	function fake:sendTo(playerRef, position)
		table.insert(self.destinations, position)
		self.last = position
	end

	function fake:kill(playerRef)
		self.kills += 1
	end

	return fake
end

function Fakes.passGateway(owned: { [string]: boolean }?)
	local fake = { owned = owned or {} }

	function fake:ownedPasses(playerRef)
		return self.owned
	end

	function fake:promptPurchase() end

	return fake
end

function Fakes.snapshots()
	return {
		build = function(_self, session)
			return {
				speed = session.profile.speed,
				bananas = session.profile.bananas,
				rebirths = session.profile.rebirths,
				zoneId = session.zoneId,
				upgrades = table.clone(session.profile.upgrades),
			}
		end,
	}
end

function Fakes.player(userId: number, name: string?)
	return { UserId = userId, Name = name or `Player{userId}` }
end

return Fakes
