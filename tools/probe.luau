local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local game = roblox.deserializePlace(fs.readFile("maps/Place1.rbxl"))
local workspace = game:GetService("Workspace")

local function describe(instance, label)
	local attrs = {}
	local ok, attributes = pcall(function()
		return instance:GetAttributes()
	end)
	if ok and attributes then
		for key, value in attributes do
			table.insert(attrs, `{key}={tostring(value)}`)
		end
	end

	local pos, size, collide, touch = "?", "?", "?", "?"
	pcall(function()
		pos = string.format("%.0f,%.0f,%.0f", instance.Position.X, instance.Position.Y, instance.Position.Z)
		size = string.format("%.0fx%.0fx%.0f", instance.Size.X, instance.Size.Y, instance.Size.Z)
		collide = tostring(instance.CanCollide)
		touch = tostring(instance.CanTouch)
	end)

	print(
		string.format(
			"  %-16s pos %-18s size %-16s collide=%-5s touch=%-5s attrs[%s]",
			label,
			pos,
			size,
			collide,
			touch,
			table.concat(attrs, " ")
		)
	)
end

for _, folderName in { "Checkpoints", "TrapParts", "Conveyors", "BouncePad" } do
	local folder = workspace:FindFirstChild(folderName)
	if folder then
		print(`=== {folderName} ===`)
		for _, child in folder:GetChildren() do
			describe(child, child.Name)
		end
	end
end

print("=== StartSpawn ===")
describe(workspace:FindFirstChild("StartSpawn"), "StartSpawn")

print("=== ObbyStructure (5 premiers) ===")
local obby = workspace:FindFirstChild("ObbyStructure")
if obby then
	for index, child in obby:GetChildren() do
		if index > 5 then
			break
		end
		describe(child, child.Name .. " (" .. child.ClassName .. ")")
	end
end
