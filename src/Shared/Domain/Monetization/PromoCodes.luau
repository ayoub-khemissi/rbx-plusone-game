--!strict
--[[
	PromoCodes — codes promotionnels.

	Levier d'ACQUISITION : les codes se diffusent sur les videos et les reseaux, ce
	qui ramene des joueurs sans cout publicitaire. Un code est utilisable une seule
	fois par profil et peut avoir une date de peremption.
]]

local Result = require(script.Parent.Parent.Support.Result)

type Result = Result.Result

export type Code = {
	code: string,
	grant: { [string]: any },
	expiresAt: number?,
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
		return Result.err("UNKNOWN_CODE", "Ce code n'existe pas.")
	end
	if entry.expiresAt and now > entry.expiresAt then
		return Result.err("EXPIRED", "Ce code a expire.")
	end
	if profile.codes[key] then
		return Result.err("ALREADY_REDEEMED", "Tu as deja utilise ce code.")
	end

	profile.codes[key] = true
	return Result.ok({ code = key, grant = entry.grant, label = entry.label })
end

return PromoCodes
