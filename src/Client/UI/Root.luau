--!strict
--[[ Root — assemble l'interface : HUD, menu lateral, fenetres, offres, messages. ]]

local Theme = require(script.Parent.Theme)
local Hud = require(script.Parent.Hud)
local Sidebar = require(script.Parent.Sidebar)
local Notifications = require(script.Parent.Notifications)
local ShopPanel = require(script.Parent.ShopPanel)
local RebirthPanel = require(script.Parent.RebirthPanel)
local ZonesPanel = require(script.Parent.ZonesPanel)
local RewardsPanel = require(script.Parent.RewardsPanel)
local StorePanel = require(script.Parent.StorePanel)
local OfferPopup = require(script.Parent.OfferPopup)
local ChatLayout = require(script.Parent.ChatLayout)

local Root = {}

function Root.mount(player: Player, state, remotes)
	-- Liberer le coin haut-gauche avant de poser le HUD qui l'occupe.
	ChatLayout.apply()

	local screen = Instance.new("ScreenGui")
	screen.Name = "SingeRapide"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = player:WaitForChild("PlayerGui")

	local hud = Hud.new(screen, state)
	local notifications = Notifications.new(screen)

	local panels = {
		shop = ShopPanel.new(screen, state, remotes),
		rebirth = RebirthPanel.new(screen, state, remotes),
		zones = ZonesPanel.new(screen, state, remotes),
		rewards = RewardsPanel.new(screen, state, remotes),
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
		{ name = "Boutique", icon = "🛒", onClick = exclusiveToggle("shop") },
		{ name = "Renaissance", icon = "🔥", onClick = exclusiveToggle("rebirth") },
		{ name = "Zones", icon = "🗺️", onClick = exclusiveToggle("zones") },
		{ name = "Cadeaux", icon = "🎁", onClick = exclusiveToggle("rewards") },
		{ name = "Robux", icon = "💎", color = Theme.color.accentDark, onClick = exclusiveToggle("store") },
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
