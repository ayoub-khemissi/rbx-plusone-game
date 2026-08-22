--!strict
--[[
	Net — contrat reseau partage client/serveur.

	Les noms des remotes sont declares une seule fois ici : impossible pour le client
	d'ecouter un evenement que le serveur n'expose pas (ou l'inverse) sans que ce
	fichier ne le dise.

	Le serveur cree les instances, le client les attend.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local EVENTS = {
	"Notify", -- serveur -> client : message court
	"BuyUpgrade", -- client -> serveur : achat d'amelioration
	"Rebirth", -- client -> serveur : renaissance
	"TravelZone", -- client -> serveur : voyage rapide
	"RedeemCode", -- client -> serveur : code promo
	"ClaimDaily", -- client -> serveur : recompense quotidienne
	"ClaimChest", -- client -> serveur : coffre de session
	"PromptPurchase", -- client -> serveur : ouvrir une fenetre d'achat
	"CollectBanana", -- client -> serveur : ramassage a distance (aimant)
}

local FUNCTIONS = {
	"GetOffers", -- offres a duree limitee visibles
	"GetRewardStatus", -- etat du quotidien et du coffre
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

--[[ Cote serveur : cree les remotes manquantes et renvoie l'index. ]]
function Net.server()
	assert(RunService:IsServer(), "Net.server() ne doit etre appele que sur le serveur")

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

--[[ Cote client : attend les remotes creees par le serveur. ]]
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
