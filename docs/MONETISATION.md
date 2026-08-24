# Modèle économique

Quatre piliers qui se renforcent. Le principe : **on ne vend rien tant que le joueur
ne joue pas**, et c'est le temps de jeu qui alimente à la fois le classement Roblox et
les occasions d'achat.

```
   RÉTENTION            →  temps de jeu  →  visibilité Roblox  →  nouveaux joueurs
   (quotidien, coffres,                          │
    zone AFK, codes)                             ▼
                                          OCCASIONS D'ACHAT
                                  (barrière de Speed, seuil de Prestige)
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
| Coffre de session | toutes les 5 min | Faire rester maintenant |
| Zone AFK | pendant la session | Maintenir le serveur peuplé |
| Codes promo | ponctuel | Acquisition via les réseaux |
| Checkpoints | continu | Rendre l'échec bon marché |

**Sur la zone AFK.** C'est le système d'attente du jeu, et il est volontairement
médiocre : le revenu est lent et **plafonné par session**. Il sert à garder les serveurs
peuplés — ce qui compte pour les recommandations Roblox — sans jamais devenir une
stratégie meilleure que jouer. Le jour où rester planté rapporte plus que courir, le jeu
est mort.

**Sur les checkpoints.** Une chute ne coûte ni Speed ni Coins, seulement du temps. C'est
un choix économique autant que ludique : un joueur qui perd sa progression ferme le jeu,
un joueur qui perd trente secondes recommence.

## 2. Permanent — gamepasses

Achat unique, valeur perçue élevée, aucun contenu bloqué derrière.

| Gamepass | Effet |
| --- | --- |
| x2 Coins | Double tous les Coins gagnés |
| x2 Speed | Double la Speed gagnée à chaque foulée |
| Swift Boots | ×1,5 Speed et un saut définitivement plus haut |
| Extra Jump | Un saut aérien de plus que ce que les améliorations autorisent |
| Coin Magnet | Ramasse les Coins de bien plus loin |
| Auto Run | Le personnage court tout seul |

Aucun ne débloque de contenu. **Extra Jump** est le plus vendeur des six, parce qu'il
s'achète juste après avoir raté trois fois le même saut — le joueur sait exactement ce
qu'il achète et pourquoi.

## 3. Répétable — produits développeur

La source de revenu principale : le joueur revient acheter à chaque barrière.

| Produit | Prix indicatif | Contenu |
| --- | --- | --- |
| Handful / Bag / Chest / Vault of Coins | 99 / 199 / 499 / 999 R$ | 2 500 → 100 000 Coins |
| Speed Rush | 149 R$ | ×2 Speed, 20 min |
| Coin Rush | 149 R$ | ×3 Coins, 20 min |
| Party Time | 299 R$ | Bonus pour **tous** les joueurs du serveur, 10 min |
| Instant Chest | 149 R$ | Ouvre le coffre de session immédiatement |
| Instant Prestige | 399 R$ | Prestige immédiat, **améliorations gardées** |
| Starter Pack | 199 R$ | Offre de bienvenue : Coins + boost |

La grille 99 / 199 / 499 / 999 est celle à laquelle les joueurs Roblox sont habitués,
avec une offre *best value* mise en avant pour tirer le panier moyen.

**Instant Prestige garde les améliorations**, contrairement au Prestige gratuit qui les
remet à zéro. C'est précisément ce qu'on vend : pas le multiplicateur, qui reste
atteignable en jouant, mais le fait de ne pas racheter tout l'arbre.

## 4. Social et acquisition

- **Party Time** : l'acheteur est nommé dans une notification vue par tous. L'achat
  devient un geste social, très visible, souvent imité.
- **Offres à durée limitée** : une seule à la fois, jamais bloquante. Le Starter Pack
  apparaît après quelques minutes de jeu ; une offre de Coins est proposée au moment
  précis où le joueur vient de se faire refuser par une barrière de Speed.
- **Codes promo** : diffusables sur TikTok, YouTube ou Discord, ils ramènent des joueurs
  sans budget publicitaire.

L'offre déclenchée par une barrière est la plus rentable des deux, et c'est logique :
elle arrive au seul moment où le joueur a un problème précis, nommé, et une solution
chiffrée sous les yeux.

## Fiabilité des achats

Un achat perdu, c'est un joueur perdu. Le traitement des reçus applique trois règles :

1. **Profil non chargé → on ne confirme pas.** Roblox rejouera le reçu, y compris à la
   prochaine session du joueur.
2. **Reçu déjà traité → on ne crédite pas deux fois.** Un registre d'achats conservé
   dans la sauvegarde garantit l'idempotence, même après un redémarrage de serveur.
3. **Sauvegarde en échec → on ne confirme pas.** Mieux vaut un rejeu qu'un achat crédité
   en mémoire puis perdu.

Ces trois cas sont couverts par des tests automatisés.

## Mise en service

1. Créer les gamepasses et produits sur le site Roblox.
2. Coller les identifiants dans `src/Shared/Config/Passes.luau` et
   `src/Shared/Config/Products.luau`.
3. Un identifiant laissé à `0` masque l'article partout — le jeu reste jouable et la
   boutique reste propre tant que rien n'est créé.

Aucune ligne de code n'est à modifier pour activer la monétisation.

## Réglages

Tout se règle dans `src/Shared/Config/Monetization.luau` : durées et cumul des boosts,
table des récompenses quotidiennes, intervalle du coffre de session, codes promo et
offres. Les prix des améliorations en Coins sont dans `Upgrades.luau`, et le rythme de
la zone AFK dans `Balance.luau`.
