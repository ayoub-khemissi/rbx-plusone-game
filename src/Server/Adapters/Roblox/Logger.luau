--!strict
--[[ Logger — sortie console prefixee, injectable (donc remplacable en test). ]]

local Logger = {}
Logger.__index = Logger

function Logger.new(prefix: string)
	return setmetatable({ prefix = prefix }, Logger)
end

function Logger.info(self, message: string)
	print(`[{self.prefix}] {message}`)
end

function Logger.warn(self, message: string)
	warn(`[{self.prefix}] {message}`)
end

return Logger
