# Architecture

Le projet suit une **architecture hexagonale** (ports & adaptateurs). L'objectif est
simple : les règles du jeu ne dépendent d'aucune API Roblox, ce qui les rend testables
en ligne de commande et remplaçables sans réécriture.

```
                    ┌─────────────────────────────┐
                    │          DOMAINE            │  Luau pur
                    │  règles du jeu, sans API    │  0 dépendance
                    └──────────────▲──────────────┘
                                   │ utilise
                    ┌──────────────┴──────────────┐
                    │        APPLICATION          │  cas d'usage
                    │  orchestre via des PORTS    │  0 API Roblox
                    └──────────────▲──────────────┘
                                   │ implémente les ports
      ┌────────────────────────────┴────────────────────────────┐
      │                       ADAPTATEURS                        │
      │  DataStore · attributs · Humanoid · MarketplaceService   │
      └──────────────────────────────────────────────────────────┘
                                   ▲
                    ┌──────────────┴──────────────┐
                    │        COMPOSITION          │  câblage unique
                    └─────────────────────────────┘
```

## Règle de dépendance

Les flèches ne pointent que vers l'intérieur.

| Couche | Peut dépendre de | Ne connaît jamais |
| --- | --- | --- |
| `Domain` | rien | Roblox, réseau, sauvegarde |
| `Application` | `Domain`, ports | Roblox, instances |
| `Adapters` | `Domain`, ports, Roblox | les cas d'usage |
| `Composition` | tout | — |
| `Client` | `Domain` (lecture), `Config`, `Net` | la logique serveur |

Concrètement : `grep -r "game:GetService" src/Shared/Domain` ne doit **rien** renvoyer,
et `src/Server/Application` ne doit contenir aucune référence à une instance Roblox.

## Arborescence

```
src/
├─ Shared/                     → ReplicatedStorage.Shared
│  ├─ Config/                  Équilibrage : la seule source de constantes
│  │   Balance · Upgrades · Zones · Passes · Products · Monetization · World
│  ├─ Domain/                  RÈGLES DU JEU (Luau pur, testé)
│  │  ├─ Progression/          SpeedCurve · MovementAccounting · Multipliers ·
│  │  │                        Progression · IdleAccrual
│  │  ├─ Economy/              UpgradeCatalog · Purchase
│  │  ├─ Zones/                ZoneLadder · TrackLayout
│  │  ├─ Rebirth/              RebirthPolicy
│  │  ├─ Monetization/         BoostStack · PurchaseLedger · ProductCatalog ·
│  │  │                        Grants · RewardSchedule · IntervalReward ·
│  │  │                        PromoCodes · OfferEngine
│  │  ├─ Profile/              Entité de sauvegarde + migration de schéma
│  │  └─ Support/              Result · Format
│  ├─ Net.luau                 Contrat réseau partagé
│  └─ Signal.luau
│
├─ Server/                     → ServerScriptService.Server
│  ├─ Application/             CAS D'USAGE (dépendent des ports uniquement)
│  │  ├─ Ports.luau            Contrats : repository, publisher, notifier…
│  │  ├─ SessionRegistry       État en mémoire des joueurs connectés
│  │  ├─ Snapshot              Modèle de présentation envoyé au client
│  │  ├─ RewardApplier         Chemin commun à toute récompense
│  │  └─ UseCases/             16 cas d'usage, un fichier chacun
│  ├─ Adapters/                IMPLÉMENTATIONS ROBLOX
│  │  ├─ Persistence/          DataStore · InMemory
│  │  ├─ Replication/          Attributs + leaderstats · Notifications
│  │  └─ Roblox/               Humanoid · téléportation · Marketplace · sondes
│  ├─ World/                   Génération de la carte (Palette · WorldBuilder)
│  └─ Composition/             Container · Adapters · Bootstrap · bindings
│
└─ Client/                     → StarterPlayerScripts.Client
   ├─ State.luau               Miroir local de l'état répliqué
   ├─ Controllers/             Wall-run · barrières · gamepasses · effets
   └─ UI/                      Theme · Widgets · HUD · fenêtres
```

## Les ports

Déclarés dans `src/Server/Application/Ports.luau`, implémentés deux fois : par un
adaptateur Roblox en production, par un double en test.

| Port | Rôle | Production | Test |
| --- | --- | --- | --- |
| `ProfileRepository` | charger / sauvegarder | `DataStoreProfileRepository` | `Fakes.repository()` |
| `StatsPublisher` | répliquer l'état | `AttributeStatsPublisher` | `Fakes.publisher()` |
| `Notifier` | messages joueur | `RemoteNotifier` | `Fakes.notifier()` |
| `MovementActuator` | appliquer la vitesse | `HumanoidActuator` | `Fakes.actuator()` |
| `Teleporter` | déplacer le personnage | `CharacterTeleporter` | `Fakes.teleporter()` |
| `PassGateway` / `Marketplace` | gamepasses et achats | `MarketplaceGateway` | `Fakes.passGateway()` |
| `Clock` | temps | `os.time` / `os.clock` | horloge contrôlée |

## Racine de composition

`Composition/Container.luau` est le **seul** fichier qui assemble le tout :
configuration → objets de domaine → cas d'usage, ports branchés sur les adaptateurs.

Les tests d'intégration montent ce même conteneur avec des doubles :

```lua
local container = Container.new({ ports = fakePorts })
container.useCases.buyUpgrade:run(player, "speedGain")
```

Le câblage de production est donc lui aussi couvert par la suite de tests.

## Choix structurants

**La vitesse est mesurée par le serveur.** Le client n'envoie jamais de gain. Une boucle
échantillonne la position réelle du personnage et plafonne le déplacement crédité à ce
qui est physiquement atteignable (`MovementAccounting`). Un téléport ou un multiplicateur
client ne rapporte rien de plus qu'une course honnête.

**L'état est répliqué par attributs, pas par RemoteEvents.** Le serveur écrit des
attributs sur le joueur, Roblox les réplique, le client les écoute. Moins de réseau,
aucune désynchronisation possible, état inspectable depuis Studio.

**Le confort est client, la décision est serveur.** Le wall-run, les barrières
traversables et les effets tournent chez le joueur pour un contrôle sans latence ;
le serveur revalide systématiquement (`EnforceZoneAccess` renvoie un joueur entré dans
une zone trop rapide pour lui).

**La courbe de vitesse est bornée.** La physique Roblox décroche au-delà de ~250 studs/s.
`SpeedCurve` applique une exponentielle inverse : le compteur peut exploser, la vitesse
réelle reste jouable.

**La sauvegarde ne s'écrase jamais par accident.** Si la lecture du DataStore échoue,
la session est marquée non sauvegardable : le joueur peut jouer, mais sa progression
existante est protégée.

## Tests

Voir [`DEVELOPPEMENT.md`](DEVELOPPEMENT.md) pour les commandes. En résumé :

- les modules de `Domain` et `Application` s'exécutent **hors de Studio** grâce à un
  harnais (`tests/harness/`) qui reconstruit l'arbre Roblox depuis `default.project.json`
  et fournit `script`, `require` et `game:GetService` ;
- le code de production ignore totalement l'existence de ce harnais ;
- les adaptateurs, volontairement très fins, ne sont pas couverts : ils ne contiennent
  aucune règle de jeu.
