--!strict
--[[ RebirthPanel — explique clairement ce que la renaissance coute et rapporte. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local RebirthPanel = {}
RebirthPanel.__index = RebirthPanel

function RebirthPanel.new(parent: ScreenGui, state, remotes)
	local panel = Panel.new(parent, {
		name = "Renaissance",
		title = "🔥 Renaissance",
		size = UDim2.fromOffset(480, 330),
	})

	local self = setmetatable({ panel = panel, state = state, remotes = remotes }, RebirthPanel)

	self.explain = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 66),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		wrapped = true,
		textScaled = false,
		text = "Renaitre remet ta vitesse, tes bananes et tes ameliorations a zero,"
			.. " mais augmente definitivement tous tes gains.",
	})
	self.explain.TextSize = 16

	self.current = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.fromOffset(0, 74),
		font = Theme.font.title,
		color = Theme.color.accent,
		text = "",
	})

	self.next = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 108),
		font = Theme.font.number,
		color = Theme.color.positive,
		text = "",
	})

	self.progressLabel = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 140),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		text = "",
	})

	self.bar = Widgets.bar(panel.content, {
		size = UDim2.new(1, 0, 0, 16),
		position = UDim2.fromOffset(0, 166),
		color = Theme.color.positive,
	})

	self.action = Widgets.button(panel.content, {
		text = "RENAITRE",
		size = UDim2.new(1, 0, 0, 54),
		position = UDim2.new(0, 0, 1, -8),
		anchorPoint = Vector2.new(0, 1),
		onClick = function()
			self.remotes.events.Rebirth:FireServer()
		end,
	})

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function RebirthPanel.render(self)
	local state = self.state
	local rebirths = state:get("Rebirths")
	local required = state:get("RebirthRequirement")
	local progress = state:get("RebirthProgress")
	local perRebirth = Config.Balance.rebirth.multiplierPerRebirth

	self.current.Text =
		`Renaissances : {rebirths} — bonus {Format.multiplier(state:get("RebirthMultiplier"))}`
	self.next.Text =
		`Apres celle-ci : {Format.multiplier(1 + (rebirths + 1) * perRebirth)} sur tous les gains`
	self.progressLabel.Text =
		`{Format.abbreviate(state:get("Speed"))} / {Format.abbreviate(required)} de vitesse`
	self.bar.set(progress)

	local ready = progress >= 1
	self.action.BackgroundColor3 = if ready then Theme.color.positive else Theme.color.locked
	self.action.Text = if ready then "RENAITRE" else `ENCORE {Format.percent(1 - progress)}`
end

function RebirthPanel.toggle(self)
	self.panel:toggle()
end

return RebirthPanel
