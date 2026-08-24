# Modèle économique

Le modèle repose sur quatre piliers qui se renforcent : **on ne vend rien tant que le
joueur ne joue pas**, et c'est le temps de jeu qui alimente à la fois le classement
Roblox et les occasions d'achat.

```
   RÉTENTION            →  temps de jeu  →  visibilité Roblox  →  nouveaux joueurs
   (quotidien, coffres,                          │
    couvoir, codes)                              ▼
                                          OCCASIONS D'ACHAT
                                    (barrières de vent, Pouch perdue)
                                                 │
                        ┌────────────────────────┴────────────────────────┐
                        ▼                                                 ▼
              PERMANENT (gamepasses)                        RÉPÉTABLE (produits)
              achat unique, valeur perçue                   revenu principal
```

## 1. Rétention — gratuit

| Mécanique | Rythme | Effet recherché |
| --- | --- | --- |
| Récompense quotidienne | 1 / jour, série de 7 | Faire revenir demain |
| Sky Chest | toutes les 5 min | Faire rester maintenant |
| Couvaison des œufs | temps réel, hors ligne | Donner une raison de revenir |
| Perch au Nest | pendant la session | Maintenir le serveur peuplé |
| Codes promo | ponctuel | Acquisition via les réseaux |
| Rings | continu | Tracer la trajectoire idéale |

**Sur la couvaison.** C'est le système d'attente du jeu, et il est honnête : les œufs
avancent en temps réel, y compris joueur déconnecté, donc l'absence n'est jamais punie.
Rester au **Perch** accélère seulement la couvaison — les serveurs restent peuplés, ce
qui compte pour les recommandations Roblox, sans payer personne à rester planté.

## 2. Permanent — gamepasses

Achat unique, valeur perçue élevée, aucun contenu bloqué derrière.

| Gamepass | Effet |
| --- | --- |
| x2 Gold | Double l'or rapporté au Nest |
| x2 Eggs | Double les œufs encaissés à un Altar |
| Swift Wing | x1.5 Speed et un virage plus stable |
| Phoenix Feather | Un mur pardonné par vol : la Pouch survit |
| Ring Magnet | Attrape les Rings de bien plus loin |
| Nest Keeper | Deux emplacements de couvoir supplémentaires |

Aucun ne débloque de contenu. Le Phoenix Feather est le plus vendeur des six, parce
qu'il s'achète juste après avoir perdu une Pouch — et qu'on sait exactement ce qu'on
vient de perdre.

## 3. Répétable — produits développeur

C'est la source de revenu principale : le joueur revient acheter à chaque barrière.

| Produit | Prix indicatif | Contenu |
| --- | --- | --- |
| Pouch / Chest / Hoard / Dragon's Hoard | 99 / 199 / 499 / 999 R$ | 2 500 → 100 000 or |
| Swift Rush | 149 R$ | x2 Speed, 20 min |
| Gold Fever | 149 R$ | x3 or, 20 min |
| Sky Festival | 299 R$ | Bonus pour **tous** les joueurs, 10 min |
| Instant Hatch | 149 R$ | Tous les œufs du Nest éclosent |
| Flight Insurance | 199 R$ | Moitié de la Pouch récupérée, 3 vols |
| Instant Molt | 399 R$ | Molt immédiate, améliorations gardées |
| Hatchling Pack | 199 R$ | Offre de bienvenue : or + œuf rare + boost |

La grille 99 / 199 / 499 / 999 est celle à laquelle les joueurs Roblox sont habitués,
avec une offre « meilleure offre » mise en avant pour tirer le panier moyen.

## 4. Social et acquisition

- **Sky Festival** : l'acheteur est nommé dans une notification vue par tous. L'achat
  devient un geste social, très visible, souvent imité.
- **Offres à durée limitée** : une seule à la fois, jamais bloquante. Le pack de
  bienvenue apparaît après quelques minutes de jeu ; l'assurance est proposée au moment
  précis où le joueur vient de perdre une Pouch.
- **Codes promo** : diffusables sur TikTok, YouTube ou Discord, ils ramènent des joueurs
  sans budget publicitaire.

## Fiabilité des achats

Un achat perdu, c'est un joueur perdu. Le traitement des reçus applique trois règles :

1. **Profil non chargé → on ne confirme pas.** Roblox rejouera le reçu, y compris à la
   prochaine session du joueur.
2. **Reçu déjà traité → on ne crédite pas deux fois.** Un registre d'achats conservé
   dans la sauvegarde garantit l'idempotence, même après un redémarrage de serveur.
3. **Sauvegarde en échec → on ne confirme pas.** Mieux vaut un rejeu qu'un achat crédité
   en mémoire puis perdu.

Ces trois cas sont couverts par des tests automatisés
(`tests/specs/application/flight.spec.luau` et le domaine `Monetization`).

## Mise en service

1. Créer les gamepasses et produits sur le site Roblox.
2. Coller les identifiants dans `src/Shared/Config/Passes.luau` et
   `src/Shared/Config/Products.luau`.
3. Un identifiant laissé à `0` masque l'article partout — le jeu reste jouable et la
   boutique reste propre tant que rien n'est créé.

Aucune ligne de code n'est à modifier pour activer la monétisation.

## Réglages

Tout se règle dans `src/Shared/Config/Monetization.luau` : raretés et leurs poids,
durées de couvaison et emplacements, durées et cumul des boosts, table des récompenses
quotidiennes, intervalle du Sky Chest, codes promo et offres.
