--!strict
--[[
	ChatLayout — repositionne la fenetre de chat Roblox.

	Par defaut le chat s'affiche en HAUT A GAUCHE, exactement la ou vit la carte de
	statistiques (vitesse, bananes, renaissances). On le bascule en bas a gauche,
	seule zone de l'ecran laissee libre par l'interface du jeu.

	La configuration est protegee : sur une version de moteur qui n'exposerait pas
	ces proprietes, le jeu continue de tourner avec le chat par defaut.
]]

local TextChatService = game:GetService("TextChatService")

local WAIT_TIMEOUT = 10

local ChatLayout = {}

function ChatLayout.apply()
	local window = TextChatService:WaitForChild("ChatWindowConfiguration", WAIT_TIMEOUT)
	if not window then
		return false
	end

	local ok = pcall(function()
		window.HorizontalAlignment = Enum.HorizontalAlignment.Left
		window.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end)

	return ok
end

return ChatLayout
