--!strict
--[[
	RemoteNotifier — the Notifier port, over a RemoteEvent.

	Anti-spam: two identical messages sent back to back to the same player are
	merged. Without it, standing against a gate produces one message per sample.

	Cues are not messages and are never merged: falling twice in three seconds is
	two falls, and a sound that swallows its repeats stops marking the moment.
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

function RemoteNotifier.cue(self, player: Player, name: string)
	if not player or not player.Parent then
		return
	end

	self.remote:FireClient(player, { cue = name })
end

function RemoteNotifier.forget(self, player: Player)
	self._last[player] = nil
end

return RemoteNotifier
