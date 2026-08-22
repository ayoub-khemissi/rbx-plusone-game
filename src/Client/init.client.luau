--!strict
--[[
	Point d'entree du client.

	Le client ne calcule aucun gain : il lit l'etat repliqué par le serveur, affiche
	l'interface et gere le CONFORT de jeu (mouvement nerveux, effets, barrieres
	traversables). Toute decision de jeu reste serveur.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)

local State = require(script.State)
local Root = require(script.UI.Root)
local WallRunController = require(script.Controllers.WallRunController)
local GateController = require(script.Controllers.GateController)
local PassPerksController = require(script.Controllers.PassPerksController)
local SpeedEffectsController = require(script.Controllers.SpeedEffectsController)

local player = Players.LocalPlayer
local remotes = Net.client()
local state = State.new(player)

Root.mount(player, state, remotes)

WallRunController.new(player, state)
GateController.new(state)
PassPerksController.new(player, state, remotes)
SpeedEffectsController.new(player, state)
