# Modèle économique

Le modèle repose sur quatre piliers qui se renforcent : **on ne vend rien tant que le
joueur ne joue pas**, et c'est le temps de jeu qui alimente à la fois le classement
Roblox et les occasions d'achat.

```
   RÉTENTION            →  temps de jeu  →  visibilité Roblox  →  nouveaux joueurs
   (quotidien, coffres,                          │
    AFK, codes)                                  ▼
                                          OCCASIONS D'ACHAT
                                    (paliers difficiles, offres)
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
| Zone AFK | par minute, plafonnée | Maintenir le serveur peuplé |
| Codes promo | ponctuel | Acquisition via les réseaux |
| Bananes au sol | continu | Récompenser l'exploration |

**Sur la zone AFK.** Trois garde-fous la maintiennent à sa place : elle ne rapporte
**que** des bananes (jamais de vitesse), elle ignore **tous** les multiplicateurs — donc
son intérêt fond à mesure que le joueur progresse — et elle est **plafonnée par session**.
Le compteur vit dans la session et jamais dans la sauvegarde : se reconnecter ne
contourne pas le plafond, laisser tourner une nuit ne crée pas de revenu illimité.
Elle sert le nombre de joueurs simultanés, pas la progression.

## 2. Permanent — gamepasses

Achat unique, valeur perçue élevée, aucun contenu bloqué derrière.

| Gamepass | Effet |
| --- | --- |
| x2 Vitesse | Double la vitesse gagnée par pas |
| x2 Bananes | Double les bananes ramassées |
| Super Saut | +15 de puissance de saut |
| Singe VIP | x1.5 vitesse et bananes, +1 s d'accroche murale |
| Course automatique | Le singe avance seul |
| Aimant à bananes | Ramasse à distance |

Les deux derniers ne touchent pas à l'équilibrage : ils vendent du **confort**, ce qui
évite l'effet « pay-to-win » tout en se vendant très bien.

## 3. Répétable — produits développeur

C'est la source de revenu principale : le joueur revient acheter à chaque palier.

| Produit | Prix indicatif | Contenu |
| --- | --- | --- |
| Poignée / Régime / Cageot / Camion de bananes | 99 / 199 / 499 / 999 R$ | 2 500 → 100 000 bananes |
| Ruée du singe | 149 R$ | x2 vitesse, 20 min |
| Fièvre de la banane | 149 R$ | x3 bananes, 20 min |
| Fête du serveur | 299 R$ | Bonus pour **tous** les joueurs, 10 min |
| Renaissance immédiate | 399 R$ | Renaît sans le seuil, garde les améliorations |
| Pack du petit singe | 199 R$ | Offre de bienvenue : bananes + boost |

La grille 99 / 199 / 499 / 999 est celle à laquelle les joueurs Roblox sont habitués,
avec une offre « meilleure offre » mise en avant pour tirer le panier moyen.

## 4. Social et acquisition

- **Fête du serveur** : l'acheteur est nommé dans une notification vue par tous. L'achat
  devient un geste social, très visible, souvent imité.
- **Offres à durée limitée** : une seule à la fois, jamais bloquante. Le pack de
  bienvenue apparaît après quelques minutes de jeu ; un boost est proposé au moment
  précis où le joueur bute sur une barrière de zone.
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
(`tests/specs/application/monetization.spec.luau`).

## Mise en service

1. Créer les gamepasses et produits sur le site Roblox.
2. Coller les identifiants dans `src/Shared/Config/Passes.luau` et
   `src/Shared/Config/Products.luau`.
3. Un identifiant laissé à `0` masque l'article partout — le jeu reste jouable et la
   boutique reste propre tant que rien n'est créé.

Aucune ligne de code n'est à modifier pour activer la monétisation.

## Réglages

Tout se règle dans `src/Shared/Config/Monetization.luau` : durées et cumul des boosts,
table des récompenses quotidiennes, intervalle des coffres, codes promo, offres, et
paramètres de la zone AFK (rythme, plafond, position du pad).
