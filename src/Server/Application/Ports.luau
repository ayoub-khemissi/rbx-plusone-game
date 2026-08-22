--!strict
--[[
	Ports — frontieres de la couche Application.

	Un port est une INTERFACE : la couche Application ne connait que ces contrats,
	jamais leur implementation. Les adaptateurs (src/Server/Adapters) les realisent
	avec les API Roblox, les tests avec des doubles en memoire.

	Aucune de ces definitions n'est instanciable : ce module ne sert qu'a documenter
	et typer le cablage effectue par Composition/Container.
]]

export type PlayerRef = { UserId: number, Name: string }

export type Point = { x: number, y: number, z: number }

--[[ Persistance du profil joueur. Peut lever : l'appelant traite l'echec. ]]
export type ProfileRepository = {
	load: (self: ProfileRepository, userId: number) -> any?,
	save: (self: ProfileRepository, userId: number, profile: any) -> boolean,
}

--[[ Replication de l'etat vers le client (attributs, leaderstats...). ]]
export type StatsPublisher = {
	publish: (self: StatsPublisher, player: PlayerRef, snapshot: any) -> (),
}

--[[ Messages courts affiches au joueur. ]]
export type Notifier = {
	notify: (self: Notifier, player: PlayerRef, message: string, kind: string?) -> (),
}

--[[ Application de l'etat de mouvement sur le personnage. ]]
export type MovementActuator = {
	apply: (self: MovementActuator, player: PlayerRef, movement: any) -> (),
}

--[[ Deplacement force du personnage (barrieres de zone, renaissance). ]]
export type Teleporter = {
	sendTo: (self: Teleporter, player: PlayerRef, position: Point) -> (),
}

--[[ Acces aux gamepasses et aux achats. ]]
export type PassGateway = {
	ownedPasses: (self: PassGateway, player: PlayerRef) -> { [string]: boolean },
	promptPurchase: (self: PassGateway, player: PlayerRef, passId: string) -> (),
}

--[[ Horloge injectable : rend le temps testable. ]]
export type Clock = {
	now: () -> number,
}

return {}
