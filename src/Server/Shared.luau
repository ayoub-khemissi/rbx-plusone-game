--!strict
--[[
	Raccourci vers ReplicatedStorage.Shared.

	Evite les chaines de `script.Parent.Parent.Parent...` dans tout le code serveur :
	un seul endroit connait l'emplacement reel du code partage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

return ReplicatedStorage:WaitForChild("Shared")
