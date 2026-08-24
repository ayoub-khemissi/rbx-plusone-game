--!strict
--[[
	RemoteNotifier — the Notifier port, over a RemoteEvent.

	Anti-spam: two identical messages sent back to back to the same player are
	merged. Without it, standing against a gate produces one message per sample.
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

function RemoteNotifier.notify(self, player: Player, message: string, kind: string?, cue: string?)
	if not player or not player.Parent then
		return
	end

	local now = self.clock.now()
	local last = self._last[player]

	-- A repeated CUE is not spam: falling twice in three seconds is two falls, and
	-- both carry the same empty message. Only a repeated message is silenced.
	if last and last.message == message and cue == nil and now - last.at < REPEAT_COOLDOWN then
		return
	end

	self._last[player] = { message = message, at = now }
	self.remote:FireClient(player, { message = message, kind = kind or "info", cue = cue })
end

function RemoteNotifier.forget(self, player: Player)
	self._last[player] = nil
end

return RemoteNotifier
