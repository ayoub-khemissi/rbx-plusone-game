# Runner — chaque pas te rend plus rapide

Un jeu de parcours Roblox où **courir est la seule progression**. Le personnage
accélère au fil des mètres parcourus, débloque le double puis le triple saut, et un
dash qui gagne en puissance — jusqu'à traverser des parcours qu'il ne pouvait
physiquement pas franchir une heure plus tôt.

> ⚡ Chaque mètre couru augmente ta **Speed**, définitivement
> 🪙 Ramasse des **Coins** et achète ce qui te fait aller plus loin
> 🪽 Double saut, triple saut, dash niveau 1 à 3
> 🚩 Franchis les barrières de vitesse qui gardent l'entrée de chaque Stage
> 🔁 Recommence à zéro avec un **Prestige**, et va beaucoup plus vite

---

## La boucle de jeu

**Courir rapporte.** Chaque mètre parcouru augmente la Speed — définitivement — et
rapporte des Coins. Rien de tout ça ne se perd en tombant : une chute coûte du temps,
jamais de la progression.

**Les Coins achètent la capacité d'aller plus loin.** Sauter plus haut, sauter deux
puis trois fois, dasher plus fort, ramasser de plus loin, gagner plus vite. Ce sont
ces achats qui ouvrent des raccourcis et des passages qui étaient hors de portée.

**Les barrières découpent le parcours.** L'entrée de chaque Stage est gardée par une
barrière qui ne laisse passer qu'au-dessus d'une certaine Speed. Elle ne se contourne
pas : elle se mérite en courant, ou elle s'achète en avance en améliorant Stride.

**Le Prestige remet tout à zéro, en plus fort.** Speed, Coins et améliorations
disparaissent en échange d'un multiplicateur définitif sur tous les gains futurs. Le
deuxième passage sur un parcours est une autre expérience que le premier.

---

## Se déplacer

| Commande | Effet |
| --- | --- |
| Directions / joystick | Courir |
| Espace, ou le bouton de saut | Sauter — puis re-sauter en l'air une fois le double saut débloqué |
| **Q** ou **Maj gauche**, ou le bouton dédié | Dash |

Le saut et le dash répondent **immédiatement**, sans attendre le serveur : le pilotage
ne doit jamais dépendre de la latence.

La **Speed est sa propre difficulté**. Plus tu vas vite, moins tu as de temps pour
lire un trou ou un piège. Le jeu se durcit exactement à ton rythme, et c'est pour ça
que le saut et le dash s'achètent séparément de la vitesse : il y a un arbitrage, pas
un curseur à pousser à droite.

---

## Les Stages

Le parcours est découpé en cinq segments, chacun gardé par une barrière de Speed et
plus généreux que le précédent.

| # | Stage | Speed requise | Coins |
| --- | --- | --- | --- |
| 1 | Warm-up | — | ×1 |
| 2 | Ramp | 250 | ×1,6 |
| 3 | Climb | 1 000 | ×2,4 |
| 4 | Gauntlet | 4 000 | ×3,5 |
| 5 | Summit | 15 000 | ×5 |

Des **checkpoints** jalonnent le tracé. Tomber dans le vide ou toucher un piège renvoie
au dernier checkpoint atteint, **sans rien perdre** : ni Speed, ni Coins, ni progression
dans le Stage.

---

## Les améliorations

Achetées avec des Coins, elles ne se perdent qu'au Prestige.

| Amélioration | Effet |
| --- | --- |
| **Stride** | +15 % de Speed gagnée à chaque foulée |
| **Fortune** | +20 % de Coins sur tout |
| **Spring** | Sauter plus haut |
| **Air Jump** | Double saut, puis triple saut |
| **Dash** | Une ruée vers l'avant — trois niveaux de puissance |
| **Magnet** | Ramasser les Coins de plus loin |

---

## Ce que le joueur gagne gratuitement

- **Récompense quotidienne** — une série de sept jours, de plus en plus généreuse
- **Coffre de session** — un coffre de Coins toutes les cinq minutes de jeu
- **Zone AFK** — un revenu passif lent et plafonné tant qu'on y reste
- **Codes promo** — diffusés sur les réseaux, échangeables en jeu
- **Offres limitées** — jamais bloquantes, une seule à la fois

---

## Ce qui est proposé à l'achat

Rien n'est obligatoire : tout le contenu se termine sans dépenser. Les achats font
gagner du **temps** et du **confort**, jamais de l'accès.

**Avantages permanents**
x2 Coins · x2 Speed · Swift Boots · Extra Jump · Coin Magnet · Auto Run

**Achats ponctuels**
Lots de Coins (quatre tailles) · Speed Rush (×2 Speed, 20 min) · Coin Rush (×3 Coins,
20 min) · **Party Time** (bonus offert à *tous* les joueurs présents) · Coffre immédiat ·
Prestige immédiat · Starter Pack

---

## Plusieurs thèmes, un seul jeu

Les règles ne connaissent que des notions neutres — vitesse, monnaie, prestige, segment,
checkpoint. Ce que le joueur lit et voit, les mots comme les icônes et les couleurs, est
décidé séparément.

Un nouveau thème rhabille donc entièrement le jeu **sans toucher à une seule règle**, et
plusieurs peuvent coexister. L'équilibrage, lui, ne bouge jamais d'un thème à l'autre :
deux joueurs de deux thèmes restent comparables.

---

## Les parcours

Les maps sont **construites à la main**, pas générées. Le serveur ne fait que lire ce
que la map déclare : où sont les checkpoints, les pièges, les tapis roulants, les
trampolines, les Coins, les barrières et les pads de la zone de départ.

Le vide n'a rien à déclarer : toute chute sous le niveau le plus bas de la map est
détectée automatiquement.

---

## Bon à savoir

- La progression est **sauvegardée automatiquement**. En cas d'incident de sauvegarde,
  la partie reste jouable et la sauvegarde existante n'est jamais écrasée.
- La Speed est **mesurée par le serveur** à partir des déplacements réels : courir
  vraiment est le seul moyen de progresser.
- Les achats sont **crédités une seule fois** et ne peuvent pas être perdus, même en cas
  de coupure au moment du paiement.
