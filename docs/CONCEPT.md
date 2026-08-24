# 🐉 +1 Envol — Dragons de l'Archipel

*Titre de travail. Document de référence du jeu : ce qu'on construit, et pourquoi.*

---

## Le pitch

Tu es un dragonneau. Tu t'élances depuis ton nid au-dessus d'un archipel d'îles
flottantes. **Chaque mètre parcouru te rend plus rapide, définitivement.** Le ciel est
découpé en dix paliers d'altitude, de plus en plus hostiles.

À chaque palier, un choix : **encaisser ton butin et rentrer**, ou monter encore, pour
un butin bien plus gros — au risque de tout perdre contre un mur.

---

## La boucle

```
   LE NID  ──envol──►  VOL  ──palier franchi──►  choix
     ▲                  │                          │
     │                  │ mur                      ├─ ENCAISSER ─► retour au Nid
     │                  ▼                          │               butin acquis
     │            poche perdue                     └─ CONTINUER ──► palier suivant
     │            vitesse gardée                                    butin x2,5
     │
     └── œufs ──► couvoir (temps réel, hors ligne) ──► dragon ──► bonus permanent
```

---

## Le Nid

La plateforme de départ, et le seul endroit sûr.

- **Rampe d'envol** — relance immédiate, sans temps mort
- **Couvoir** — les œufs y couvent, même joueur déconnecté
- **Collection** — les dragons éclos, exposés comme un livre à compléter
- **Boutique** — améliorations en or, et boutique Robux
- **Classement** — meilleur palier atteint, plus haute vitesse
- **Perchoir** — rester connecté au Nid accélère la couvaison

---

## Le vol

### La vitesse est sa propre difficulté

La vitesse accumulée pilote la vélocité de vol. Plus le joueur progresse, **moins il a
de temps pour éviter les murs**. Le jeu se durcit exactement au rythme du joueur, sans
qu'on ait à calibrer des paliers de difficulté artificiels.

C'est le cœur du design, et ça donne du sens à l'arbitrage central :

| Amélioration | Effet | Tension |
| --- | --- | --- |
| **Vitesse** | Avance plus vite, gagne plus | Rend le pilotage plus dur |
| **Agilité** | Tourne plus serré | Ne rapporte rien directement |

Pousser la vitesse sans agilité, c'est devenir incapable de piloter. Le joueur doit
équilibrer — il y a une décision, pas un curseur à pousser à droite.

### Les anneaux

Posés sur la ligne rapide. Les franchir remplit la poche d'or. Ils servent aussi de
guide visuel : ils tracent la trajectoire idéale.

**Pas de multiplicateur de combo en v1.** Le quitte ou double fournit déjà toute la
tension ; empiler deux systèmes de multiplication rendrait le jeu illisible. On pourra
l'ajouter après playtest — jamais l'inverse.

### Les murs

Le contact est fatal : la poche est perdue, retour au Nid, relance immédiate.

- **Paliers 1 à 4** — parois fixes à slalomer
- **Paliers 5 à 7** — herses et murs mobiles lents
- **Paliers 8 à 10** — anneaux rotatifs, couloirs resserrés, brume

---

## Les dix paliers

Ambiance *fantasy lumineuse* : îles verdoyantes, ruines dorées, brume et aurores.

| # | Palier | Décor | Danger dominant | Œufs | Rareté max |
| --- | --- | --- | --- | --- | --- |
| 1 | Les Prairies Suspendues | prairies, brume basse | parois fixes espacées | 1 | commun |
| 2 | Les Ruines Dorées | arches, colonnes | passages étroits | 3 | commun |
| 3 | La Cascade Renversée | eau qui monte | colonnes d'eau mouvantes | 6 | rare |
| 4 | Le Bosquet de Nuages | canopée nuageuse | murs mobiles lents | 12 | rare |
| 5 | Les Arches d'Ambre | ambre, lumière chaude | herses | 25 | rare garanti |
| 6 | Le Sanctuaire du Vent | temples ouverts | anneaux rotatifs | 45 | épique |
| 7 | La Mer de Brume | visibilité réduite | murs surgissants | 80 | épique |
| 8 | Les Aiguilles de Cristal | pics translucides | couloirs serrés | 140 | épique |
| 9 | L'Aurore | ciel polaire | murs mobiles rapides | 240 | épique garanti |
| 10 | La Couronne | vide étoilé | tout combiné | 400 | légendaire garanti |

L'or de la poche suit la même montée : multiplicateur de **x1 au palier 1** à **x10 au
palier 10**.

Passer d'un palier au suivant multiplie le butin par ~2,5. C'est le rapport où l'on
hésite : assez pour tenter, pas assez pour que renoncer soit absurde.

---

## Le quitte ou double

### La poche

Pendant le vol, tout ce qui est ramassé va dans la **poche** : or des anneaux, œufs des
paliers franchis. **Rien n'appartient au joueur tant qu'il n'a pas encaissé.**

### L'Autel

À chaque palier, un anneau doré **volontairement écarté de la ligne rapide**. Le
toucher encaisse la poche et ramène au Nid.

Une plaque au sol ne fonctionne pas en vol : on la traverse sans y penser. En écartant
l'Autel de la trajectoire, encaisser devient un geste délibéré — il faut accepter de
dévier et de casser son élan. La décision est physique, pas un bouton dans un menu.

### La mort

Contact avec un mur : la poche est vidée, retour au Nid, relance immédiate. Aucun temps
mort, aucun écran de défaite — la frustration se joue en secondes.

### Le filet de sécurité

**La vitesse acquise pendant le vol reste acquise, quoi qu'il arrive.**

C'est ce qui rend le quitte ou double supportable : même un vol raté a rendu le joueur
un peu plus rapide. Sans ce filet, une série de morts donne le sentiment d'avoir perdu
sa soirée — et le joueur s'en va.

---

## Le couvoir et les dragons

Les œufs **couvent en temps réel, y compris hors ligne**. C'est le système d'attente du
jeu, et il est honnête : il donne une raison de revenir demain, au lieu de payer un
joueur à rester planté sur un pad.

Rester connecté au Nid **accélère** la couvaison — les serveurs restent peuplés, ce qui
compte pour les recommandations Roblox, sans que l'absence soit punie.

Chaque éclosion donne :

- un **bonus permanent** (or, vitesse, agilité, vitesse de couvaison, plume
  supplémentaire) ;
- une **monture visible** par les autres joueurs.

La collection est le moteur de retour à long terme : on revient compléter un livre de
dragons, pas un compteur. Un bonus d'ensemble récompense les collections complètes.

---

## La Mue

Au bout du palier 10, le joueur peut **muer** : améliorations et vitesse remises à zéro,
en échange d'un multiplicateur permanent sur tous les gains, d'un ciel plus hostile et
d'une nouvelle couleur d'écailles — visible par les autres.

C'est la boucle longue du jeu, celle qui lui donne des centaines d'heures.

---

## L'économie

| Monnaie | Vient de | Sert à |
| --- | --- | --- |
| **Or** | anneaux et distance | améliorations |
| **Œufs** | paliers encaissés | dragons de collection |

Améliorations achetables en or : vitesse de base, agilité, aimant à anneaux, valeur des
anneaux, vitesse de couvaison.

---

## La monétisation

Trois produits sont propres à ce format, et se vendent d'eux-mêmes parce qu'ils
s'achètent **dans l'instant du regret** :

- **Plume de résurrection** — un mur pardonné, une fois par vol
- **Assurance de vol** — la moitié de la poche récupérée en cas de mort
- **Éclosion instantanée** — l'attente du couvoir, achetée

À quoi s'ajoutent : emplacements de couvoir supplémentaires, x2 or, x2 œufs, boosts
temporaires, fête du serveur, récompense quotidienne, coffres de session, codes promo,
offre de bienvenue.

**Aucun contenu n'est réservé aux payants.** Les achats font gagner du temps et du
confort, jamais de la puissance inaccessible autrement.

> **Conformité** : les œufs viennent du jeu, pas de la boutique. Si un jour des œufs à
> rareté aléatoire sont vendus contre des Robux, Roblox impose d'en afficher les
> probabilités.

---

## Ce qu'on ne fait pas en v1

- Multiplicateur de combo sur les anneaux
- Paliers infinis au-delà du dixième
- Dragons hostiles ou événements vivants
- Courses chronométrées entre joueurs

Chacun peut s'ajouter plus tard. Aucun ne peut se retirer sans douleur une fois que les
joueurs s'y sont habitués.

---

## Ce que le pivot conserve

Le socle technique est indépendant du thème et reste tel quel : anti-triche par mesure
serveur, sauvegarde et migration de profil, reçus idempotents, boosts, quotidien,
coffres, codes, offres, publication par attributs, architecture hexagonale et suite de
tests.

Ce qui change : le déplacement (vol au lieu de course), les paliers et l'Autel à la
place des zones continues, la poche et sa remise à zéro, le couvoir à la place du pad
AFK, et la collection de dragons.
