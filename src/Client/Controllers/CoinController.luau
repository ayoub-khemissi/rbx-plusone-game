--!strict
--[[
	CoinController — every Coin the player sees, and the pull that takes it.

	EACH PLAYER RUNS THEIR OWN FIELD. The map holds one part per Coin, but nothing
	the player sees happen to it is replicated: the turning, the draw towards them,
	the disappearance and the thirty seconds before it comes back are all done here,
	on their machine, to their copy of the world. A course swept clean by whoever ran
	it a minute ago is still full for the next player, and two friends running
	together are never racing for the same pickup.

	That is what makes the parts local property. A client may move, hide and restore
	a replicated part freely; the change simply stays home. The server never touches
	their position or transparency, so nothing ever fights over them.

	WHAT THE SERVER STILL OWNS is whether the pickup counts. The client says which
	Coin it reached; the server checks the tag, the distance and the player's own
	field, and answers with what the Coin was worth after multipliers. The animation
	is feedback, never a payment.

	THE DRAW is the Magnet made visible. There has always been a radius inside which
	a Coin was collected; before, it teleported into the counter. Now it flies in,
	and the upgrade simply widens the circle it flies from.

	WHAT KEEPS IT CHEAP. A world holds hundreds of Coins and only a handful are ever
	near the player. The far ones are found on a slow pass, a few times a second, and
	only the near ones are touched per frame. The per-frame cost follows what is on
	screen rather than what is in the map.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Sound = require(script.Parent.Parent.Sound)

local CoinController = {}
CoinController.__index = CoinController

local COIN_TAG = "Coin"
local LABEL = Config.Theme.labels.coins
local RESPAWN = Config.Balance.run.coinRespawn
local REACH = Config.Balance.run.coinReach

-- How often the field is swept for what is near enough to matter. Far enough apart
-- to cost nothing, close enough that a Coin is never run past.
local SCAN_INTERVAL = 0.1
-- Past this a Coin is left alone entirely: not turned, not measured. Well beyond
-- both the draw and what the eye reads as movement.
local CULL_RANGE = 200

local TURNS_PER_SECOND = 0.5
local DRAW_TIME = 0.32
local DRAW_HEIGHT = 2.5
-- Where a Coin flies to: the chest rather than the feet, so it reads as caught.
local CHEST_OFFSET = Vector3.new(0, 1, 0)

function CoinController.new(player: Player, state, remotes, popups)
	local self = setmetatable({
		player = player,
		state = state,
		remotes = remotes,
		popups = popups,
		coins = {},
		near = {},
		sinceScan = 0,
	}, CoinController)

	for _, instance in CollectionService:GetTagged(COIN_TAG) do
		self:_track(instance)
	end
	CollectionService:GetInstanceAddedSignal(COIN_TAG):Connect(function(instance)
		self:_track(instance)
	end)
	CollectionService:GetInstanceRemovedSignal(COIN_TAG):Connect(function(instance)
		self.coins[instance] = nil
	end)

	remotes.events.CollectCoin.OnClientEvent:Connect(function(part, granted)
		self:_onGranted(part, granted)
	end)

	-- A new body finds the course full again, which is the other half of the rule
	-- the server applies to the field it keeps.
	player.CharacterAdded:Connect(function()
		self:_restoreAll()
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		self:_update(deltaTime)
	end)

	return self
end

--[[ A Coin the map declares. Parts only: a model is tagged part by part. ]]
function CoinController._track(self, instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end

	self.coins[instance] = {
		part = instance,
		home = instance.CFrame,
		-- "idle" waiting to be taken, "drawn" flying in, "gone" until it returns.
		phase = "idle",
		elapsed = 0,
		takenAt = 0,
		from = instance.Position,
		granted = nil,
	}
end

function CoinController._root(self): BasePart?
	local character = self.player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

--[[ How far a Coin is collected from: what the Magnet is actually buying. ]]
function CoinController._reach(self): number
	return REACH + math.max(self.state:get("Magnet"), 0)
end

function CoinController._update(self, deltaTime: number)
	local root = self:_root()

	self.sinceScan += deltaTime
	if self.sinceScan >= SCAN_INTERVAL then
		self.sinceScan = 0
		self:_scan(root)
	end

	for coin in self.near do
		self:_step(coin, deltaTime, root)
	end
end

--[[
	Rebuilds the short list of Coins worth spending a frame on, and claims the ones
	within reach. Everything costly is decided here, ten times a second.
]]
function CoinController._scan(self, root: BasePart?)
	table.clear(self.near)
	if not root then
		return
	end

	local reach = self:_reach()
	local now = os.clock()

	for _, coin in self.coins do
		if not coin.part.Parent then
			continue
		end

		local distance = (coin.part.Position - root.Position).Magnitude
		if distance > CULL_RANGE then
			continue
		end

		if coin.phase == "gone" then
			if now - coin.takenAt < RESPAWN then
				continue
			end
			self:_restore(coin)
		end

		self.near[coin] = true

		if coin.phase == "idle" and distance <= reach then
			coin.phase = "drawn"
			coin.elapsed = 0
			coin.from = coin.part.Position
			self.remotes.events.CollectCoin:FireServer(coin.part)
		end
	end
end

--[[ One Coin, one frame: turning on the spot, or on its way in. ]]
function CoinController._step(self, coin, deltaTime: number, root: BasePart?)
	local spin = CFrame.Angles(0, deltaTime * TURNS_PER_SECOND * math.pi * 2, 0)

	if coin.phase == "idle" then
		coin.part.CFrame = coin.part.CFrame * spin
		return
	end

	if coin.phase ~= "drawn" then
		return
	end

	if not root then
		-- The body vanished mid-flight. Put the Coin back; whether it was paid for
		-- is the server's business, not this animation's.
		self:_restore(coin)
		return
	end

	coin.elapsed += deltaTime
	local progress = math.min(coin.elapsed / DRAW_TIME, 1)

	-- Eased so the Coin leaves slowly and arrives fast: pulled, not thrown.
	local pull = progress * progress
	local target = root.Position + CHEST_OFFSET
	local position = coin.from:Lerp(target, pull)
	-- A hop over the straight line, so the flight has a shape at any distance.
	position += Vector3.new(0, math.sin(progress * math.pi) * DRAW_HEIGHT, 0)

	coin.part.CFrame = CFrame.new(position) * (coin.part.CFrame - coin.part.Position) * spin

	if progress >= 1 then
		self:_land(coin)
	end
end

--[[ The Coin has arrived: where the player is told what they earned. ]]
function CoinController._land(self, coin)
	coin.phase = "gone"
	coin.takenAt = os.clock()
	coin.part.CFrame = coin.home
	coin.part.LocalTransparencyModifier = 1
	self.near[coin] = nil

	if coin.granted then
		self:_announce(coin.granted)
		coin.granted = nil
	end
end

--[[
	The server's answer, carrying the Coin so it needs no matching on this side.

	It usually arrives while the Coin is still flying, and is held until it lands:
	the number belongs to the moment of catching it, not to the moment the network
	came back.
]]
function CoinController._onGranted(self, part, granted)
	local coin = self.coins[part]
	if not coin or typeof(granted) ~= "number" or granted <= 0 then
		return
	end

	if coin.phase == "drawn" then
		coin.granted = granted
	else
		self:_announce(granted)
	end
end

function CoinController._announce(self, granted: number)
	Sound.playRepeating("coin")
	self.popups:spawn(`+{math.floor(granted)}`, LABEL.image)
end

function CoinController._restore(_self, coin)
	coin.phase = "idle"
	coin.granted = nil
	coin.part.CFrame = coin.home
	coin.part.LocalTransparencyModifier = 0
end

function CoinController._restoreAll(self)
	for _, coin in self.coins do
		if coin.phase ~= "idle" then
			self:_restore(coin)
		end
	end
end

return CoinController
