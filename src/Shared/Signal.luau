--!strict
--[[ Signal — evenement minimal (connect / fire / disconnect), sans dependance. ]]

local Signal = {}
Signal.__index = Signal

export type Connection = { disconnect: (Connection) -> () }

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal.connect(self, handler: (...any) -> ()): Connection
	table.insert(self._handlers, handler)

	return {
		disconnect = function()
			local index = table.find(self._handlers, handler)
			if index then
				table.remove(self._handlers, index)
			end
		end,
	}
end

function Signal.fire(self, ...)
	for _, handler in table.clone(self._handlers) do
		task.spawn(handler, ...)
	end
end

function Signal.destroy(self)
	table.clear(self._handlers)
end

return Signal
