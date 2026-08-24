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
│  │   Balance · Tiers · Upgrades · Dragons · Passes · Products · Monetization · World
│  ├─ Domain/                  RÈGLES DU JEU (Luau pur, testé)
│  │  ├─ Flight/               SpeedCurve · FlightAccounting · Multipliers · Progression
│  │  ├─ Run/                  Pouch · TierLadder · SkyLayout
│  │  ├─ Hatchery/             Clutch · RarityTable · DragonCatalog
│  │  ├─ Economy/              UpgradeCatalog · Purchase
│  │  ├─ Molt/                 MoltPolicy
│  │  ├─ Monetization/         BoostStack · PurchaseLedger · ProductCatalog · Grants ·
│  │  │                        RewardSchedule · IntervalReward · PromoCodes · OfferEngine
│  │  ├─ Profile/              Entité de sauvegarde + migration de schéma
│  │  └─ Support/              Result · Format
│  ├─ Net.luau                 Contrat réseau partagé
│  └─ Signal.luau
│
├─ Server/                     → ServerScriptService.Server
│  ├─ Application/             CAS D'USAGE (dépendent des ports uniquement)
│  │  ├─ Ports.luau            Contrats : repository, publisher, notifier, random…
│  │  ├─ SessionRegistry       État volatil du vol (Pouch, feathers, insurance)
│  │  ├─ Snapshot              Modèle de présentation envoyé au client
│  │  ├─ EggRoller             Tirage des raretés, à la frontière du domaine
│  │  ├─ RewardApplier         Chemin commun à toute récompense
│  │  └─ UseCases/             19 cas d'usage, un fichier chacun
│  ├─ Adapters/                IMPLÉMENTATIONS ROBLOX
│  │  ├─ Persistence/          DataStore · InMemory
│  │  ├─ Replication/          Attributs + leaderstats · Notifications
│  │  └─ Roblox/               FlightActuator · téléportation · Marketplace · sondes
│  ├─ World/                   Génération du ciel (Palette · SkyBuilder)
│  └─ Composition/             Container · Adapters · Bootstrap · bindings
│
└─ Client/                     → StarterPlayerScripts.Client
   ├─ State.luau               Miroir local de l'état répliqué
   ├─ Controllers/             Vol arcade · barrières · magnet · effets
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
| `FlightActuator` | appliquer vitesse et agilité | `FlightActuator` | `Fakes.actuator()` |
| `Teleporter` | déplacer le personnage | `CharacterTeleporter` | `Fakes.teleporter()` |
| `PassGateway` / `Marketplace` | gamepasses et achats | `MarketplaceGateway` | `Fakes.passGateway()` |
| `Clock` | temps | `os.time` / `os.clock` | horloge contrôlée |
| `Random` | tirages (raretés, espèces) | `Random.new()` | séquence déterministe |

## Racine de composition

`Composition/Container.luau` est le **seul** fichier qui assemble le tout :
configuration → objets de domaine → cas d'usage, ports branchés sur les adaptateurs.

Les tests d'intégration montent ce même conteneur avec des doubles :

```lua
local container = Container.new({ ports = fakePorts })
container.useCases.bankPouch:run(player)
```

Le câblage de production est donc lui aussi couvert par la suite de tests.

## Choix structurants

**La vitesse est mesurée par le serveur.** Le client n'envoie jamais de gain. Une boucle
échantillonne la position réelle du personnage, en trois dimensions, et plafonne le
déplacement crédité à ce qui est physiquement atteignable (`FlightAccounting`). Un
téléport ou un multiplicateur client ne rapporte rien de plus qu'un vol honnête.

**La Pouch ne quitte jamais la session.** Tout ce qui appartient à un vol — or en jeu,
Tier atteint, plumes, assurance — vit dans `SessionRegistry`, jamais dans le profil.
Se déconnecter en plein vol ne protège donc pas une Pouch : elle n'a jamais existé
ailleurs qu'en mémoire.

**L'état est répliqué par attributs, pas par RemoteEvents.** Le serveur écrit des
attributs sur le joueur, Roblox les réplique, le client les écoute. Moins de réseau,
aucune désynchronisation possible, état inspectable depuis Studio.

**Le confort est client, la décision est serveur.** Le pilotage, la couleur des
barrières et les effets tournent chez le joueur pour un contrôle sans latence ; le
serveur revalide systématiquement (`SampleFlight` renvoie un dragon entré dans un Tier
trop rapide pour lui, et le magnet est plafonné en distance côté serveur).

**La courbe de vitesse est bornée.** Un corps trop rapide traverse un mur entre deux
frames et la collision n'est jamais vue. `SpeedCurve` applique une exponentielle
inverse : le compteur peut exploser, la vitesse réelle reste sous le plafond.

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
