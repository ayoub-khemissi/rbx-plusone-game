--!strict
--[[
	Result — the explicit outcome of a business operation.

	The domain never raises for an expected business case — not enough currency, a
	level already maxed. It returns a Result, and the caller turns it into something
	the player reads. `error()` stays reserved for contract violations, which is to
	say programming bugs: the two must not travel the same path, because only one of
	them deserves a crash.
]]

export type Result = {
	ok: boolean,
	value: any?,
	code: string?,
	message: string?,
}

local Result = {}

function Result.ok(value: any?): Result
	return { ok = true, value = value }
end

function Result.err(code: string, message: string?, value: any?): Result
	return { ok = false, code = code, message = message or code, value = value }
end

function Result.isOk(result: Result): boolean
	return result ~= nil and result.ok == true
end

--[[ Unwraps a success and raises on a failure: for invariants, never for input. ]]
function Result.unwrap(result: Result): any
	if not result.ok then
		error(`Result.unwrap on a failure: {result.code} — {result.message}`, 2)
	end
	return result.value
end

return Result
