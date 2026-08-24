--!strict
--[[
	Net — the network contract shared by client and server.

	Remote names are declared once, here: the client cannot listen to an event the
	server does not expose (or the other way round) without this file saying so.

	The server creates the instances, the client waits for them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local EVENTS = {
	"Notify", -- server -> client: short message
	"StartFlight", -- client -> server: take off from the Nest
	"BuyUpgrade", -- client -> server: buy an upgrade
	"Molt", -- client -> server: molt
	"PlaceEgg", -- client -> server: put an egg in the hatchery
	"CollectHatchling", -- client -> server: collect a hatched egg
	"RedeemCode", -- client -> server: promo code
	"ClaimDaily", -- client -> server: daily reward
	"ClaimChest", -- client -> server: session chest
	"PromptPurchase", -- client -> server: open a purchase window
	"CollectRing", -- client -> server: ring caught by the magnet
}

local FUNCTIONS = {
	"GetOffers", -- limited-time offers currently visible
	"GetRewardStatus", -- state of the daily reward and the session chest
}

local Net = {}

local function ensureFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

--[[ Server side: creates the missing remotes and returns the index. ]]
function Net.server()
	assert(RunService:IsServer(), "Net.server() must only be called on the server")

	local folder = ensureFolder()
	local remotes = { events = {}, functions = {} }

	for _, name in EVENTS do
		local remote = folder:FindFirstChild(name) or Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		remotes.events[name] = remote
	end

	for _, name in FUNCTIONS do
		local remote = folder:FindFirstChild(name) or Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
		remotes.functions[name] = remote
	end

	return remotes
end

--[[ Client side: waits for the remotes created by the server. ]]
function Net.client()
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	local remotes = { events = {}, functions = {} }

	for _, name in EVENTS do
		remotes.events[name] = folder:WaitForChild(name)
	end
	for _, name in FUNCTIONS do
		remotes.functions[name] = folder:WaitForChild(name)
	end

	return remotes
end

return Net
