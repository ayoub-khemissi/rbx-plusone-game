# Développement

## Mise en route

```powershell
./scripts/setup.ps1     # installe Rojo, Lune, Selene et StyLua dans .tools/
./scripts/check.ps1     # format + lint + build + tests
```

`setup.ps1` télécharge les outils localement (dossier `.tools/`, ignoré par git),
génère la définition standard Roblox utilisée par le linter et le `sourcemap.json`
qui donne l'autocomplétion à l'éditeur.

Si tu préfères gérer les versions avec [Rokit](https://github.com/rojo-rbx/rokit),
le fichier `rokit.toml` est déjà présent : `rokit install` suffit.

## Commandes

| Commande | Effet |
| --- | --- |
| `./scripts/test.ps1` | Lance toute la suite de tests |
| `./scripts/test.ps1 economy` | Ne lance que les specs dont le chemin contient `economy` |
| `./scripts/check.ps1` | Format + lint + build Rojo + tests (à lancer avant chaque commit) |
| `./scripts/check.ps1 -Fix` | Formate au lieu de vérifier |
| `./scripts/serve.ps1` | Sert le projet vers Roblox Studio |

Les tests s'exécutent **sans Roblox Studio**, en moins de 50 ms.

## Ouvrir le jeu dans Studio

1. Installer le plugin **Rojo** dans Studio (onglet Plugins → Manage Plugins).
2. Créer un lieu vide et le sauvegarder.
3. Lancer `./scripts/serve.ps1` à la racine du projet.
4. Dans Studio : *Rojo → Connect*.
5. Lancer une session **serveur + client** (bouton Play, ou Test → Start avec 1 joueur).

`check.ps1` valide `default.project.json` en construisant le lieu hors Studio :
une erreur d'arborescence est donc détectée avant même d'ouvrir Roblox.

Le ciel est **généré au démarrage du serveur** : il n'y a rien à construire à la main.
En Studio sans accès aux API, la sauvegarde bascule automatiquement en mémoire.

## Écrire du code

### Test d'abord

Chaque règle de jeu commence par une spec dans `tests/specs/`, puis l'implémentation.
Les specs du domaine utilisent leurs **propres fixtures** plutôt que la configuration
réelle : rééquilibrer le jeu ne doit pas casser les tests. Une spec dédiée
(`config.spec.luau`) vérifie séparément que la configuration réelle reste cohérente.

```lua
-- tests/specs/domain/ma_regle.spec.luau
local MaRegle = require(Domain.Categorie.MaRegle)

describe("MaRegle", function()
    it("fait ce qu'on attend", function()
        expect(MaRegle.calcule(2)).toBe(4)
    end)
end)
```

Globales disponibles dans une spec : `describe`, `it`, `beforeEach`, `expect`,
`Domain`, `Application`, `Config`, `Shared`, `Server`, `Fakes`, `Tree`.

### Où ranger quoi

| Ce que tu écris | Où ça va |
| --- | --- |
| Une règle de jeu, un calcul, une validation | `src/Shared/Domain/` |
| Un enchaînement d'actions (charger → décider → publier) | `src/Server/Application/UseCases/` |
| Un appel à une API Roblox | `src/Server/Adapters/` |
| Un nombre d'équilibrage | `src/Shared/Config/` |
| De l'affichage | `src/Client/UI/` |

Un nouveau cas d'usage se déclare dans `Composition/Container.luau` et, s'il est
déclenché par le joueur, dans `Composition/RemoteBindings.luau`.

### Conventions

- Modules en `PascalCase`, un module par fichier, `return` d'une seule table.
- Commentaires en français, sur le **pourquoi** — le *quoi* se lit dans le code.
- Aucun nombre magique hors de `Config/`.
- Les erreurs métier passent par `Result.ok` / `Result.err` ; `error()` est réservé aux
  violations de contrat (bug de programmation).
- Toute donnée venant du réseau est vérifiée en type avant usage.

## Commits

Format [Conventional Commits](https://www.conventionalcommits.org/) :

```
<type>(<portée>): <description à l'impératif, en anglais>
```

Types utilisés : `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`.
Portées : `domain`, `application`, `server`, `client`, `monetization`, `world`, `build`.

```
feat(domain): add agility bonus to the speed curve
fix(application): stop crediting movement after a wall
```

`./scripts/check.ps1` doit être vert avant chaque commit.

## Se donner des ressources pour tester

Équilibrer une amélioration en jouant la courbe à la main est une perte de temps.
Quatre codes existent **uniquement dans Studio** :

| Code | Effet |
| --- | --- |
| `DEVCOINS` | +1 000 000 Coins |
| `DEVSPEED` | +20 000 Speed |
| `DEVPRESTIGE` | +1 Prestige |
| `DEVBOOST` | Speed Rush pendant 30 minutes |

Ouvre la fenêtre **Gifts** dans la sidebar, tape le code dans le champ en bas,
**REDEEM**. Ils sont **répétables** : autant de fois que tu veux, dans la même
session.

Ils passent par exactement le même chemin qu'un vrai code promo — `RedeemCode` →
`Grants` → sauvegarde → snapshot — donc ce que tu testes est le vrai pipeline, pas
un raccourci.

**Ils n'existent pas sur un serveur publié.** `Bootstrap` ne les charge que si
`RunService:IsStudio()` est vrai, et ils vivent dans une table séparée de
`Config/Monetization.luau`. Il n'y a rien à penser à retirer avant de publier.

Pour en ajouter un, une ligne dans `devCodes` suffit ; les effets disponibles sont
ceux de `Grants` : `coins`, `speed`, `boost`, `prestiges`.

## Mise en production

1. **Créer les gamepasses et produits** sur le site Roblox.
2. Reporter les identifiants dans `src/Shared/Config/Passes.luau` et
   `src/Shared/Config/Products.luau` (un identifiant à `0` masque proprement l'article).
3. Activer **Studio Access to API Services** dans les paramètres du jeu (sauvegarde).
4. Vérifier l'équilibrage dans `src/Shared/Config/Balance.luau`.
5. Publier depuis Studio.

Voir [`MONETISATION.md`](MONETISATION.md) pour le détail du modèle économique.
