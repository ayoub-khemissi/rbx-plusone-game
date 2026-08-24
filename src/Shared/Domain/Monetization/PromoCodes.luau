--!strict
--[[
	PromoCodes — redeemable codes.

	An ACQUISITION lever: a code spreads on videos and social feeds, which brings
	players in at no advertising cost. A code is redeemable once per profile and may
	carry an expiry date.

	A code marked `repeatable` is redeemable as often as the player likes and is never
	recorded against the profile. That is what a recurring code needs — and what
	makes the dev codes usable while balancing the game.
]]

local Result = require(script.Parent.Parent.Support.Result)

type Result = Result.Result

export type Code = {
	code: string,
	grant: { [string]: any },
	expiresAt: number?,
	repeatable: boolean?,
	label: string?,
}

local PromoCodes = {}
PromoCodes.__index = PromoCodes

export type PromoCodes = typeof(setmetatable({} :: { _byCode: { [string]: Code } }, PromoCodes))

local function normalize(code: any): string?
	if typeof(code) ~= "string" then
		return nil
	end
	return string.upper((string.gsub(code, "%s", "")))
end

function PromoCodes.new(codes: { Code }): PromoCodes
	local byCode = {}
	for _, entry in codes do
		local key = normalize(entry.code)
		if key then
			byCode[key] = entry
		end
	end
	return setmetatable({ _byCode = byCode }, PromoCodes)
end

function PromoCodes.redeem(self: PromoCodes, profile: any, rawCode: any, now: number): Result
	local key = normalize(rawCode)
	local entry = if key then self._byCode[key] else nil

	if not key or not entry then
		return Result.err("UNKNOWN_CODE", "This code does not exist.")
	end
	if entry.expiresAt and now > entry.expiresAt then
		return Result.err("EXPIRED", "This code has expired.")
	end

	-- A repeatable code leaves no trace: recording it would grow the profile for
	-- nothing, and a code made repeatable later would stay blocked for everyone who
	-- had already used it once.
	if not entry.repeatable then
		if profile.codes[key] then
			return Result.err("ALREADY_REDEEMED", "You have already used this code.")
		end
		profile.codes[key] = true
	end

	return Result.ok({ code = key, grant = entry.grant, label = entry.label })
end

return PromoCodes
