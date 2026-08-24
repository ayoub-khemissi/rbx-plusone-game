--!strict
--[[
	ChatLayout — moves the Roblox chat window out of the way.

	By default the chat window opens in the top left, underneath the platform's own
	menu, chat and voice buttons. It is pushed to the bottom left, which leaves that
	corner to Roblox and the centre to the game.

	Guarded: on an engine version that would not expose these properties, the game
	keeps running with the default chat.
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
