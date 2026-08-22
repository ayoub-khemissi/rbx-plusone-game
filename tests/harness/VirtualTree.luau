--!nocheck
--[[
	VirtualTree — reconstruit une arborescence d'Instances Roblox en memoire a partir
	de `default.project.json` et du systeme de fichiers.

	C'est un ADAPTATEUR DE TEST : il permet d'executer, hors de Roblox Studio, tout
	module ecrit avec la semantique Roblox habituelle (`script.Parent.Foo`,
	`game:GetService(...)`). Le code de production n'a aucune connaissance de ce fichier.
]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local VirtualTree = {}

local Instance_ = {}
Instance_.__index = function(self, key)
	local field = rawget(Instance_, key)
	if field ~= nil then
		return field
	end
	return rawget(self, "_children")[key]
end

function Instance_:GetChildren()
	local out = {}
	for _, child in self._order do
		table.insert(out, child)
	end
	return out
end

function Instance_:FindFirstChild(name: string)
	return self._children[name]
end

function Instance_:WaitForChild(name: string)
	local child = self._children[name]
	if not child then
		error(`WaitForChild("{name}") a echoue sur {self:GetFullName()} (arbre virtuel)`, 2)
	end
	return child
end

function Instance_:IsA(className: string): boolean
	if self.ClassName == className then
		return true
	end
	if className == "LuaSourceContainer" then
		return self.ClassName == "ModuleScript"
			or self.ClassName == "Script"
			or self.ClassName == "LocalScript"
	end
	return false
end

function Instance_:GetFullName(): string
	local parts = { self.Name }
	local node = self.Parent
	while node do
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, ".")
end

local function newInstance(className: string, name: string, parent)
	local node = setmetatable({
		ClassName = className,
		Name = name,
		Parent = parent,
		_children = {},
		_order = {},
		_source = nil,
		_path = nil,
	}, Instance_)

	if parent then
		parent._children[name] = node
		table.insert(parent._order, node)
	end
	return node
end

local SCRIPT_KINDS = {
	["init.luau"] = "ModuleScript",
	["init.server.luau"] = "Script",
	["init.client.luau"] = "LocalScript",
}

local function scriptKindOf(fileName: string): (string, string)
	if fileName:match("%.server%.luau$") then
		return "Script", (fileName:gsub("%.server%.luau$", ""))
	elseif fileName:match("%.client%.luau$") then
		return "LocalScript", (fileName:gsub("%.client%.luau$", ""))
	end
	return "ModuleScript", (fileName:gsub("%.luau$", ""))
end

local function populateFromPath(node, path: string)
	if not fs.isDir(path) then
		return
	end

	local entries = fs.readDir(path)
	table.sort(entries)

	-- Un dossier contenant init*.luau devient lui-meme un script (semantique Rojo).
	for fileName, className in SCRIPT_KINDS do
		if table.find(entries, fileName) then
			node.ClassName = className
			node._source = fs.readFile(`{path}/{fileName}`)
			node._path = `{path}/{fileName}`
			break
		end
	end

	for _, entry in entries do
		local childPath = `{path}/{entry}`
		if fs.isDir(childPath) then
			local child = newInstance("Folder", entry, node)
			populateFromPath(child, childPath)
		elseif entry:match("%.luau$") and not SCRIPT_KINDS[entry] then
			local className, name = scriptKindOf(entry)
			local child = newInstance(className, name, node)
			child._source = fs.readFile(childPath)
			child._path = childPath
		end
	end
end

local function buildNode(name: string, spec, parent)
	local className = spec["$className"] or (parent == nil and "DataModel" or "Folder")
	local node = newInstance(className, name, parent)

	if spec["$path"] then
		populateFromPath(node, spec["$path"])
	end

	for key, value in spec do
		if typeof(key) == "string" and key:sub(1, 1) ~= "$" and typeof(value) == "table" then
			buildNode(key, value, node)
		end
	end

	return node
end

--[[ Construit le DataModel virtuel decrit par un fichier projet Rojo. ]]
function VirtualTree.fromProjectFile(projectPath: string)
	local project = serde.decode("json", fs.readFile(projectPath))
	local dataModel = buildNode(project.name or "game", project.tree, nil)
	dataModel.Parent = nil

	function dataModel:GetService(serviceName: string)
		local service = self._children[serviceName]
		if not service then
			error(`Service "{serviceName}" absent de l'arbre virtuel`, 2)
		end
		return service
	end

	return dataModel
end

return VirtualTree
