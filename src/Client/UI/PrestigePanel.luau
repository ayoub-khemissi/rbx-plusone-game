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

function PrestigePanel.new(parent: Instance, state, remotes)
	local panel = Panel.new(parent, {
		name = "Prestige",
		title = string.upper(LABELS.prestige.name),
		size = UDim2.fromOffset(540, 380),
	})
	local self = setmetatable({ panel = panel, state = state, remotes = remotes }, PrestigePanel)

	local explain = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 66),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		wrapped = true,
		textSize = Theme.text.small,
		text = `Resets your {LABELS.speed.name}, your {LABELS.coins.plural} and your upgrades, and raises`
			.. " every future gain for good.",
	})
	explain.TextYAlignment = Enum.TextYAlignment.Top

	self.current = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.fromOffset(0, 74),
		font = Theme.font.title,
		textSize = Theme.text.big,
		color = Theme.color.accentDark,
	})

	self.next = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 108),
		font = Theme.font.number,
		textSize = Theme.text.body,
		color = Theme.color.positive,
	})

	self.progressLabel = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 140),
		font = Theme.font.body,
		textSize = Theme.text.small,
		color = Theme.color.textMuted,
	})

	self.bar = Widgets.bar(panel.content, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 166),
		color = Theme.color.positive,
	})

	self.action = Widgets.button(panel.content, {
		text = LABELS.prestige.verb or "PRESTIGE",
		size = UDim2.new(1, 0, 0, 58),
		position = UDim2.new(0, 0, 1, -6),
		anchorPoint = Vector2.new(0, 1),
		textSize = Theme.text.big,
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
	-- The multiplier compounds, so the next one is a factor of the current one
	-- rather than a step added to it.
	local growth = Config.Balance.prestige.multiplierGrowth

	self.current.Text = `{LABELS.prestige.plural or LABELS.prestige.name}: {prestiges} — {Format.multiplier(
		state:get("PrestigeMultiplier")
	)}`
	self.next.Text =
		`After this one: {Format.multiplier(state:get("PrestigeMultiplier") * growth)} on every gain`
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
