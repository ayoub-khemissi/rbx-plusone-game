--!nocheck
--[[
	TestKit — micro framework de test (describe / it / expect) sans dependance externe.
	The API deliberately mirrors Jest-Lua: `expect(x).toBe(y)`, `expect(x).never.toBe(y)`.
]]

local TestKit = {}

local function deepEqual(a, b): boolean
	if a == b then
		return true
	end
	if typeof(a) ~= "table" or typeof(b) ~= "table" then
		return false
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function stringify(value): string
	if typeof(value) == "string" then
		return `"{value}"`
	elseif typeof(value) ~= "table" then
		return tostring(value)
	end
	local parts = {}
	for key, inner in value do
		table.insert(
			parts,
			`{tostring(key)} = {if typeof(inner) == "table" then "{...}" else tostring(inner)}`
		)
	end
	table.sort(parts)
	return "{ " .. table.concat(parts, ", ") .. " }"
end

local MATCHERS = {}

function MATCHERS.toBe(value, expected)
	return value == expected, `expected {stringify(expected)}, got {stringify(value)}`
end

function MATCHERS.toEqual(value, expected)
	return deepEqual(value, expected),
		`expected (deep equality) {stringify(expected)}, got {stringify(value)}`
end

function MATCHERS.toBeCloseTo(value, expected, tolerance)
	local delta = tolerance or 1e-6
	local ok = typeof(value) == "number" and math.abs(value - expected) <= delta
	return ok, `expected ~{expected} (+/- {delta}), got {stringify(value)}`
end

function MATCHERS.toBeGreaterThan(value, expected)
	return typeof(value) == "number" and value > expected, `expected > {expected}, got {stringify(value)}`
end

function MATCHERS.toBeGreaterThanOrEqual(value, expected)
	return typeof(value) == "number" and value >= expected, `expected >= {expected}, got {stringify(value)}`
end

function MATCHERS.toBeLessThan(value, expected)
	return typeof(value) == "number" and value < expected, `expected < {expected}, got {stringify(value)}`
end

function MATCHERS.toBeLessThanOrEqual(value, expected)
	return typeof(value) == "number" and value <= expected, `expected <= {expected}, got {stringify(value)}`
end

function MATCHERS.toBeNil(value)
	return value == nil, `expected nil, got {stringify(value)}`
end

function MATCHERS.toBeTruthy(value)
	return (value and true or false), `expected a truthy value, got {stringify(value)}`
end

function MATCHERS.toBeFalsy(value)
	return not value, `expected a falsy value, got {stringify(value)}`
end

function MATCHERS.toBeA(value, expected)
	return typeof(value) == expected, `expected a {expected}, got a {typeof(value)}`
end

function MATCHERS.toHaveLength(value, expected)
	local length = if typeof(value) == "table" then #value else #tostring(value)
	return length == expected, `expected a length of {expected}, got {length}`
end

function MATCHERS.toContain(value, expected)
	local found = false
	if typeof(value) == "table" then
		for _, item in value do
			if deepEqual(item, expected) then
				found = true
				break
			end
		end
	elseif typeof(value) == "string" then
		found = string.find(value, tostring(expected), 1, true) ~= nil
	end
	return found, `{stringify(value)} ne contient pas {stringify(expected)}`
end

function MATCHERS.toThrow(value, pattern)
	local ok, err = pcall(value)
	local threw = not ok
	if threw and pattern then
		threw = string.find(tostring(err), pattern, 1, true) ~= nil
	end
	local suffix = if pattern then ` containing "{pattern}"` else ""
	return threw, `expected an error{suffix}, got: {tostring(err)}`
end

local function buildExpectation(value, negated: boolean)
	local expectation = {}

	for name, matcher in MATCHERS do
		expectation[name] = function(...)
			local ok, message = matcher(value, ...)
			local satisfied = if negated then not ok else ok
			if not satisfied then
				local prefix = if negated then "[never] " else ""
				error(prefix .. message, 2)
			end
			return expectation
		end
	end

	if not negated then
		expectation.never = buildExpectation(value, true)
	end

	return expectation
end

local function expect(value)
	return buildExpectation(value, false)
end

--[[ Cree une session de collecte : renvoie les globales a injecter et les resultats. ]]
function TestKit.newSession()
	local session = { results = {}, stack = {} }

	local function pathFor(name: string): string
		local parts = table.clone(session.stack)
		table.insert(parts, name)
		return table.concat(parts, " > ")
	end

	local globals = {}
	local hooks = { beforeEach = {} }

	function globals.describe(name: string, body: () -> ())
		table.insert(session.stack, name)
		local depth = #hooks.beforeEach
		local ok, err = pcall(body)
		for index = #hooks.beforeEach, depth + 1, -1 do
			table.remove(hooks.beforeEach, index)
		end
		table.remove(session.stack)
		if not ok then
			table.insert(session.results, { name = pathFor(name), ok = false, message = tostring(err) })
		end
	end

	function globals.beforeEach(body: () -> ())
		table.insert(hooks.beforeEach, body)
	end

	function globals.it(name: string, body: () -> ())
		local path = pathFor(name)
		local ok, err = pcall(function()
			for _, hook in hooks.beforeEach do
				hook()
			end
			body()
		end)
		table.insert(session.results, { name = path, ok = ok, message = if ok then nil else tostring(err) })
	end

	globals.test = globals.it
	globals.expect = expect

	return globals, session
end

return TestKit
