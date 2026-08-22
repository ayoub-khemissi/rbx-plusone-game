--!nocheck
--[[
	Lanceur de tests headless.

	Usage :  .tools/lune.exe run tests/run           (tous les specs)
	         .tools/lune.exe run tests/run economy   (filtre sur le nom de fichier)
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local VirtualTree = require("./harness/VirtualTree")
local Runtime = require("./harness/Runtime")
local TestKit = require("./harness/TestKit")

local SPEC_ROOT = "tests/specs"
local filter = process.args[1]

local function collectSpecs(dir: string, out: { string })
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`
		if fs.isDir(path) then
			collectSpecs(path, out)
		elseif entry:match("%.spec%.luau$") then
			table.insert(out, path)
		end
	end
	return out
end

local dataModel = VirtualTree.fromProjectFile("default.project.json")
local runtime = Runtime.new(dataModel)

local replicatedStorage = dataModel:GetService("ReplicatedStorage")
local shared = replicatedStorage:WaitForChild("Shared")

local fakes = require("./harness/Fakes")

local specs = collectSpecs(SPEC_ROOT, {})
table.sort(specs)

local passed, failed = 0, 0
local failures: { { name: string, message: string, file: string } } = {}
local startedAt = os.clock()

for _, specPath in specs do
	if filter and not string.find(specPath, filter, 1, true) then
		continue
	end

	local globals, session = TestKit.newSession()
	globals.Shared = shared
	globals.Tree = dataModel
	globals.Domain = shared:FindFirstChild("Domain")
	globals.Application = shared:FindFirstChild("Application")
	globals.Config = shared:FindFirstChild("Config")
	globals.Server = dataModel:GetService("ServerScriptService"):FindFirstChild("Server")
	globals.Fakes = fakes

	local ok, loadErr = pcall(function()
		local chunk = runtime:loadScript(specPath, fs.readFile(specPath), globals)
		chunk()
	end)

	if not ok then
		failed += 1
		table.insert(failures, { name = "<chargement du fichier>", message = tostring(loadErr), file = specPath })
		continue
	end

	for _, result in session.results do
		if result.ok then
			passed += 1
		else
			failed += 1
			table.insert(failures, { name = result.name, message = result.message, file = specPath })
		end
	end
end

local elapsed = (os.clock() - startedAt) * 1000

print("")
for _, failure in failures do
	stdio.write(`{stdio.color("red")}  X {failure.file}{stdio.color("reset")}\n`)
	stdio.write(`     {failure.name}\n`)
	stdio.write(`     {stdio.style("dim")}{failure.message}{stdio.style("reset")}\n\n`)
end

local total = passed + failed
if failed == 0 then
	stdio.write(
		`{stdio.color("green")}  {total} test(s) OK{stdio.color("reset")} en {string.format("%.0f", elapsed)} ms\n\n`
	)
	process.exit(0)
else
	stdio.write(
		`{stdio.color("red")}  {failed} echec(s){stdio.color("reset")} / {total} test(s) `
			.. `en {string.format("%.0f", elapsed)} ms\n\n`
	)
	process.exit(1)
end
