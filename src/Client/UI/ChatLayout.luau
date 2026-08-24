--!strict
--[[
	ChatLayout — moves the Roblox chat window out of the way.

	By default the chat sits in the TOP LEFT corner, exactly where the stats card
	lives. It is pushed to the bottom left, the only area the interface leaves free.

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
