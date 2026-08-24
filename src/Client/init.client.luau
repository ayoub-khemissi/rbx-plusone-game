--!strict
--[[
	Client entry point.

	The client computes no gain: it reads the state replicated by the server, draws
	the interface and handles FEEL (responsive flight, effects, gate colours). Every
	game decision stays on the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)

local State = require(script.State)
local Root = require(script.UI.Root)
local FlightController = require(script.Controllers.FlightController)
local GateController = require(script.Controllers.GateController)
local MagnetController = require(script.Controllers.MagnetController)
local EffectsController = require(script.Controllers.EffectsController)

local player = Players.LocalPlayer
local remotes = Net.client()
local state = State.new(player)

Root.mount(player, state, remotes)

FlightController.new(player, state)
GateController.new(state)
MagnetController.new(player, state, remotes)
EffectsController.new(player, state)
