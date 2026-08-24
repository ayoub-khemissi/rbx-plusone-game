--!strict
--[[ Root — assembles the interface: HUD, sidebar, windows, offers, messages. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local Hud = require(script.Parent.Hud)
local Sidebar = require(script.Parent.Sidebar)
local Notifications = require(script.Parent.Notifications)
local ShopPanel = require(script.Parent.ShopPanel)
local PrestigePanel = require(script.Parent.PrestigePanel)
local RewardsPanel = require(script.Parent.RewardsPanel)
local StorePanel = require(script.Parent.StorePanel)
local OfferPopup = require(script.Parent.OfferPopup)
local ChatLayout = require(script.Parent.ChatLayout)

local Root = {}

function Root.mount(player: Player, state, remotes)
	-- Free the top left corner before the HUD claims it.
	ChatLayout.apply()

	local screen = Instance.new("ScreenGui")
	screen.Name = "Runner"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = player:WaitForChild("PlayerGui")

	-- Everything is built inside the scaled frame: sizes are written once, for a
	-- 1280x720 screen, and this is what makes them mean the same on every device.
	local root = Widgets.scaled(screen)

	local hud = Hud.new(root, state)
	local notifications = Notifications.new(root)

	local panels = {
		shop = ShopPanel.new(root, state, remotes),
		prestige = PrestigePanel.new(root, state, remotes),
		gifts = RewardsPanel.new(root, state, remotes),
		store = StorePanel.new(root, state, remotes),
	}

	local function exclusiveToggle(key: string)
		return function()
			for name, panel in panels do
				if name ~= key then
					panel.panel:close()
				end
			end
			panels[key]:toggle()
		end
	end

	local LABELS = Config.Theme.labels
	local ICONS = Config.Theme.icons

	-- One colour per window: the player learns the position AND the colour, and stops
	-- reading the caption after the first minute.
	Sidebar.new(root, {
		{
			name = "Shop",
			icon = LABELS.coins.icon,
			image = ICONS.shop,
			color = Theme.color.negative,
			onClick = exclusiveToggle("shop"),
		},
		{
			name = LABELS.prestige.name,
			icon = LABELS.prestige.icon,
			image = LABELS.prestige.image,
			color = Theme.color.info,
			onClick = exclusiveToggle("prestige"),
		},
		{
			name = "Gifts",
			icon = "🎁",
			image = ICONS.gifts,
			color = Theme.color.positive,
			onClick = exclusiveToggle("gifts"),
		},
		{
			name = "Store",
			icon = "💎",
			image = ICONS.store,
			color = Theme.color.special,
			onClick = exclusiveToggle("store"),
		},
	})

	-- A hub pad can ask for a window: the map decides where the shop is.
	remotes.events.OpenPanel.OnClientEvent:Connect(function(key)
		if panels[key] then
			exclusiveToggle(key)()
		end
	end)

	OfferPopup.new(root, remotes)

	remotes.events.Notify.OnClientEvent:Connect(function(payload)
		-- An empty message is a cue-only notification: it exists to make a sound,
		-- and a toast with nothing in it would be worse than no toast.
		if typeof(payload) == "table" and typeof(payload.message) == "string" and payload.message ~= "" then
			notifications:push(payload.message, payload.kind)
		end
	end)

	return { screen = screen, root = root, hud = hud, panels = panels, notifications = notifications }
end

return Root
