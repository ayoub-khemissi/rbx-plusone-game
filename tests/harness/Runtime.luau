--!nocheck
--[[
	Runtime — execute les ModuleScripts de l'arbre virtuel avec la semantique Roblox :
	globale `script`, `require(instance)` avec cache, et un `game` minimal.

	Les modules du Domaine et de l'Application n'utilisent aucune API Roblox ;
	ce runtime suffit donc a les tester integralement en ligne de commande.
]]

local luau = require("@lune/luau")

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(dataModel)
	return setmetatable({
		dataModel = dataModel,
		_cache = {},
		_loading = {},
	}, Runtime)
end

function Runtime:_environmentFor(scriptNode)
	local env = {}
	env.script = scriptNode
	env.game = self.dataModel
	env.workspace = self.dataModel:FindFirstChild("Workspace")
	env.require = function(target)
		return self:require(target)
	end
	return env
end

--[[ Equivalent de `require(module)` cote Roblox : execution unique puis cache. ]]
function Runtime:require(target)
	if typeof(target) ~= "table" or target.ClassName == nil then
		error(`require() expects an Instance of the virtual tree, got: {typeof(target)}`, 2)
	end
	if target.ClassName ~= "ModuleScript" then
		error(`require() sur {target:GetFullName()} qui est un {target.ClassName}`, 2)
	end

	local cached = self._cache[target]
	if cached ~= nil then
		return cached.value
	end
	if self._loading[target] then
		error(`Dependance circulaire detectee sur {target:GetFullName()}`, 2)
	end

	self._loading[target] = true
	local chunk = luau.load(target._source, {
		debugName = target._path or target:GetFullName(),
		environment = self:_environmentFor(target),
	})
	local value = chunk()
	self._loading[target] = nil

	self._cache[target] = { value = value }
	return value
end

--[[ Loads a spec file with the extra globals it expects (describe/it/expect...). ]]
function Runtime:loadScript(path: string, source: string, extraGlobals: { [string]: any })
	local pseudoScript = {
		ClassName = "ModuleScript",
		Name = path,
		Parent = nil,
		_source = source,
		_path = path,
		GetFullName = function()
			return path
		end,
		FindFirstChild = function()
			return nil
		end,
	}

	local env = self:_environmentFor(pseudoScript)
	for key, value in extraGlobals do
		env[key] = value
	end

	return luau.load(source, { debugName = path, environment = env })
end

return Runtime
