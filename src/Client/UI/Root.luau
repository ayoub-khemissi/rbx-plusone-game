--!strict
--[[ Root — assembles the interface: HUD, sidebar, windows, offers, messages. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Theme = require(script.Parent.Theme)
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

	local hud = Hud.new(screen, state)
	local notifications = Notifications.new(screen)

	local panels = {
		shop = ShopPanel.new(screen, state, remotes),
		prestige = PrestigePanel.new(screen, state, remotes),
		gifts = RewardsPanel.new(screen, state, remotes),
		store = StorePanel.new(screen, state, remotes),
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

	Sidebar.new(screen, {
		{ name = "Shop", icon = LABELS.coins.icon, onClick = exclusiveToggle("shop") },
		{ name = "Prestige", icon = LABELS.prestige.icon, onClick = exclusiveToggle("prestige") },
		{ name = "Gifts", icon = "🎁", onClick = exclusiveToggle("gifts") },
		{ name = "Store", icon = "💎", color = Theme.color.accentDark, onClick = exclusiveToggle("store") },
	})

	-- A hub pad can ask for a window: the map decides where the shop is.
	remotes.events.OpenPanel.OnClientEvent:Connect(function(key)
		if panels[key] then
			exclusiveToggle(key)()
		end
	end)

	OfferPopup.new(screen, remotes)

	remotes.events.Notify.OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" and typeof(payload.message) == "string" then
			notifications:push(payload.message, payload.kind)
		end
	end)

	return { screen = screen, hud = hud, panels = panels, notifications = notifications }
end

return Root
