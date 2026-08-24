--!strict
--[[ PrestigePanel — states plainly what a prestige costs and what it pays. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local PrestigePanel = {}
PrestigePanel.__index = PrestigePanel

local LABELS = Config.Theme.labels

function PrestigePanel.new(parent: ScreenGui, state, remotes)
	local panel = Panel.new(parent, {
		name = "Prestige",
		title = `{LABELS.prestige.icon} {LABELS.prestige.name}`,
		size = UDim2.fromOffset(500, 340),
	})
	local self = setmetatable({ panel = panel, state = state, remotes = remotes }, PrestigePanel)

	local explain = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 66),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		wrapped = true,
		textScaled = false,
		text = `Resets your {LABELS.speed.name}, your {LABELS.coins.plural} and your upgrades, and raises`
			.. " every future gain for good.",
	})
	explain.TextSize = 16

	self.current = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.fromOffset(0, 74),
		font = Theme.font.title,
		color = Theme.color.accent,
	})

	self.next = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 108),
		font = Theme.font.number,
		color = Theme.color.positive,
	})

	self.progressLabel = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 140),
		font = Theme.font.body,
		color = Theme.color.textMuted,
	})

	self.bar = Widgets.bar(panel.content, {
		size = UDim2.new(1, 0, 0, 16),
		position = UDim2.fromOffset(0, 166),
		color = Theme.color.positive,
	})

	self.action = Widgets.button(panel.content, {
		text = LABELS.prestige.verb or "PRESTIGE",
		size = UDim2.new(1, 0, 0, 54),
		position = UDim2.new(0, 0, 1, -8),
		anchorPoint = Vector2.new(0, 1),
		onClick = function()
			self.remotes.events.Prestige:FireServer()
		end,
	})

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function PrestigePanel.render(self)
	local state = self.state
	local prestiges = state:get("Prestiges")
	local progress = state:get("PrestigeProgress")
	local perPrestige = Config.Balance.prestige.multiplierPerPrestige

	self.current.Text = `{LABELS.prestige.plural or LABELS.prestige.name}: {prestiges} — {Format.multiplier(
		state:get("PrestigeMultiplier")
	)}`
	self.next.Text = `After this one: {Format.multiplier(1 + (prestiges + 1) * perPrestige)} on every gain`
	self.progressLabel.Text = `{Format.abbreviate(state:get("Speed"))} / {Format.abbreviate(
		state:get("PrestigeRequirement")
	)} {LABELS.speed.name}`
	self.bar.set(progress)

	local ready = progress >= 1
	self.action.BackgroundColor3 = if ready then Theme.color.positive else Theme.color.locked
	self.action.Text = if ready
		then (LABELS.prestige.verb or "PRESTIGE")
		else `{Format.percent(1 - progress)} TO GO`
end

function PrestigePanel.toggle(self)
	self.panel:toggle()
end

return PrestigePanel
