--!strict
--[[
	WorldBindings — branche les elements marques de la carte sur les cas d'usage.

	Le generateur de carte pose des tags (Banane, Obstacle, PadRenaissance...) ;
	c'est ici, et seulement ici, qu'un contact devient une action de jeu.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldBuilder = require(script.Parent.Parent.World.WorldBuilder)

local WorldBindings = {}

local TAGS = WorldBuilder.TAGS

local function playerFromTouch(hit: BasePart): Player?
	local character = hit.Parent
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

--[[ Connecte un tag a un gestionnaire, pour les parties presentes et a venir. ]]
local function onTagged(tag: string, handler: (Instance) -> ())
	for _, instance in CollectionService:GetTagged(tag) do
		handler(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(handler)
end

function WorldBindings.bind(container, world: Folder)
	local useCases = container.useCases
	local session = container.config.Balance.session
	local collecting: { [BasePart]: boolean } = {}
	local rebirthCooldown: { [Player]: number } = {}

	--[[ Ramassage d'une banane : credite puis fait disparaitre la banane un moment. ]]
	local function collect(player: Player, banana: BasePart)
		if collecting[banana] then
			return
		end
		collecting[banana] = true

		useCases.collectBanana:run(player, banana:GetAttribute("Valeur") or 0)

		banana.Transparency = 1
		banana.CanTouch = false

		task.delay(session.bananaRespawnDelay, function()
			collecting[banana] = nil
			if banana.Parent then
				banana.Transparency = 0
				banana.CanTouch = true
			end
		end)
	end

	onTagged(TAGS.banana, function(instance)
		local banana = instance :: BasePart
		banana.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if player then
				collect(player, banana)
			end
		end)
	end)

	onTagged(TAGS.obstacle, function(instance)
		local obstacle = instance :: BasePart
		obstacle.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if not player then
				return
			end
			-- Penalite courte : ralentir plutot que tuer garde le rythme du jeu.
			player:SetAttribute("StunnedUntil", os.clock() + session.obstacleStunDuration)
		end)
	end)

	onTagged(TAGS.rebirthPad, function(instance)
		local pad = instance :: BasePart
		pad.Touched:Connect(function(hit)
			local player = playerFromTouch(hit)
			if not player then
				return
			end
			local now = os.clock()
			if rebirthCooldown[player] and now - rebirthCooldown[player] < 2 then
				return
			end
			rebirthCooldown[player] = now
			useCases.performRebirth:run(player)
		end)
	end)

	-- Rotors : une seule boucle pour toute la carte.
	local spinners = CollectionService:GetTagged(TAGS.spinner)
	CollectionService:GetInstanceAddedSignal(TAGS.spinner):Connect(function(instance)
		table.insert(spinners, instance)
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		for _, instance in spinners do
			local spinner = instance :: BasePart
			if spinner.Parent then
				spinner.CFrame *= CFrame.Angles(0, (spinner:GetAttribute("SpinSpeed") or 1) * deltaTime, 0)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		rebirthCooldown[player] = nil
	end)

	-- Le ramassage est expose au binding reseau (aimant a bananes).
	return { collect = collect, folder = world }
end

return WorldBindings
