--!nocheck
--[[
	Doubles de test pour les PORTS de la couche Application.
	Chaque double enregistre les appels recus afin de pouvoir les asserter.
]]

local Fakes = {}

function Fakes.clock(startTime: number?)
	local now = startTime or 0
	return {
		now = function()
			return now
		end,
		advance = function(seconds: number)
			now += seconds
		end,
	}
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

	function fake:notify(playerRef, message: string, kind: string?)
		table.insert(self.messages, { player = playerRef, message = message, kind = kind or "info" })
	end

	function fake:lastMessage(): string?
		local entry = self.messages[#self.messages]
		return entry and entry.message
	end

	return fake
end

function Fakes.actuator()
	local fake = { applied = {}, last = nil }

	function fake:apply(playerRef, movement)
		table.insert(self.applied, movement)
		self.last = movement
	end

	return fake
end

function Fakes.teleporter()
	local fake = { destinations = {} }

	function fake:sendTo(playerRef, position)
		table.insert(self.destinations, position)
		self.last = position
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

function Fakes.player(userId: number, name: string?)
	return { UserId = userId, Name = name or `Joueur{userId}` }
end

return Fakes
