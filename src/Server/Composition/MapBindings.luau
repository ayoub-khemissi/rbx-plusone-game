--!strict
--[[
	MapBindings — reads the hand built map and turns touching a part into a game
	action.

	The contract is `docs/MAP.md`, and nothing else: seven tags, a few attributes, no
	naming convention and no imposed hierarchy. The server never creates, moves or
	renames anything in the map.

	A tagged part that is misconfigured is ignored with a console warning rather than
	crashing the server: a map should never be able to take the game down.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local MapBindings = {}

MapBindings.TAGS = {
	checkpoint = "Checkpoint",
	killzone = "Killzone",
	coin = "Coin",
	speedGate = "SpeedGate",
	shopPad = "ShopPad",
	prestigePad = "PrestigePad",
	idlePad = "AfkPad",
}

local FALL_GRACE_FALLBACK = 1
local PAD_COOLDOWN = 1
local IDLE_PAD_MARGIN = 6

local function playerFromTouch(hit: BasePart): Player?
	local character = hit.Parent
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

--[[ Connects a tag to a handler, for the parts already there and the ones to come. ]]
local function onTagged(tag: string, handler: (Instance) -> ())
	for _, instance in CollectionService:GetTagged(tag) do
		handler(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(handler)
end

local function countTagged(tag: string): number
	return #CollectionService:GetTagged(tag)
end

function MapBindings.bind(container)
	local useCases = container.useCases
	local logger = container.ports.logger
	local settings = container.config.Balance.run
	local TAGS = MapBindings.TAGS

	local lastFall: { [Player]: number } = {}
	local lastPad: { [Player]: number } = {}
	local idlePads: { BasePart } = {}

	local function cooled(memory, player: Player, delay: number): boolean
		local now = os.clock()
		if memory[player] and now - memory[player] < delay then
			return false
		end
		memory[player] = now
		return true
	end

	-- Checkpoints: the backbone of a course. Without a StageId a checkpoint cannot
	-- be priced, so it is skipped rather than guessed.
	onTagged(TAGS.checkpoint, function(instance)
		local part = instance :: BasePart
		local stageId = part:GetAttribute("StageId")

		if typeof(stageId) ~= "number" then
			logger:warn(`A Checkpoint has no StageId, ignored ({part:GetFullName()})`)
			return
		end

		part.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if not player then
				return
			end
			useCases.reachCheckpoint:run(player, {
				stageId = stageId,
				position = {
					x = part.Position.X,
					y = part.Position.Y + settings.respawnHeight,
					z = part.Position.Z,
				},
			})
		end)
	end)

	-- Killzones: the void under the course, and anything else that hurts.
	onTagged(TAGS.killzone, function(instance)
		local part = instance :: BasePart
		part.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			-- The grace period stops a killzone from firing again on the way out.
			if player and cooled(lastFall, player, settings.fallGrace or FALL_GRACE_FALLBACK) then
				useCases.fallToCheckpoint:run(player)
			end
		end)
	end)

	onTagged(TAGS.coin, function(instance)
		local part = instance :: BasePart
		local value = part:GetAttribute("Value")
		if typeof(value) ~= "number" then
			value = settings.coinValue
		end

		part.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if not player or not part.CanTouch then
				return
			end

			useCases.collectCoin:run(player, value)

			part.Transparency = 1
			part.CanTouch = false
			task.delay(settings.coinRespawn, function()
				if part.Parent then
					part.Transparency = 0
					part.CanTouch = true
				end
			end)
		end)
	end)

	local function padHandler(open: (Player) -> ())
		return function(instance)
			local part = instance :: BasePart
			part.Touched:Connect(function(hit)
				local player = playerFromTouch(hit)
				if player and cooled(lastPad, player, PAD_COOLDOWN) then
					open(player)
				end
			end)
		end
	end

	onTagged(
		TAGS.shopPad,
		padHandler(function(player)
			container.remotes.events.OpenPanel:FireClient(player, "shop")
		end)
	)

	onTagged(
		TAGS.prestigePad,
		padHandler(function(player)
			useCases.performPrestige:run(player)
		end)
	)

	-- The idle pad is polled by the sampling loop rather than wired to Touched:
	-- standing still on a part does not keep firing Touched events.
	onTagged(TAGS.idlePad, function(instance)
		if instance:IsA("BasePart") then
			table.insert(idlePads, instance)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastFall[player] = nil
		lastPad[player] = nil
	end)

	--[[ Is this position standing on one of the idle pads? ]]
	local function isOnIdlePad(position: { x: number, y: number, z: number }): boolean
		for _, pad in idlePads do
			if pad.Parent then
				local size, centre = pad.Size, pad.Position
				local withinX = math.abs(position.x - centre.X) <= size.X / 2 + IDLE_PAD_MARGIN
				local withinZ = math.abs(position.z - centre.Z) <= size.Z / 2 + IDLE_PAD_MARGIN
				local withinY = math.abs(position.y - centre.Y) <= size.Y / 2 + IDLE_PAD_MARGIN * 2

				if withinX and withinY and withinZ then
					return true
				end
			end
		end
		return false
	end

	--[[ The report announced in docs/MAP.md: what the server actually found. ]]
	local function report()
		logger:info(
			`Map loaded: {countTagged(TAGS.checkpoint)} checkpoints, {countTagged(TAGS.coin)} coins, `
				.. `{countTagged(TAGS.killzone)} killzones, {countTagged(TAGS.speedGate)} speed gates, `
				.. `{#idlePads} idle pads`
		)
		if countTagged(TAGS.checkpoint) == 0 then
			logger:warn("No Checkpoint in the map: players will always respawn at the Hub")
		end
		if countTagged(TAGS.killzone) == 0 then
			logger:warn("No Killzone in the map: a player falling off will never come back")
		end
	end

	return { isOnIdlePad = isOnIdlePad, report = report }
end

return MapBindings
