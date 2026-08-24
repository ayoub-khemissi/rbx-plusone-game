--!strict
--[[ Root — assembles the interface: HUD, sidebar, windows, offers, messages. ]]

local Theme = require(script.Parent.Theme)
local Hud = require(script.Parent.Hud)
local Sidebar = require(script.Parent.Sidebar)
local Notifications = require(script.Parent.Notifications)
local ShopPanel = require(script.Parent.ShopPanel)
local NestPanel = require(script.Parent.NestPanel)
local MoltPanel = require(script.Parent.MoltPanel)
local RewardsPanel = require(script.Parent.RewardsPanel)
local StorePanel = require(script.Parent.StorePanel)
local OfferPopup = require(script.Parent.OfferPopup)
local ChatLayout = require(script.Parent.ChatLayout)

local Root = {}

function Root.mount(player: Player, state, remotes)
	-- Free the top left corner before the HUD claims it.
	ChatLayout.apply()

	local screen = Instance.new("ScreenGui")
	screen.Name = "SkyDragons"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = player:WaitForChild("PlayerGui")

	local hud = Hud.new(screen, state, remotes)
	local notifications = Notifications.new(screen)

	local panels = {
		shop = ShopPanel.new(screen, state, remotes),
		nest = NestPanel.new(screen, state, remotes),
		molt = MoltPanel.new(screen, state, remotes),
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

	Sidebar.new(screen, {
		{ name = "Shop", icon = "🪙", onClick = exclusiveToggle("shop") },
		{ name = "Nest", icon = "🪺", onClick = exclusiveToggle("nest") },
		{ name = "Molt", icon = "🐉", onClick = exclusiveToggle("molt") },
		{ name = "Gifts", icon = "🎁", onClick = exclusiveToggle("gifts") },
		{ name = "Store", icon = "💎", color = Theme.color.accentDark, onClick = exclusiveToggle("store") },
	})

	OfferPopup.new(screen, remotes)

	remotes.events.Notify.OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" and typeof(payload.message) == "string" then
			notifications:push(payload.message, payload.kind)
		end
	end)

	return { screen = screen, hud = hud, panels = panels, notifications = notifications }
end

return Root
