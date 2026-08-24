--!strict
--[[ MoltPanel — states plainly what molting costs and what it pays. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local MoltPanel = {}
MoltPanel.__index = MoltPanel

function MoltPanel.new(parent: ScreenGui, state, remotes)
	local panel = Panel.new(parent, { name = "Molt", title = "🐉 Molt", size = UDim2.fromOffset(500, 340) })
	local self = setmetatable({ panel = panel, state = state, remotes = remotes }, MoltPanel)

	local explain = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 66),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		wrapped = true,
		textScaled = false,
		text = "Molting resets your speed, your gold and your upgrades, and raises every"
			.. " future gain for good. Your dragons are never touched.",
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
		text = "MOLT",
		size = UDim2.new(1, 0, 0, 54),
		position = UDim2.new(0, 0, 1, -8),
		anchorPoint = Vector2.new(0, 1),
		onClick = function()
			self.remotes.events.Molt:FireServer()
		end,
	})

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function MoltPanel.render(self)
	local state = self.state
	local molts = state:get("Molts")
	local progress = state:get("MoltProgress")
	local perMolt = Config.Balance.molt.multiplierPerMolt

	self.current.Text = `Molts: {molts} — bonus {Format.multiplier(state:get("MoltMultiplier"))}`
	self.next.Text = `After this one: {Format.multiplier(1 + (molts + 1) * perMolt)} on every gain`
	self.progressLabel.Text =
		`{Format.abbreviate(state:get("Speed"))} / {Format.abbreviate(state:get("MoltRequirement"))} speed`
	self.bar.set(progress)

	local ready = progress >= 1
	self.action.BackgroundColor3 = if ready then Theme.color.positive else Theme.color.locked
	self.action.Text = if ready then "MOLT" else `{Format.percent(1 - progress)} TO GO`
end

function MoltPanel.toggle(self)
	self.panel:toggle()
end

return MoltPanel
