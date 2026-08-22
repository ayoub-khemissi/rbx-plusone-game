--!strict
--[[
	IdleAccrual — revenu passif de la zone AFK.

	Pourquoi une zone AFK : un joueur qui laisse le jeu ouvert maintient le serveur
	peuple et fait remonter le nombre de joueurs simultanes, critere majeur des
	recommandations Roblox. Trois garde-fous evitent que cela remplace le jeu :

	  1. la zone ne rapporte QUE des bananes, jamais de vitesse — le classement
	     reste gagne par ceux qui courent ;
	  2. le rythme est volontairement faible face au jeu actif ;
	  3. un plafond par session empeche la ferme a l'infini.

	Le compteur vit dans la session (jamais dans la sauvegarde) : se reconnecter ne
	contourne pas le plafond d'une session, et laisser tourner une nuit ne cree pas
	de revenu illimite.
]]

export type Station = { x: number, z: number, radius: number }

export type Tuning = {
	bananasPerMinute: number,
	payoutInterval: number,
	sessionCapSeconds: number,
	station: Station,
}

export type State = {
	pendingSeconds: number,
	creditedSeconds: number,
}

export type Outcome = {
	payouts: number,
	bananas: number,
	capped: boolean,
}

local IdleAccrual = {}
IdleAccrual.__index = IdleAccrual

export type IdleAccrual = typeof(setmetatable({} :: Tuning, IdleAccrual))

function IdleAccrual.new(tuning: Tuning): IdleAccrual
	return setmetatable({
		bananasPerMinute = tuning.bananasPerMinute,
		payoutInterval = tuning.payoutInterval,
		sessionCapSeconds = tuning.sessionCapSeconds,
		station = tuning.station,
	}, IdleAccrual)
end

function IdleAccrual.newState(): State
	return { pendingSeconds = 0, creditedSeconds = 0 }
end

--[[ Le joueur est-il sur le pad AFK ? La hauteur est ignoree. ]]
function IdleAccrual.covers(self: IdleAccrual, position: { x: number, y: number, z: number }): boolean
	local dx = position.x - self.station.x
	local dz = position.z - self.station.z
	return dx * dx + dz * dz <= self.station.radius * self.station.radius
end

function IdleAccrual.remainingFor(self: IdleAccrual, state: State): number
	return math.max(self.sessionCapSeconds - state.creditedSeconds, 0)
end

--[[ Le joueur quitte la zone : le temps partiel est perdu, le plafond est garde. ]]
function IdleAccrual.reset(_self: IdleAccrual, state: State)
	state.pendingSeconds = 0
end

function IdleAccrual.accumulate(self: IdleAccrual, state: State, deltaTime: number): Outcome
	local empty: Outcome = { payouts = 0, bananas = 0, capped = false }

	if typeof(deltaTime) ~= "number" or deltaTime ~= deltaTime or deltaTime <= 0 then
		return empty
	end

	local remaining = self:remainingFor(state)
	if remaining <= 0 then
		return { payouts = 0, bananas = 0, capped = true }
	end

	state.pendingSeconds += math.min(deltaTime, remaining)

	local payouts = math.floor(state.pendingSeconds / self.payoutInterval)
	if payouts <= 0 then
		return empty
	end

	local creditedSeconds = payouts * self.payoutInterval
	state.pendingSeconds -= creditedSeconds
	state.creditedSeconds += creditedSeconds

	return {
		payouts = payouts,
		bananas = self.bananasPerMinute * (creditedSeconds / 60),
		capped = self:remainingFor(state) <= 0,
	}
end

return IdleAccrual
