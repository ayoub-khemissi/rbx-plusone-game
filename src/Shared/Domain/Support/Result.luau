--!strict
--[[
	Result — resultat explicite d'une operation metier.

	Le domaine ne leve jamais d'erreur pour un cas metier attendu (solde insuffisant,
	niveau maximal...) : il renvoie un Result que l'appelant traduit en message joueur.
	`error()` reste reserve aux violations de contrat (bug de programmation).
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

--[[ Extrait la valeur d'un succes, leve sur un echec (a reserver aux invariants). ]]
function Result.unwrap(result: Result): any
	if not result.ok then
		error(`Result.unwrap sur un echec : {result.code} — {result.message}`, 2)
	end
	return result.value
end

return Result
