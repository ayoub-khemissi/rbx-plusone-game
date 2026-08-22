--!strict
--[[
	RemoteNotifier — port Notifier via un RemoteEvent.

	Anti-spam : deux messages identiques envoyes coup sur coup au meme joueur sont
	fusionnes (une barriere de zone declenche sinon un message a chaque echantillon).
]]

local RemoteNotifier = {}
RemoteNotifier.__index = RemoteNotifier

local REPEAT_COOLDOWN = 3

function RemoteNotifier.new(remote: RemoteEvent, clock: any)
	return setmetatable({
		remote = remote,
		clock = clock or { now = os.clock },
		_last = {},
	}, RemoteNotifier)
end

function RemoteNotifier.notify(self, player: Player, message: string, kind: string?)
	if not player or not player.Parent then
		return
	end

	local now = self.clock.now()
	local last = self._last[player]

	if last and last.message == message and now - last.at < REPEAT_COOLDOWN then
		return
	end

	self._last[player] = { message = message, at = now }
	self.remote:FireClient(player, { message = message, kind = kind or "info" })
end

function RemoteNotifier.forget(self, player: Player)
	self._last[player] = nil
end

return RemoteNotifier
