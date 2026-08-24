--!strict
--[[
	Client entry point.

	The client computes no gain: it reads the state replicated by the server, draws
	the interface and handles FEEL — instant jumps and dashes, effects, gates that
	open without waiting. Every decision that pays stays on the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)

local State = require(script.State)
local Root = require(script.UI.Root)
local MovementController = require(script.Controllers.MovementController)
local SpeedGateController = require(script.Controllers.SpeedGateController)
local MagnetController = require(script.Controllers.MagnetController)
local EffectsController = require(script.Controllers.EffectsController)
local SoundController = require(script.Controllers.SoundController)

local player = Players.LocalPlayer
local remotes = Net.client()
local state = State.new(player)

Root.mount(player, state, remotes)

MovementController.new(player, state, remotes)
SpeedGateController.new(state)
MagnetController.new(player, state, remotes)
EffectsController.new(player, state)
SoundController.new(state, remotes)
