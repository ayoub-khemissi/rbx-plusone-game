--!strict
--[[
	MapBindings — reads the hand built map and turns touching a part into a game
	action.

	The contract is `docs/MAP.md`, and nothing else: a handful of tags, a few
	attributes, no naming convention and no imposed hierarchy.

	Two deliberate leniencies, because a map is built by hand and not by a compiler:

	  - a tag may sit on a Model as well as on a Part; every BasePart inside is wired;
	  - a missing attribute falls back to a sane default and logs, rather than being
	    ignored. A map should never be able to take the game down, nor to silently
	    do nothing.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local MapBindings = {}

MapBindings.TAGS = {
	checkpoint = "Checkpoint",
	-- Killzone and TrapPart are the same idea; both names are accepted so a map can
	-- use whichever word its author already had in mind.
	killzone = { "Killzone", "TrapPart" },
	coin = "Coin",
	speedGate = "SpeedGate",
	conveyor = "Conveyor",
	bouncePad = "BouncePad",
	shopPad = "ShopPad",
	prestigePad = "PrestigePad",
	finishPad = "FinishPad",
	treadmill = "Treadmill",
}

local FALL_GRACE_FALLBACK = 1
local PAD_COOLDOWN = 1
--[[
	A belt is something you stand ON. A generous box lets a player walk clear of one
	and still be counted on it, which leaves the run animation playing over an empty
	floor — so this one is deliberately tight.
]]
local TREADMILL_MARGIN = 2
local DEFAULT_STAGE = 1
local DEFAULT_BOUNCE = 200
local DEFAULT_CONVEYOR = 10

local function playerFromTouch(hit: BasePart): Player?
	local character = hit.Parent
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

--[[ Every BasePart carrying the tag, whether it is tagged directly or through a Model. ]]
local function partsOf(instance: Instance): { BasePart }
	if instance:IsA("BasePart") then
		return { instance }
	end

	local parts = {}
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

--[[ Connects a tag (or a list of aliases) to a handler, now and for what comes later. ]]
local function onTagged(tag: string | { string }, handler: (Instance) -> ())
	local names = if typeof(tag) == "table" then tag else { tag }
	for _, name in names do
		for _, instance in CollectionService:GetTagged(name) do
			handler(instance)
		end
		CollectionService:GetInstanceAddedSignal(name):Connect(handler)
	end
end

local function countTagged(tag: string | { string }): number
	local names = if typeof(tag) == "table" then tag else { tag }
	local total = 0
	for _, name in names do
		total += #CollectionService:GetTagged(name)
	end
	return total
end

function MapBindings.bind(container)
	local useCases = container.useCases
	local logger = container.ports.logger
	local settings = container.config.Balance.run
	local TAGS = MapBindings.TAGS

	local lastFall: { [Player]: number } = {}
	local lastPad: { [Player]: number } = {}
	local treadmills: { { part: BasePart, multiplier: number } } = {}
	local missingStageId = 0

	local function cooled(memory, player: Player, delay: number): boolean
		local now = os.clock()
		if memory[player] and now - memory[player] < delay then
			return false
		end
		memory[player] = now
		return true
	end

	--[[ Sends the player back to their checkpoint, once per grace period. ]]
	local function fall(player: Player)
		if cooled(lastFall, player, settings.fallGrace or FALL_GRACE_FALLBACK) then
			useCases.fallToCheckpoint:run(player)
		end
	end

	onTagged(TAGS.checkpoint, function(instance)
		-- A checkpoint with no StageId belongs to the first Stage: most maps have
		-- only one, and demanding the attribute would break them for nothing.
		local stageId = instance:GetAttribute("StageId")
		if typeof(stageId) ~= "number" then
			stageId = DEFAULT_STAGE
			missingStageId += 1
		end

		for _, part in partsOf(instance) do
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
		end
	end)

	onTagged(TAGS.killzone, function(instance)
		for _, part in partsOf(instance) do
			part.Touched:Connect(function(hit)
				local player = playerFromTouch(hit)
				if player then
					fall(player)
				end
			end)
		end
	end)

	--[[
		A Coin is a MARKER, and everything the player sees of it happens on their own
		machine: the turning, the draw towards them, the disappearance, the thirty
		seconds before it comes back.

		That is not an optimisation, it is the rule. Coins are counted per player, so
		a course swept by whoever ran it a minute ago still pays the next player, and
		two friends running together are not racing for the same pickup. A server
		that hid the part would hide it from everyone at once.

		So no Touched here: the client says which Coin it reached and the server
		checks the tag, the distance and the player's own field before paying. It
		still forces the part anchored and untouchable — a Coin is run through, not
		into, and a solid one blocks the course.
	]]
	onTagged(TAGS.coin, function(instance)
		for _, part in partsOf(instance) do
			part.CanCollide = false
			part.CanTouch = false
			part.Anchored = true
		end
	end)

	--[[
		Conveyor belts need no per-player logic: an anchored part with a velocity
		drags whatever stands on it, and Roblox physics does the rest.

		The direction is the part's front face, so rotating the part in Studio is
		enough to change where it pushes.
	]]
	onTagged(TAGS.conveyor, function(instance)
		for _, part in partsOf(instance) do
			local speed = part:GetAttribute("Speed")
			if typeof(speed) ~= "number" then
				speed = DEFAULT_CONVEYOR
			end
			part.AssemblyLinearVelocity = part.CFrame.LookVector * speed
		end
	end)

	--[[ Bounce pads: a designed launch, so the vertical speed is replaced, not added. ]]
	onTagged(TAGS.bouncePad, function(instance)
		for _, part in partsOf(instance) do
			local impulse = part:GetAttribute("BounceImpulse")
			if typeof(impulse) ~= "number" then
				impulse = DEFAULT_BOUNCE
			end

			part.Touched:Connect(function(hit)
				local player = playerFromTouch(hit)
				local character = player and player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					local velocity = root.AssemblyLinearVelocity
					root.AssemblyLinearVelocity = Vector3.new(velocity.X, impulse, velocity.Z)
				end
			end)
		end
	end)

	local function padHandler(open: (Player) -> ())
		return function(instance)
			for _, part in partsOf(instance) do
				part.Touched:Connect(function(hit)
					local player = playerFromTouch(hit)
					if player and cooled(lastPad, player, PAD_COOLDOWN) then
						open(player)
					end
				end)
			end
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

	--[[
		The plate at the end of a course. It reads its own StageId, because the plate
		is what says a course was CLEARED — a checkpoint only says the player walked
		in. A plate with no id names no course and is ignored with a warning rather
		than paying out the wrong one.
	]]
	onTagged(TAGS.finishPad, function(instance)
		local stageId = instance:GetAttribute("StageId")
		if typeof(stageId) ~= "number" then
			logger:warn(`A {TAGS.finishPad} has no StageId and will pay nothing: {instance:GetFullName()}`)
			return
		end

		for _, part in partsOf(instance) do
			part.Touched:Connect(function(hit)
				local player = playerFromTouch(hit)
				if player and cooled(lastPad, player, PAD_COOLDOWN) then
					useCases.finishStage:run(player, stageId)
				end
			end)
		end
	end)

	--[[
		Treadmills are polled for the same reason, and carry the multiplier they are
		worth. A belt with no multiplier is a decoration, not a fault: it runs at x1
		and the console says so.
	]]
	onTagged(TAGS.treadmill, function(instance)
		local multiplier = instance:GetAttribute("Multiplier")
		if typeof(multiplier) ~= "number" or multiplier <= 0 then
			logger:warn(`A {TAGS.treadmill} has no Multiplier and will run at x1: {instance:GetFullName()}`)
			multiplier = 1
		end

		for _, part in partsOf(instance) do
			table.insert(treadmills, { part = part, multiplier = multiplier })
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastFall[player] = nil
		lastPad[player] = nil
	end)

	--[[
		The multiplier of the belt under a player, or nil if there is none.

		The strongest one wins where belts overlap, which is the answer a player
		expects when they are standing on two.
	]]
	local function treadmillAt(position: { x: number, y: number, z: number }): number?
		local best: number? = nil
		for _, belt in treadmills do
			local part = belt.part
			if part.Parent then
				local size, centre = part.Size, part.Position
				local withinX = math.abs(position.x - centre.X) <= size.X / 2 + TREADMILL_MARGIN
				local withinZ = math.abs(position.z - centre.Z) <= size.Z / 2 + TREADMILL_MARGIN
				local withinY = math.abs(position.y - centre.Y) <= size.Y / 2 + TREADMILL_MARGIN * 3

				if withinX and withinY and withinZ and (best == nil or belt.multiplier > best) then
					best = belt.multiplier
				end
			end
		end
		return best
	end

	--[[ The report announced in docs/MAP.md: what the server actually found. ]]
	local function report()
		logger:info(
			`Map loaded: {countTagged(TAGS.checkpoint)} checkpoints, {countTagged(TAGS.killzone)} hazards, `
				.. `{countTagged(TAGS.coin)} coins, {countTagged(TAGS.conveyor)} conveyors, `
				.. `{countTagged(TAGS.bouncePad)} bounce pads, {#treadmills} treadmills`
		)
		if missingStageId > 0 then
			logger:info(`{missingStageId} checkpoints without a StageId, assigned to Stage {DEFAULT_STAGE}`)
		end
		if countTagged(TAGS.checkpoint) == 0 then
			logger:warn("No Checkpoint in the map: players will always respawn at the Hub")
		end
	end

	return { treadmillAt = treadmillAt, fall = fall, report = report }
end

--[[
	Whether a part is one of the map's hazards. Read by the void detection, which
	must not mistake a Killzone slab for the floor it is lying under.
]]
function MapBindings.isKillzone(part: Instance): boolean
	for _, tag in MapBindings.TAGS.killzone do
		if CollectionService:HasTag(part, tag) then
			return true
		end
	end
	return false
end

return MapBindings
