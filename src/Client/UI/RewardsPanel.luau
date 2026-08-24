--!strict
--[[
	RewardsPanel — everything that is free: daily streak, session chest, promo codes.
	This is the window that makes a player come back tomorrow.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Domain.Support.Format)

local Panel = require(script.Parent.Panel)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)

local RewardsPanel = {}
RewardsPanel.__index = RewardsPanel

local REFRESH_INTERVAL = 5

function RewardsPanel.new(parent: ScreenGui, state, remotes)
	local panel =
		Panel.new(parent, { name = "Gifts", title = "🎁 Gifts", size = UDim2.fromOffset(500, 400) })
	local self = setmetatable({ panel = panel, state = state, remotes = remotes }, RewardsPanel)

	self.dailyTitle = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 26),
		font = Theme.font.title,
		text = "Daily reward",
	})

	self.dailyDetail = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 28),
		font = Theme.font.body,
		color = Theme.color.textMuted,
	})

	self.dailyButton = Widgets.button(panel.content, {
		text = "CLAIM",
		size = UDim2.new(1, 0, 0, 46),
		position = UDim2.fromOffset(0, 56),
		onClick = function()
			self.remotes.events.ClaimDaily:FireServer()
			task.delay(0.4, function()
				self:refresh()
			end)
		end,
	})

	Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 118),
		font = Theme.font.title,
		text = Config.Monetization.sessionChest.label,
	})

	self.chestDetail = Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, 146),
		font = Theme.font.body,
		color = Theme.color.textMuted,
	})

	self.chestButton = Widgets.button(panel.content, {
		text = "OPEN",
		size = UDim2.new(1, 0, 0, 46),
		position = UDim2.fromOffset(0, 174),
		onClick = function()
			self.remotes.events.ClaimChest:FireServer()
			task.delay(0.4, function()
				self:refresh()
			end)
		end,
	})

	Widgets.label(panel.content, {
		size = UDim2.new(1, 0, 0, 26),
		position = UDim2.fromOffset(0, 236),
		font = Theme.font.title,
		text = "Promo code",
	})

	local input = Instance.new("TextBox")
	input.Name = "CodeInput"
	input.Size = UDim2.new(0.62, 0, 0, 44)
	input.Position = UDim2.fromOffset(0, 266)
	input.BackgroundColor3 = Theme.color.background
	input.BorderSizePixel = 0
	input.Font = Theme.font.number
	input.PlaceholderText = "YOUR CODE"
	input.Text = ""
	input.TextColor3 = Theme.color.text
	input.TextScaled = true
	input.ClearTextOnFocus = false
	input.Parent = panel.content
	Widgets.corner(input)

	Widgets.button(panel.content, {
		text = "REDEEM",
		size = UDim2.new(0.34, 0, 0, 44),
		position = UDim2.new(1, 0, 0, 266),
		anchorPoint = Vector2.new(1, 0),
		color = Theme.color.positive,
		onClick = function()
			if input.Text ~= "" then
				self.remotes.events.RedeemCode:FireServer(input.Text)
				input.Text = ""
			end
		end,
	})

	panel.onOpen = function()
		self:refresh()
	end

	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			if panel.isOpen then
				self:refresh()
			end
		end
	end)

	return self
end

--[[ Asks the server: it holds the reference clock. ]]
function RewardsPanel.refresh(self)
	local ok, status = pcall(function()
		return self.remotes.functions.GetRewardStatus:InvokeServer()
	end)
	if not ok or typeof(status) ~= "table" then
		return
	end

	local daily = status.daily
	if daily then
		self.dailyDetail.Text = `Day {daily.day} — streak of {daily.streak}`
		self.dailyButton.Text = if daily.claimable
			then "CLAIM"
			else `NEXT IN {Format.duration(daily.secondsRemaining)}`
		self.dailyButton.BackgroundColor3 = if daily.claimable then Theme.color.accent else Theme.color.locked
	end

	local chest = status.chest
	if chest then
		self.chestDetail.Text = `+{Format.abbreviate((chest.grant and chest.grant.coins) or 0)} Coins`
		self.chestButton.Text = if chest.claimable
			then "OPEN"
			else `READY IN {Format.duration(chest.secondsRemaining)}`
		self.chestButton.BackgroundColor3 = if chest.claimable
			then Theme.color.positive
			else Theme.color.locked
	end
end

function RewardsPanel.toggle(self)
	self.panel:toggle()
end

return RewardsPanel
