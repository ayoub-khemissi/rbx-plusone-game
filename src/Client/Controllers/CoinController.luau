--!strict
--[[
	CoinController — makes the coins turn, and answers when one is taken.

	THE SPIN IS LOCAL. Rotating a part on the server replicates a CFrame to every
	client several times a second, for something nobody can interact with; done
	here it costs one loop and no network at all. Coins are anchored, so moving
	them locally changes nothing anybody else sees.

	THE PICKUP IS ANSWERED BY THE SERVER, and that is a deliberate reversal of how
	the jump and the dash work. Those are answered locally because latency in a
	control is felt as lag. A coin is different: what the player wants to see is the
	AMOUNT, and after multipliers only the server knows it. Showing a number the
	client guessed would be worse than showing it forty milliseconds later.

	It also fixes a hole. Coins were only ever answered by the magnet path, so a
	coin taken by walking into it was silent — which is every coin, until the magnet
	is bought.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Sound = require(script.Parent.Parent.Sound)

local CoinController = {}
CoinController.__index = CoinController

local COIN_TAG = "Coin"
local TURNS_PER_SECOND = 0.45
local LABEL = Config.Theme.labels.coins

function CoinController.new(popups)
	local self = setmetatable({ popups = popups }, CoinController)

	local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Events")
	remotes:WaitForChild("CollectCoin").OnClientEvent:Connect(function(amount)
		self:_onCollected(amount)
	end)

	RunService.RenderStepped:Connect(function(deltaTime)
		self:_spin(deltaTime)
	end)

	return self
end

function CoinController._onCollected(self, amount: number)
	if typeof(amount) ~= "number" or amount <= 0 then
		return
	end

	Sound.playRepeating("coin")
	self.popups:spawn(`+{math.floor(amount)}`, LABEL.image)
end

function CoinController._spin(_self, deltaTime: number)
	local step = CFrame.Angles(0, deltaTime * TURNS_PER_SECOND * math.pi * 2, 0)

	for _, instance in CollectionService:GetTagged(COIN_TAG) do
		-- A collected coin is waiting to come back and cannot be touched; turning it
		-- would only heat the processor.
		if instance:IsA("BasePart") then
			if instance.CanTouch then
				instance.CFrame = instance.CFrame * step
			end
		elseif instance:IsA("Model") then
			-- A coin built as a model — a mesh with a light, say. Its pivot is what
			-- the builder placed, so that is what turns.
			local anchor = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
			if anchor and anchor.CanTouch then
				instance:PivotTo(instance:GetPivot() * step)
			end
		end
	end
end

return CoinController
