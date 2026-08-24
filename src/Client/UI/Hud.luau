--!strict
--[[
	Hud — what stays on screen.

	Three things must be readable in one second of flight: how fast I am, what I am
	carrying that I could lose, and how far the next barrier is.

	The pouch panel is the emotional centre of the game. It only shows up in flight,
	it uses its own warm colour, and it says out loud what banking would pay — that
	is the number the player is gambling with.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local Hud = {}
Hud.__index = Hud

local function tierName(tierId: number): string
	local tier = Config.Tiers[tierId]
	return if tier then tier.name else "The Nest"
end

function Hud.new(parent: ScreenGui, state, remotes)
	local self = setmetatable({ state = state, remotes = remotes }, Hud)

	-- Permanent stats, top left.
	local card = Widgets.card(parent, {
		name = "Stats",
		size = UDim2.fromOffset(268, 146),
		position = UDim2.fromOffset(14, 14),
	})
	Widgets.padding(card, 12)

	self.speedLabel = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 42),
		font = Theme.font.title,
		color = Theme.color.accent,
		text = "⚡ 0",
	})

	self.goldLabel = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 46),
		font = Theme.font.number,
		text = "🪙 0",
	})

	self.moltLabel = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 74),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		text = "🐉 0 — gains x1",
	})

	self.tierLabel = Widgets.label(card, {
		size = UDim2.new(1, 0, 0, 20),
		position = UDim2.fromOffset(0, 98),
		font = Theme.font.body,
		color = Theme.color.textMuted,
		text = tierName(1),
	})

	self.tierBar = Widgets.bar(card, {
		size = UDim2.new(1, 0, 0, 10),
		position = UDim2.fromOffset(0, 122),
	})

	-- The pouch at risk, centre bottom: impossible to miss while flying.
	self.pouchCard = Widgets.card(parent, {
		name = "Pouch",
		size = UDim2.fromOffset(300, 92),
		position = UDim2.new(0.5, 0, 1, -18),
		anchorPoint = Vector2.new(0.5, 1),
		color = Theme.color.pouch,
		transparency = 0.15,
		visible = false,
	})
	Widgets.padding(self.pouchCard, 10)

	self.pouchTitle = Widgets.label(self.pouchCard, {
		size = UDim2.new(1, 0, 0, 22),
		font = Theme.font.number,
		color = Theme.color.background,
		align = Enum.TextXAlignment.Center,
		text = "AT RISK",
	})

	self.pouchValue = Widgets.label(self.pouchCard, {
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.fromOffset(0, 24),
		font = Theme.font.title,
		color = Theme.color.background,
		align = Enum.TextXAlignment.Center,
		text = "🪙 0",
	})

	self.pouchHint = Widgets.label(self.pouchCard, {
		size = UDim2.new(1, 0, 0, 18),
		position = UDim2.fromOffset(0, 56),
		font = Theme.font.body,
		color = Theme.color.background,
		align = Enum.TextXAlignment.Center,
		textScaled = false,
		text = "Fly through an Altar to bank it",
	})
	self.pouchHint.TextSize = 14

	-- Take off button, only at the Nest.
	self.launchButton = Widgets.button(parent, {
		name = "Launch",
		text = "🐉 TAKE OFF",
		size = UDim2.fromOffset(220, 56),
		position = UDim2.new(0.5, 0, 1, -18),
		anchorPoint = Vector2.new(0.5, 1),
		color = Theme.color.positive,
		onClick = function()
			self.remotes.events.StartFlight:FireServer()
		end,
	})

	-- Active boosts and feathers, top right.
	self.statusCard = Widgets.card(parent, {
		name = "Status",
		size = UDim2.fromOffset(210, 34),
		position = UDim2.new(1, -14, 0, 14),
		anchorPoint = Vector2.new(1, 0),
		visible = false,
	})
	Widgets.padding(self.statusCard, 8)
	self.statusLabel = Widgets.label(self.statusCard, {
		font = Theme.font.number,
		color = Theme.color.positive,
		align = Enum.TextXAlignment.Center,
	})

	state.changed:connect(function()
		self:render()
	end)
	self:render()

	return self
end

function Hud.render(self)
	local state = self.state
	local flying = state:flag("Flying")

	self.speedLabel.Text = `⚡ {Format.abbreviate(state:get("Speed"))}`
	self.goldLabel.Text = `🪙 {Format.abbreviate(state:get("Gold"))}`
	self.moltLabel.Text =
		`🐉 {state:get("Molts")} — gains {Format.multiplier(state:get("SpeedMultiplier"))}`

	local reached = math.max(state:get("ReachedTier"), 1)
	local nextRequirement = state:get("NextTierRequirement")
	self.tierLabel.Text = if nextRequirement > 0
		then `{tierName(reached)} → next barrier {Format.abbreviate(nextRequirement)}`
		else `{tierName(reached)} — the last tier`
	self.tierBar.set(state:get("TierProgress"))

	-- The pouch replaces the take off button: they are never both relevant.
	self.pouchCard.Visible = flying
	self.launchButton.Visible = not flying

	if flying then
		local tier = state:get("PouchTier")
		self.pouchValue.Text =
			`🪙 {Format.abbreviate(state:get("PouchGold"))}   🥚 {state:get("PouchEggs")}`
		self.pouchHint.Text = if tier > 0
			then `Tier {tier} — an Altar banks it, a wall takes it`
			else "Cross the first tier to fill the pouch"
	end

	local parts = {}
	for _, boost in state:list("ActiveBoosts") do
		table.insert(parts, `{boost.icon or "⏱"} {math.ceil((boost.remaining or 0) / 60)}m`)
	end
	if state:get("Feathers") > 0 then
		table.insert(parts, `🪶 {state:get("Feathers")}`)
	end
	if state:flag("Insured") then
		table.insert(parts, "🛡️")
	end

	self.statusLabel.Text = table.concat(parts, "  ")
	self.statusCard.Visible = #parts > 0
end

return Hud
